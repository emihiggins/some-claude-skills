# Ledger — the long-term tracker

Read this at step 5. `LEDGER.md` is the cumulative, human-readable record that turns a pile of
days into a visible trend. It is appended every run and is meant to be opened and read on its
own — a brag doc, a progress chart in prose, and the source of every "how's my week" answer.

`MEMORY.md` is its silent companion: bookkeeping that keeps the ledger honest (dedup keys,
streak, carry-over). The user never needs to read `MEMORY.md`; they may well read `LEDGER.md`.

## LEDGER.md shape

```markdown
# Day in Review — ledger for {Name}
Started {YYYY-MM-DD}

## Daily throughput
| Date | PRs | Commits | Issues | Story pts | Reviews | Meeting h | Focus h | Tag |
|---|---|---|---|---|---|---|---|---|
| 2026-08-19 | 2 | 11 | 1 | 5 | 3 | 2.0 | 5.5 | migration |

## Goal progress
| Date | Goal | Value | Δ |
|---|---|---|---|
| 2026-08-19 | HDC migration | 12/20 apps | +1 |

## Time shape
| Date | Meeting h | Focus h | Meetings |
|---|---|---|---|
| 2026-08-19 | 2.0 | 5.5 | 2 |

## Highlights
| Date | Tag | Win |
|---|---|---|
| 2026-08-19 | migration | Cleared polaris-api-gateway, the riskiest app in the set; unblocked 3 more |

## Rollups
_Recomputed each run from the rows above._
- This week (Mon–today): 7 PRs · 3 issues · 5 reviews · 28h focus · 9h meetings
- This month: 24 PRs · 11 issues · tracking ~+15% on July's PR pace
- Streak: 8 working days
```

## Append rules

1. **One row per section per day.** After rendering, append today's row to Daily throughput,
   Time shape, and Highlights, and a Goal-progress row for each goal that moved.
2. **Dedup first.** Before counting, read `MEMORY.md § Dedup keys`. Any PR/issue/commit/deploy
   id already recorded for today is not re-counted. This makes a same-day re-run **update**
   today's row in place instead of appending a second one, and stops a PR that merged
   yesterday from re-appearing if it shows up in a wider query today.
3. **Same-day re-run = replace.** If a row for today's date already exists, overwrite its
   numbers with the fresh totals rather than adding a row.
4. **Goal progress is append-only** even when flat — a dated `+0` row is signal (it shows the
   day the number did not move). Only append when you actually checked the goal.
5. **One highlight per day**, tagged with a short kebab word reused across days (`migration`,
   `rbac`, `observability`) so the brag doc filters cleanly later.
6. **Rollups are derived, never authored.** Recompute the whole Rollups block from the table
   rows every run; never hand-edit a rollup number.

## MEMORY.md shape

```markdown
# Day in Review — memory

## Last run
2026-08-19 17:32 MDT · 720 words

## Streak
8   (working days with ≥1 PR merged or ≥1 issue Done; review-only days hold, gaps reset)

## Dedup keys — today
date: 2026-08-19
prs: [482, 479]
issues: [ESCTEN-1487]
commits: [a1b2c3d, ...]
deploys: [polaris-api-gateway#2026-08-19T21:04Z]

## Source health
One row per configured source; drives auth recovery and the anomaly check (see `sources.md`).
| Source | Last success | Access used | Status | Seen/last4 | Consec empty | Needs re-auth |
|---|---|---|---|---|---|---|
| github | 2026-08-19 | cli:gh@github.expedia.biz | live | 4/4 | 0 | no |
| jira | 2026-08-19 | mcp:atlassian | live | 3/4 | 0 | no |
| obsidian | 2026-08-18 | local:obsidian:/Users/…/Obsidian Vault | live | 3/4 | 1 | no |
| slack | 2026-08-12 | mcp-auth:Slack | auth-expired | 2/4 | 0 | yes |

## Carry-over
- Grid dashboard thresholds — blocked on one traffic day
- Roll sha-tag fix into the other 3 gateways

## Tomorrow's promise
Whether the three unblocked gateways move the migration number, and the grid thresholds.
```

## Source-health upkeep
Each run, after a lane resolves (`gather.md` four-outcome table), update its row:
- **live-data** → `Last success = today`, `Status = live`, push today as a hit into `Seen/last4`
  (a rolling ratio over the last four working-day runs), `Consec empty = 0`, `Needs re-auth = no`.
- **live-empty** → run the anomaly check, then `Status = live`, `Consec empty += 1`, push today as
  a miss into `Seen/last4`.
- **auth-fail** → `Status = auth-expired`; **do not** change `Last success` or `Seen/last4` (the
  history that marks the source "reliable" must survive an outage). Interactive: recover now.
  Unattended: `Needs re-auth = yes`.
- A source is **reliable** (eligible for the anomaly prompt) when `Seen/last4 ≥ 3`. A freshly
  added source starts empty and is not reliable until it builds a streak.
- At **step 0** of an interactive run, read every `Needs re-auth = yes` row and offer to reconnect
  before the sweep.

## Streak mechanics

- Increment when the previous **working day** (per the user's schedule; skip weekends for a
  weekday user) had a qualifying day and today does too.
- A qualifying day = at least one PR merged or one issue reached Done. A review-only or
  meeting-only day **holds** the streak (does not increment, does not reset) and is marked
  lighter in the ledger tag.
- Reset to 1 when a working day was skipped entirely.
- Do the streak math **before** overwriting `Last run`, since Last run is how you tell whether
  a day was missed.

## Reading the ledger back

For "how's my week / month / streak", answer from the Rollups block and the tables in chat —
no page. If the user asks for a specific past day, read that dated row. The ledger is a
suppression-and-truth record like daily-brief's `MEMORY.md`: when a fresh query contradicts a
stored row (a PR you thought merged was reverted), correct the row in place and note the
correction on the next page in one clause.
