# Visuals — the data vocabulary and how to choose it

Read this at compose time (step 3) whenever the day's data could be shown, not just told. It
holds the component catalog and the decisioning guide that keeps day-to-day choices consistent.
The **canonical, rendered markup for every component lives in `assets/components-gallery.html`** —
open it to copy a block; the snippets below are the shape and the rules.

## The consistency contract (read first)

- **The skeleton is invariant.** Masthead, the-line, `.item`s, section `.rule`s, `.close`,
  colophon, and Archivo type never change. Only *data blocks* use the vocabulary below.
- **Tokens only, never raw hex.** Fills/strokes are `var(--c1…--c6)`, `var(--accent)`,
  `var(--up)/--down/--warn)`, `var(--ink)/--sunk/--pill)`. 3D/relief uses neutral `white`/`black`
  with `fill-opacity`, never a hex. This is what makes dark mode work; `check.py` HEXCHECK warns
  on stray hex.
- **Depth is scoped.** `--r` (6px) and `--lift` (soft shadow) appear only on data blocks
  (cards, tables, calendar, tiles). The skeleton stays flat and square.
- **One accent.** `--accent` (indigo) marks "today"/due-dates, the latest/most-important bar, a
  single-ratio donut, and the highlight card. Don't spread it; it means "look here".
- **Every chart is labeled.** `role="img"` + a descriptive `aria-label`; a value or legend in
  text (the light-mode palette needs this "relief" for the lower-contrast hues). Text stays in
  ink tokens, never the series color.
- **Marker budget still ≤4** `.mark` per page, and charts are **label-light** (they count toward
  the WORDS budget).

## Catalog

Each entry: when to use · the shape. Full markup in the gallery.

**Bar chart · 3D codey** (`.viz` + inline SVG) — throughput by day / source / repo (≥3 bars).
The house style is techy/cartoon: bold outlines + graph-paper grid + pixel-block etch + monospace
labels. Build order per the gallery: (1) a `.tagline` terminal caption, e.g. `$ prs_merged
--since mon`; (2) a faint dashed grid `<g stroke="var(--hair2)" stroke-dasharray="2 5">`; (3) the
prisms inside `<g stroke="var(--ink)" stroke-width="2" stroke-linejoin="round">` — front `rect
fill="var(--c1)"`, light top `polygon fill="white" fill-opacity=".5"`, dark side `polygon
fill="black" fill-opacity=".2"`, latest/hero bar `fill="var(--accent)"`; (4) a `<g stroke="white"
stroke-opacity=".3">` of short horizontal lines etching each front into pixel rows; (5) a solid
`var(--ink)` baseline; (6) value + axis `<text>` in `font-family="var(--mono)"` (fill
`var(--ink)` / `var(--mute2)`). Single-series by default; for a breakdown use `--c1…--c6` in fixed
order + a legend. Keeps the value labels (the light-mode "relief" rule).

**Meter · pill** (`.meter`) — one ratio: goal %, sprint %, focus share. Track `--sunk`, fill
`--accent` (or `.up` green / `.c1` blue), value in the corner. Thin (10px), fully rounded.

**Segmented · milestone** (`.seg`) — discrete steps, e.g. the Splunk goal (`i.on` × 3, `i` × 1).
Use when progress is stages, not a percentage.

**Stacked bar** (`.viz` + two `rect`s, 2px gap) — a split of one total: meeting vs focus hours,
PR additions vs deletions. Colors `--c2`/`--c3`; legend dots below.

