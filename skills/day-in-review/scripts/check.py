#!/usr/bin/env python3
"""Ship checks for an end-of-day review page. Run before delivering.

    python3 scripts/check.py path/to/review.html --length standard

--length is one of {quick, standard, full}. Prints one line per check with
PASS / FAIL / WARN and exits non-zero on any FAIL.

Adapted from daily-brief's check.py. Differences: length-based word budget
instead of minutes; STAT-CITED (was SOURCED) exempts blocks flagged
data-selfreport (the user's own words, not a tool stat); no WILDCARD check.

Two things it does that a naive script would get wrong. It strips <style>,
<script>, and comments before counting, because a plain tag-strip counts the
stylesheet and over-reports every brief by ~550 words. And it excludes quoted
material — blockquotes, cites, linked headlines, anything in curly quotes or
marked <span data-verbatim> — before hunting banned words, because real names
collide with the list: Paramount, Tapestry, Harness, Foster + Partners, Robust
Intelligence, Beacon Roofing, Realm. Those words are matched lowercase-only for
the same reason. Never reword a real name to satisfy this script.
"""
import argparse, html, re, sys

# The executable form of references/compose.md § Prose. Change one, change both.
# Matched case-insensitively: these are never proper nouns.
SLOP_ANY = [
    r"delv(e|es|ing|ed)", r"utiliz(e|es|ing|ed)", r"facilitat(e|es|ing|ed)",
    r"cutting.edge", r"paradigm.shift", r"game.chang(er|ing)",
    r"this changes everything", r"multifaceted", r"meticulous(ly)?", r"intricate",
    r"transformative", r"supercharg(e|es|ing|ed)", r"ever.evolving",
    r"pivotal moment", r"vital role", r"underscor(e|es|ing|ed)",
    r"showcas(e|es|ing|ed)", r"highlighting", r"it.s worth noting",
    r"it.s important to note", r"at the end of the day", r"in today.s world",
    r"in the age of", r"let.s dive in", r"in conclusion", r"when it comes to",
    r"at its core", r"in terms of", r"going forward", r"the reality is",
    r"the truth is",
]
# Matched lowercase-only: capitalised, each of these is somebody's name.
SLOP_LOWER = [
    r"foster(s|ing|ed)?", r"leverag(e|es|ing|ed)", r"empower(s|ing|ed)?",
    r"streamlin(e|es|ing|ed)", r"robust", r"tapestry", r"realm", r"beacon",
    r"paramount", r"elevat(e|es|ing|ed)", r"embark(s|ing|ed)?",
    r"harness(es|ing|ed)?", r"testament",
]
SLOP_ANY_RE = re.compile(r"\b(?:" + "|".join(SLOP_ANY) + r")\b", re.I)
SLOP_LOWER_RE = re.compile(r"\b(?:" + "|".join(SLOP_LOWER) + r")\b", re.I)
SENTENCE_START = re.compile(r"(?:^|[.!?:]\s+|\n\s*)$")


def lower_hits(text):
    """Banned words that double as proper nouns: flag them lowercase, and
    capitalised only when they open a sentence."""
    out = set()
    for m in SLOP_LOWER_RE.finditer(text):
        w = m.group(0)
        if w[0].islower() or SENTENCE_START.search(text[max(0, m.start() - 40):m.start()]):
            out.add(w)
    return out

# compose.md § Prose → "Meta-frames": announcing that a fact is interesting
# instead of writing the fact.
FRAME_RE = re.compile(r"\b(?:"
    r"the (part|thing|bit|detail) (worth (noticing|noting|watching|carrying)|to watch|to sit with)"
    r"|worth noticing"
    r"|the useful part"
    r"|the interesting (part|bit|thing)"
    r"|the number worth carrying"
    r"|the one to sit with"
    r"|what.s (interesting|notable|striking) here"
    r"|here.s the thing"
    r"|it.s telling that"
    r")\b", re.I)

