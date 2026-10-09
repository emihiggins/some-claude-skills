#!/usr/bin/env python3
"""Embed Archivo into a finished brief so it renders offline, on any machine.

    python3 scripts/embed_fonts.py briefs/2026-07-31.html

Replaces the <!--FONTS--> marker with base64 @font-face rules built from
assets/fonts/*.woff2. Run it once, after the content is written and before the
screenshot. It is idempotent — a page that already has the block is left alone.

Why a build step instead of shipping the base64 inside the template: the four
woff2 files are ~57KB, which becomes ~77KB of base64 in the file. Keeping that
out of the template means you never have to read it, and the template stays a
document you can edit. Without this step the page still renders in the system
sans, so a failure here degrades rather than breaks.
"""
import base64, pathlib, re, sys

MARK = "<!--FONTS-->"
WEIGHTS = (400, 600, 700, 800)


def main():
    if len(sys.argv) != 2:
        sys.exit("usage: embed_fonts.py <brief.html>")
    page = pathlib.Path(sys.argv[1])
    fonts = pathlib.Path(__file__).resolve().parent.parent / "assets" / "fonts"
    try:
        html = page.read_text(encoding="utf-8")
    except OSError as e:
        sys.exit(f"cannot read {page}: {e.strerror}")

    if re.search(r"@font-face\s*\{", html):
        print("fonts already embedded — nothing to do")
        return
    if MARK not in html:
        sys.exit(f"no {MARK} marker in {page} — was it copied from assets/brief.template.html?")

    faces = []
    for w in WEIGHTS:
        f = fonts / f"archivo-latin-{w}-normal.woff2"
        if not f.exists():
            print(f"missing {f.name} — skipping weight {w}")
            continue
        b64 = base64.b64encode(f.read_bytes()).decode()
        faces.append(
            "@font-face{font-family:'Archivo';font-style:normal;font-weight:%d;"
            "font-display:swap;src:url(data:font/woff2;base64,%s) format('woff2')}" % (w, b64)
        )
    if not faces:
        print("no font files found — the page will use the system sans, which is fine")
        return

    page.write_text(html.replace(MARK, "<style>" + "".join(faces) + "</style>", 1), encoding="utf-8")
    kb = sum(len(f) for f in faces) // 1024
    print(f"embedded {len(faces)} weights of Archivo ({kb}KB) into {page.name}")


if __name__ == "__main__":
    main()