**Sparkline** (existing `.spark`) — a trend over time from the ledger. Only once there are ≥5
data points; before that, omit (don't draw a 2-point line).

**Donut / ring** (`.viz svg.ring`) — a single headline ratio as a dial, big number centered.
Track `--sunk`, arc `--accent`, `stroke-linecap="round"`, `stroke-dasharray` = ratio×circumference.

**Bullet** (`.viz` + track + fill + tick) — value vs a target/average: today's PRs vs your daily
average (the tick). Fill `--c1`, tick `var(--ink)`.

**Calendar · upcoming** (`.cal`) — dated items in the next ~7 days: due dates, deadlines,
meetings. Hairline 7-col grid, `.today .d` accent circle, `.cal-chip` events, `.cal-chip.due`
red. Category dots below. Feed from calendar + Jira due dates + reminders.

**Streak heatmap** (`.heat`) — consistency over ~4 weeks from the ledger; `i.l1/.l2/.l3` = activity
intensity in `--up`. The long-view companion to the streak number.

**Table** (`.dtable`) — a set of records: the ledger rollup, PR/ticket lists, source-health.
Uppercase muted headers, zebra rows, right-aligned numerics (`.num`), `.pill` status cells.

**Status pill / dot** (`.pill.ok/.warn/.bad/.acc`, `.dot`) — state that must not be color-alone;
always carries a word. Live/Reconnect/Blocked/Done.

**Highlight card** (`.hcard`) — the day's one durable win (the brag-doc line), accent-soft bg +
accent left border + lift. At most one per page.

**Stat tiles** (`.tiles`/`.tile`) — an elevated alternative to the flat `.tape` scoreboard when a
day deserves a little more presence; same numbers, card treatment.

### More components & variants (all in the codey house style)

- **Horizontal bars · ranked** (`.hbars`/`.hbar`) — a ranked list: commits by repo, PRs by
  project, issues by status. Mono label, outlined bar, value at the end; top item in the accent.
- **Grouped bar · 2 series** (inline SVG) — two measures per category, e.g. merged vs opened by
  day; `var(--c1)`/`var(--c2)` + a legend.
- **Diverging bar** (inline SVG) — signed magnitude around a center axis: PR additions (`--up`,
  right) vs deletions (`--down`, left). The diff-stat look.
- **Gauge · semicircle** (`.viz svg.gauge`) — a single bounded ratio, lighter than the donut.
- **Waffle · 10×10** (`.waffle`) — a percentage as 100 pixel cells (focus share, test coverage).
  Very pixel/codey; each `i.on` = 1%.
- **Sparkbars · inline** (`.sparkbars`) — a tiny inline bar row for an at-a-glance trend beside a
  number; last bar `.hi` in the accent.
- **Terminal · code block** (`.term`) — a dark shell block for a real command or its output
  (`gh pr list …`, a diff-stat). Always dark, fixed syntax colors; the signature codey element.
  Use for something the reader could copy-run, never as decoration.
- **Agenda · timeline** (`.agenda`) — a dotted vertical timeline of dated/timed events; the
  time-of-day variant of the calendar, good for "today's shape".
- **Callouts** (`.callout.info/.ok/.warn/.bad`) — a one-line flagged note with a glyph tile; for a
  blocker, a heads-up, or a win that isn't the single headline.
- **KPI card** (`.kpi`) — one big monospace number + a delta, for a hero metric (focus this week).
- **Key chips** (`.kbd`) — pressable-key tokens for commands/shortcuts referenced in the recap.
- **Log table** (`.dtable.log`) — the table in full monospace, for a chronological event log.

## Decisioning — choose per day, adaptively

**1 · Match the visual to the data's shape:**

| The data is… | Show |
|---|---|
| a trend over time (≥5 ledger days) | sparkline, or a day-by-day bar |
| one ratio / percentage | meter, or donut for the hero one |
| discrete stages | segmented/milestone bar |
| a split of a total | stacked bar |
| a breakdown across categories (≥3) | grouped 3D bars + legend |
| a ranked list (by repo/project) | horizontal bars |
| two measures per category | grouped bar (2 series) |
| signed magnitude (adds vs deletes) | diverging bar |
| value vs a target/average | bullet |
| a percentage, pixel-styled | waffle, or gauge for a dial |
| a tiny inline trend beside a number | sparkbars |
| dated items in the next week | calendar strip |
| a timed schedule for today | agenda timeline |
| consistency over weeks | streak heatmap |
| a set of records | table (+ status pills) |
| a chronological event log | log table |
| a real command / its output | terminal block |
| a hero metric | KPI card |
| a blocker / heads-up / small win | callout (warn / info / ok) |
| the single best thing today | highlight card |

**2 · Earn-its-space / omit:** no chart for <3 points (use a stat tile or a sentence); no
sparkline under 5 ledger days; drop any block that would render empty or near-empty; a meter/
milestone only when a goal exists; a calendar only when there are dated items to place; a heatmap
only once the ledger has a couple of weeks. A visual must encode something true — never decorate.

**3 · Ration by length** (`check.py --length`):
- **quick** — scoreboard tape only; no feature visuals.
- **standard** — tape (or tiles) + **one** feature visual, chosen by what the day is *about*.
- **full** — **two to three** feature visuals, spread across sections; never a wall of charts.
Prose still leads; a visual replaces a paragraph only when it says it better.

**4 · Placement:** a visual sits inside the section it serves (a meter in Goal check, a table in
Trend/source-health, a calendar in Tomorrow, bars in the Scoreboard/Trend). One accent per page.
**Name the chosen visuals in the colophon** (e.g. "shown: goal meter, source-health table") so a
reader knows the day's shape was a choice.

**5 · Consistency across days:** the *decision rule* is fixed even though the output varies — the
same data shape always picks the same component, so a reader learns the vocabulary. Record nothing
extra in memory; the guide is deterministic given the day's data.
