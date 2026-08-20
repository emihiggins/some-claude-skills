# Design — rendering the page

Read this at step 4, once the text is written and checked. The design is inherited from
daily-brief's "Digest": a white sheet on warm grey, a black masthead, black section rules, big
grey item numerals, boxed axioms, pill expandables, and a yellow marker on the numbers that
matter. **Do not rewrite the stylesheet, change the palette, or swap the typeface.**

## Build

```bash
mkdir -p ~/day-review/reviews
cp {skill}/assets/review.template.html ~/day-review/reviews/{YYYY-MM-DD}.html
# ... replace the content between the section comments ...
python3 {skill}/scripts/embed_fonts.py ~/day-review/reviews/{YYYY-MM-DD}.html
python3 {skill}/scripts/check.py ~/day-review/reviews/{YYYY-MM-DD}.html --length {length}
```

`embed_fonts.py` runs **last, after the content is final** — it swaps the `<!--FONTS-->` marker
for base64 Archivo so the page renders offline. It is idempotent and degrades to the system
sans if the fonts are missing, so a font failure is never worth a retry. Leave the marker alone
while editing.

Three things go stale after day one and are wrong every day after: the `<title>`, the masthead
stamp (date + `as of` + read time), and the colophon (counts + promise). Fix all three.

Delete whole sections that have nothing to say, including their rule and their jump chip.

## Components

The template ships worked markup for every section. Reused daily-brief atoms:

| Class | Use |
|---|---|
| `.masthead` | `.wordmark` "Day in Review" left, `.stamp` right (uppercase date · `AS OF …` · `N MIN READ`) |
| `.jump` / `.chip` | One chip per rendered section (Scoreboard, Shipped, Moved forward, Goals, Trend, Tomorrow, Close). ≤8 chips; check at 390px |
| `.the-line` | The one sentence about the day |
| `.rule` | Section header: `.tag` (black chip, ≤22 chars) + `.bar` + optional `.mins` |
| `.tape` / `.spark` | The scoreboard cells and the trend sparkline |
| `.item` / `.n` | A Shipped/Moved entry: `<div class="n">01</div>` then a `<div>` with everything else |
| `.ax` | An axiom box; `<b>` is the label |
| `.your-day` / `.day-row` / `.tick` | The Tomorrow block: ticks Blocked · Queued · Reminder (`.tick.muted` for a reminder) |
| `details` / `.det` | Pill expandable — the `+`/`−` is drawn by CSS |
| `.close` | Black block: `blockquote` → `cite` → `.gift` with its `.kicker` |
| `.colophon` | Mono, outside the black block |
| `.src` | Source/artifact lines — also tells `check.py` not to count them as item prose |
| `.mark` | The yellow highlight |

**Data components (v3).** The classes for charts/meters/calendar/table/heatmap/pills/tiles/
highlight-card live in the stylesheet and are catalogued, with the decision rules, in
`references/visuals.md`; worked markup for each is in `assets/components-gallery.html`. Three
rules govern them here:
- **Skeleton stays invariant.** Masthead, the-line, `.item`s, `.rule`s, `.close`, colophon and
  type never take radius/shadow/accent — only data blocks do.
- **Tokens only.** Fills/strokes use `var(--c1…--c6)`, `var(--accent)`, `var(--up/--down/--warn)`,
  `var(--sunk/--pill/--ink)`; relief/3D uses `white`/`black` + `fill-opacity`. Never a raw `#hex`
  in the body — `check.py` HEXCHECK warns on it, and hex breaks the dark-mode flip.
- **Depth is scoped** to `--r` (6px) and `--lift`; one `--accent` per page. Charts carry
  `role="img"` + `aria-label` and a text value/legend.
- **Dashboard/newsletter width.** The sheet is `max-width:1040px` — data blocks (tape/tiles,
  charts, tables, calendar, heatmap) span the full width; **prose stays a readable measure** via
  the `.prose` class (`max-width:66ch`) and the caps on `.item`/`.lead`/`.ax`. Use `<p class="prose">`
  for section prose instead of an inline `font:` style, so long lines never form on the wide sheet.

**The scoreboard** is a `.tape` of six cells (label `.t`, value `.v`, change `.c` with
`.up`/`.down`). Use `.c` for a delta vs yesterday from the ledger, or `—`/`↑` when there is no
clean number. The `.spark` is a `<polyline>` over `viewBox="0 0 300 46"`; plot only real ledger
values, `y = 42 − 36×(v−min)/(max−min)`, stroke `var(--up)`. Draw it yourself — never hunt for
a chart image.

**STAT-CITED.** Every `.item` block must carry an artifact link in a `.src` line (PR/issue/
deploy/commit URL), or, when it is the user's own reflection, be marked with a
`data-selfreport` attribute on the article so the checker exempts it. Reflection example:
`<article class="item" data-selfreport>`.

**The marker is rationed** — one `.mark` per block, four on the page, on a number/name/date
that *is* the point (`11&nbsp;commits`, `12 of ~20 apps`, `Done`). Join multi-word marks with
`&nbsp;` and put trailing punctuation inside the span.

**Minute counts.** A section's `.mins` is its words ÷ 240, rounded, floor `1 MIN`. `check.py`
recomputes each and names any that disagree; a section under ~120 words carries no `.mins`. The
Shipped/Moved rules also carry the item count: `3 ITEMS · 1 MIN`.

## No images, usually

A work recap rarely has a real image to show; the scoreboard and sparkline are the visuals.
Skip decorative art entirely (the checker's IMAGES parity check passes at `0 · 0 · 0`). If you
ever embed a real chart image, it needs `alt` and an `onerror` `.imgfail` fallback with no
apostrophes inside the `onerror` string.

## Screenshot and look

```bash
node -e "const{chromium}=require('playwright');(async()=>{
const b=await chromium.launch({executablePath:'<chromium path>'});
const p=await b.newPage({viewport:{width:900,height:1500},deviceScaleFactor:2});
await p.goto('file://ABSOLUTE/PATH.html');await p.waitForTimeout(500);
await p.screenshot({path:'/tmp/review.png',fullPage:true});
const m=await b.newPage({viewport:{width:390,height:900}});
await m.goto('file://ABSOLUTE/PATH.html');await m.screenshot({path:'/tmp/review-m.png',fullPage:true});
await b.close();})();"
```

If the bundled `executablePath` is missing, find the installed Chromium under
`~/Library/Caches/ms-playwright/chromium-*/chrome-mac/Chromium.app/Contents/MacOS/Chromium`.

Check on the slices: headings are Archivo (not a system fallback — else `embed_fonts.py` did
not run) · the scoreboard tape wraps to two rows on mobile and the sparkline renders · jump
chips fit one or two rows · every rule's black bar reaches the right edge · markers are on
numbers and there are ≤4 · one expandable opens and closes · the close block has air above it.
Any **feature visual** renders and is sized right (a donut uses `svg.ring`, not full-width) ·
its colors track the tokens and there is no raw hex.

**Dark mode + the gallery.** Take a **dark-mode** screenshot too (`colorScheme:'dark'` on the
page) and confirm every data block flips — bars/accent/pills/calendar/table all recolor, the 3D
overlays still read. When you add or change a component, render `assets/components-gallery.html`
(light, dark, 390px) and eyeball the whole catalog before shipping it in a daily page.

## Deliver

`open` the HTML on macOS so it renders in the browser, and say one or two sentences in chat
about the day. Never summarize the summary. The stylesheet carries a dark-mode block; keep it.