# Regions whose words are somebody else's, not the writer's.
# The class match is anchored to <a> and to a whole class token, because
# "\bhead\b" also matches "section-head" and silently swallowed 40% of a page.
QUOTED = [
    r"<blockquote\b.*?</blockquote>", r"<cite\b.*?</cite>",
    r'<a\b[^>]*class="(?:[^"]*\s)?head(?:\s[^"]*)?"[^>]*>.*?</a>',
    r"<span\b[^>]*\bdata-verbatim\b.*?</span>",
]
# Straight, curly, angle and low-9 quote pairs.
QUOTE_SPAN = re.compile(r'[\u201c\u201e\u00ab"][^\u201d\u00bb"]{0,600}[\u201c\u201d\u00bb"]')


def visible(s):
    s = re.sub(r"<style[^>]*>.*?</style>", " ", s, flags=re.S | re.I)
    s = re.sub(r"<script[^>]*>.*?</script>", " ", s, flags=re.S | re.I)
    s = re.sub(r"<!--.*?-->", " ", s, flags=re.S)
    return html.unescape(re.sub(r"<[^>]+>", " ", s))


def item_chunks(body, raw=False):
    """Each <article|div class="item"> block, balanced. With raw=False, captions
    and source lines are removed so SHAPE measures prose and not markup."""
    out = []
    for m in re.finditer(r'<(article|div)\b[^>]*class="(?:[^"]*\s)?item(?:\s[^"]*)?"[^>]*>', body, re.I):
        tag, depth, i = m.group(1), 1, m.end()
        for t in re.finditer(rf"</?{tag}\b[^>]*>", body[m.end():], re.I):
            depth += -1 if t.group(0).startswith("</") else 1
            if depth == 0:
                i = m.end() + t.start()
                break
        chunk = body[m.end():i]
        if raw:
            out.append(chunk); continue
        chunk = re.sub(r"<figcaption.*?</figcaption>", " ", chunk, flags=re.S | re.I)
        chunk = re.sub(r'<[^>]*class="(?:[^"]*\s)?src(?:\s[^"]*)?".*?</p>', " ", chunk, flags=re.S | re.I)
        out.append(chunk)
    return out


def unquoted(body):
    """Visible prose with quoted material removed, for the banned-word passes.
    Block and label boundaries become full stops first, so a banned word opening
    a sentence right after <b>Why it matters</b> is still seen as sentence-initial."""
    for pat in QUOTED:
        body = re.sub(pat, " ", body, flags=re.S | re.I)
    body = re.sub(r"</(b|strong|em|h[1-6]|p|li|summary|div|section|article)>|<br\s*/?>",
                  " . ", body, flags=re.I)
    return QUOTE_SPAN.sub(" ", visible(body))


