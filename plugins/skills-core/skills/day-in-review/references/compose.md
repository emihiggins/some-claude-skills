# Compose — writing the recap

Read this at step 3. Write the whole page as plain text and get it right before opening any
HTML. Prose problems become invisible once they are wrapped in tags.

## The item

Every entry in Shipped and Moved forward takes the same shape, borrowed from daily-brief:

```
[Title — 7 words or fewer, you doing a concrete thing]
[First sentence: what it was, and its number. It stands alone.]
[Optional: one more sentence of specific detail]
[One axiom line]
[Optional <details>: the tricky part, the follow-up, the source]
[.src line with the artifact link]
```

The discipline is **abandonability**: a reader who stops after the first sentence still has the
item. Titles name you doing a thing — "Merged the cloud migration for orders-api-gateway", not
"cloud migration work". Rank Shipped by significance, not by clock time: what touches a goal, or
unblocks other work, or was hard, leads.

**Break the rectangle.** No two consecutive items within 20% of each other in length
(`check.py` prints the counts). Every section wants one item under 40 words. A review-only or
small item is allowed to be one line.

## Axioms

One labelled line per item that turns the fact into something the user can use.

| Axiom | Use it for |
|---|---|
| **Why it counts** | Why this ship mattered — the goal it serves, the thing it unblocks |
| **In your book** | Ties to a goal, a workstream, a sprint total the user is tracking |
| **What's next** | The date or step that finishes an in-progress item |
| **The catch** | The limitation or the follow-up the merge left behind |
| **By the numbers** | Two or three figures that carry it (needs real figures) |

An axiom that can be deleted without losing a fact is decoration. At least one axiom per page
should tie to a `PROFILE.md` goal or workstream — that is what makes it *this* user's recap.

## The line

One sentence at the top, naming the shape of the day: a build day, a meeting-heavy day, a day
that unblocked others, a quiet-but-cleared-the-backlog day. Never a command, never a pep talk,
never a question. If the day was thin, say so plainly and do not perform: "A light day — one
review and a lot of meetings, which is its own kind of information."

## Scoreboard

The `.tape` of six figures, then, at standard and up, a `.spark` of the last ~10 working days
from `LEDGER.md`. **Every block of numbers gets one sentence of plain reaction** — the tape
alone is something an app could show; the sentence is the judgment. Compare to the week's
average or to yesterday, using ledger numbers, not a fresh query. Stamp the `as of` time.

## Goal check & Trend

- **Goal check** — progress vs each `PROFILE.md` goal, with the dated slope from the ledger:
  "12 of ~20 apps, up one today; at the fortnight's pace, a late-October finish." Never nag,
  never invent a target the profile does not name. A goal the day did not touch gets skipped,
  not a "no movement" apology.
- **Trend & streak** — the long view in two or three sentences: the streak, the week and month
  rollups. This is the section that rewards keeping the habit; keep it factual.

## Tomorrow

Blockers and the carry-over queue, as `.day-row` lines with ticks (Blocked · Queued ·
Reminder). These write to `MEMORY.md § Carry-over` so tomorrow's page can close the loop.
Reminders come from `PROFILE.md` and calendar deadlines within three days.

## The close

Three things, in order.

**The quote.** Real, verified this run, attributed to a named builder or operator (the
`PROFILE.md` register), carrying a `.src` link. Search it before using it — misattribution is
the most common failure. It should have purchase on the day: shipping, unblocking, finishing,
persistence. When a quote cannot be verified, use another.

**The gift.** One small durable pleasure that rewards finishing — a bonus stat from the day
("your busiest commit day since June"), a milestone crossed. It obeys the TALLY LAW: real and
linked. One gift, once.

**The colophon.** Build time, the number of lanes/sources that reported, the weighted word
count, any degradation in one plain line each, and one sentence promising tomorrow (written
also to `MEMORY.md`). Under 60 words. Report a thin or off lane flatly and never apologise.

## Prose (the banlist — reused from daily-brief, verbatim)

`scripts/check.py` is the executable form of this list.

**Cut outright:** delve, foster, leverage, utilize, facilitate, empower, streamline, robust,
cutting-edge, paradigm shift, game changer, this changes everything, tapestry, realm, beacon,
multifaceted, meticulous, intricate, paramount, transformative, elevate, embark, supercharge,
harness, ever-evolving, testament, pivotal moment, vital role, underscores, showcasing,
highlighting.

**Cut when empty:** just, literally, honestly, simply, actually, truly, fundamentally,
importantly, crucially, inevitably.

**Cut these phrases:** it's worth noting, it's important to note, at the end of the day, when
it comes to, at its core, in today's world, in the age of, the reality is, the truth is, in
terms of, going forward, let's dive in, in conclusion.

**Patterns to avoid:** meta-frames ("the part worth noticing"), binary contrasts ("not X, it's
Y"), balanced antithesis, throat-clearing, colon reveals, superficial `-ing` analysis,
importance puffery, weasel attribution ("studies show" — name the PR/ticket instead), synonym
cycling, dramatic fragmentation, fake-profound kickers, summary endings, robotic rhythm,
formatting slop. **Em dashes:** at most two in your own prose (quoted material and real titles
are exempt). **"rather than":** at most two on the page.

**Write instead:** active voice, concrete nouns, real numbers with units, the artifact that
proves it. "Cut the manual prod gate; the gateway now deploys on merge" — never "improved the
deployment process".

## Voice

Warm, specific, a colleague who watched your day and respects your time. Observe and hand over.
Never command, never cheerlead ("great job!"), never scold a light day, never narrate your own
process ("I queried GitHub…"). First person appears at most once, in the close. Dry in the
scoreboard and items, factual in Trend, warm in the close.