def main():
    LENGTHS = {"quick": 400, "standard": 800, "full": 1500}
    ap = argparse.ArgumentParser()
    ap.add_argument("file")
    ap.add_argument("--length", choices=LENGTHS, default="standard",
                    help="recap length: quick / standard / full")
    a = ap.parse_args()
    try:
        raw = open(a.file, encoding="utf-8").read()
    except OSError as e:
        sys.exit(f"cannot read {a.file}: {e.strerror}")
    m = re.search(r"<body.*?>(.*)</body>", raw, re.S | re.I)
    body = m.group(1) if m else raw

    txt = visible(body)
    prose = unquoted(body)
    words = len(txt.split())
    det = sum(len(visible(d).split()) for d in re.findall(r"<details.*?</details>", body, re.S | re.I))
    weighted = round(words - det / 2)
    ceiling = LENGTHS[a.length]
    floor = round(ceiling * 0.8) if a.length in ("standard", "full") else 0
    stamp = max(1, int(weighted / 240 + 0.5))

    n = lambda p, s=None: len(re.findall(p, body if s is None else s, re.I))
    imgs, onerr, alts = n(r"<img\b"), n(r"onerror="), n(r"<img[^>]*\balt=")
    ext = n(r'href="https?://')
    dead = (len(re.findall(r'(?:href|src)="#"', body))
            + len(re.findall(r'(?:href|src)="[^"]*(?:example\.com|REPLACE|YOUR_|TODO_|FIXME)', body)))
    details = n(r"<details\b")
    link_floor = 2
    slop = sorted({x.group(0) for x in SLOP_ANY_RE.finditer(prose)} | lower_hits(prose))
    frames = sorted({x.group(0).lower() for x in FRAME_RE.finditer(prose)})
    em, rather = txt.count("—"), len(re.findall(r"\brather than\b", txt, re.I))
    # HEXCHECK: raw #hex in the body (inline SVG/style attrs) breaks the dark-mode
    # flip — visuals must use var(--…) tokens or white/black keywords. Scan the body
    # with <style>/<script>/comments removed (the stylesheet's palette hex is fine).
    body_nostyle = re.sub(r"<style[^>]*>.*?</style>|<script[^>]*>.*?</script>|<!--.*?-->",
                          " ", body, flags=re.S | re.I)
    # Only hex in a colour context (fill=/stroke=/color:/background:/…) — never a
    # PR/issue ref like "#482", which is not a colour.
    HEX_CTX = re.compile(
        r"(?:fill|stroke|stop-color|flood-color|lighting-color|color|background(?:-color)?"
        r"|border[a-z-]*|box-shadow|outline|text-shadow)\s*[:=]\s*[\"']?\s*"
        r"(#(?:[0-9a-fA-F]{6}|[0-9a-fA-F]{3}))\b", re.I)
    hexes = sorted(set(m.group(1) for m in HEX_CTX.finditer(body_nostyle)))

    title = re.search(r"<title[^>]*>(.*?)</title>", raw, re.S | re.I)
    head = re.search(r'class="(?:[^"]*\s)?stamp(?:\s[^"]*)?"[^>]*>(.*?)</', body, re.S | re.I)
    shown = re.search(r"(\d+)\s*min", head.group(1), re.I) if head else None
    if not head:
        stamp_st, stamp_msg = "WARN", f'no .stamp element found; it must read "{stamp} min"'
    elif not shown or int(shown.group(1)) != stamp:
        stamp_st = "FAIL"
        stamp_msg = f'masthead says "{(shown.group(0) if shown else head.group(1).strip())}", must read "{stamp} min"'
    else:
        stamp_st, stamp_msg = "PASS", f'"{stamp} min"'

    items = [len(visible(chunk).split()) for chunk in item_chunks(body)]
    blocks = item_chunks(body, raw=True) + re.findall(r'<section[^>]*class="(?:[^"]*\s)?lead(?:\s[^"]*)?"[^>]*>.*?</section>', body, re.S | re.I)
    unsourced = sum(1 for c in blocks
                    if not re.search(r'href="https?://', c, re.I)
                    and not re.search(r'data-selfreport', c, re.I))

    # The <title> and the masthead must agree on the date. Compare their digit runs.
    strip_clock = lambda t: re.sub(r"\d{1,2}[:.]\d{2}|\b\d+\s*min\b|\b\d{1,2}\s*(?=[AaPp]\.?[Mm])", " ", t)
    tnum = {x.lstrip("0") for x in re.findall(r"\d+", strip_clock(html.unescape(title.group(1))))} if title else set()
    hnum = {x.lstrip("0") for x in re.findall(r"\d+", strip_clock(head.group(1)))} if head else set()
    if not title or not head or not tnum:
        date_st, date_msg = "WARN", "no dated <title> or no .stamp — check the date by eye"
    elif tnum <= hnum:
        date_st, date_msg = "PASS", f"<title> date matches the masthead ({' '.join(sorted(tnum))})"
    else:
        date_st = "FAIL"
        date_msg = f"<title> has {sorted(tnum - hnum)} the masthead does not — the title is stale"
    alike = [f"{items[i]}/{items[i+1]}" for i in range(len(items) - 1)
             if max(items[i], items[i + 1]) and abs(items[i] - items[i + 1]) / max(items[i], items[i + 1]) < 0.2]

    mins = []
    for m in re.finditer(r'<section\b[^>]*>', body, re.I):
        depth, end = 1, m.end()
        for t in re.finditer(r"</?section\b[^>]*>", body[m.end():], re.I):
            depth += -1 if t.group(0).startswith("</") else 1
            if depth == 0:
                end = m.end() + t.start(); break
        chunk = body[m.end():end]
        label = re.search(r'class="(?:[^"]*\s)?mins(?:\s[^"]*)?"[^>]*>(.*?)<', chunk, re.S | re.I)
        shown = re.search(r"(\d+)\s*MIN", label.group(1), re.I) if label else None
        if shown:
            want = max(1, int(len(visible(chunk).split()) / 240 + 0.5))
            if int(shown.group(1)) != want:
                tag = re.search(r'class="(?:[^"]*\s)?tag(?:\s[^"]*)?"[^>]*>(.*?)<', chunk, re.S | re.I)
                mins.append(f"{(tag.group(1).strip()[:18] if tag else '?')}: says {shown.group(1)}, is {want}")

    R = [
        ("WORDS", f"{words} visible · {det} in details → {weighted} weighted · want "
                  + (f"{floor}–{ceiling}" if floor else f"≤{ceiling}"),
         "FAIL" if weighted > ceiling else "WARN" if weighted < floor else "PASS"),
        ("STAMP", stamp_msg, stamp_st),
        ("DATE", date_msg, date_st),
        ("SLOP", ", ".join(slop) or "none", "FAIL" if slop else "PASS"),
        ("META", ", ".join(frames) or "none", "FAIL" if frames else "PASS"),
        ("LINKS", f"{ext} external (want ≥{link_floor}) · {dead} placeholder/dead",
         "FAIL" if dead or ext < link_floor else "PASS"),
        ("STAT-CITED", f"{len(blocks) - unsourced}/{len(blocks)} shipped/lead blocks carry a link or data-selfreport",
         "FAIL" if unsourced else "PASS"),
        ("IMAGES", f"{imgs} img · {onerr} onerror · {alts} alt",
         "PASS" if imgs == onerr == alts else "FAIL"),
        ("DETAILS", f"{details} (want 2–5)", "PASS" if 2 <= details <= 5 else "WARN"),
        ("EMDASH", f"{em} on the page (≤4; the allowance covers quoted material)",
         "PASS" if em <= 4 else "WARN"),
        ("RATHER", f'"rather than" ×{rather} (≤2)', "PASS" if rather <= 2 else "WARN"),
        ("HEXCHECK", ", ".join(hexes) + " — use var(--…) tokens" if hexes else "no raw hex in body",
         "WARN" if hexes else "PASS"),
        ("MINS", "; ".join(mins) or "section minute counts agree",
         "WARN" if mins else "PASS"),
        ("SHAPE", (f"item words {items} · " + ("too alike: " + ", ".join(alike) if alike else "varied"))
         if len(items) > 1 else f"only {len(items)} <article class=\"item\"> found — check the markup",
         "WARN" if alike or len(items) < 2 else "PASS"),
    ]
    w = max(len(k) for k, _, _ in R)
    for k, msg, st in R:
        print(f"{k.ljust(w)}  {st:4}  {msg}")
    fails = [k for k, _, st in R if st == "FAIL"]
    warns = [k for k, _, st in R if st == "WARN"]
    if fails:
        print(f"\nFAILED: {', '.join(fails)} — fix and re-run.")
        sys.exit(1)
    if warns:
        print(f"\nWARN: {', '.join(warns)} — fix unless you can say why not, in one colophon line.")
    print("\nMechanical checks done. Now read the page for the judgment checks in SKILL.md.")


if __name__ == "__main__":
    main()
