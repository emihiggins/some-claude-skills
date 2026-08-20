# Gather — the sweep

Read this at step 1. The job: collect the user's own work for today from the lanes enabled in
`PROFILE.md`, and return each lane as a compact structured stat list. Keep the main context for
judgment — a lane that returns prose has failed its brief.

**The shell is allowed here** (unlike daily-brief). `gh`, `git`, and MCP tools are how this
skill sees the user's work. What is *not* allowed is a write: this skill reads only. Never
transition an issue, comment on a PR, or post to Slack.

## The window

"Today" in the reader's timezone: local midnight → now. Derive the date string once at step 0
and pass it to every lane. For GitHub search, the date is `YYYY-MM-DD`; for git, `--since` a
local-midnight timestamp; for Jira, `updated >= startOfDay()` or `-1d`.

## The stat contract

Every lane returns a list of rows in this shape, nothing else:

```
kind | title | the number(s) that matter | url-or-"-" | id (for dedup) | status
```

- `kind` — pr | commit | issue | review | page | deploy | meeting
- `id` — the dedup key written to `MEMORY.md`: PR number, commit sha, issue key, deploy id.
- `status` — done | in-progress | merged | open | reviewed | attended, so compose can route it to Shipped vs Moved forward.

## Lanes

The user's setup is whatever `PROFILE.md § Sources` lists — one row per source, each carrying an
`access` token that says how it is reached. Iterate those rows; do not assume a fixed set. The
per-tool detail (detection probe, query/read recipe) lives in **`references/sources.md`**, one
adapter per tool. Run each enabled source through `detect()` then `gather()`.

### Four outcomes — classify every lane

Each lane resolves to exactly one outcome. This is the core of the skill's resilience: an
auth-expired source and a genuinely empty one look similar but must be handled differently.

| Outcome | How you know | Do | Health update (`MEMORY § Source health`) |
|---|---|---|---|
| **live-data** | the real tool/CLI ran and returned rows | use the rows | `last_success=today · status=live · seen↑ · consec_empty=0 · needs_reauth=no` |
| **live-empty** | the real tool ran, returned zero rows, no error | run the **anomaly check** (`sources.md`) | `status=live · consec_empty↑ · today counts as a miss in the seen ratio` |
| **auth-fail** | for `mcp-auth:` only the `authenticate`/`complete_authentication` stubs exist, or a call 401s; for `cli:gh`, `gh auth status` fails though a token was expected | run **auth recovery** (`sources.md`) — interactive prompts, unattended flags `needs_reauth` | `status=auth-expired`; **do not** touch `last_success` or the seen ratio |
| **not-present** | profile `on` but the `local:` path/CLI is genuinely gone | treat as a possible **tool-switch** (`sources.md`); else skip | note off; colophon line if it was previously on |

Detection, recovery, the anomaly check, and the handshake are all specified in
`references/sources.md`. Reflection input (step 2) is layered on top of whatever the lanes return.

## Turning rows into the page

- **Shipped** = rows with status merged/done/deploy. Rank by significance (touches a goal >
  unblocks others > size), not by time.
- **Moved forward** = status in-progress/open/reviewed/page, and partial progress the
  reflection surfaced.
- **Scoreboard** counts: PRs merged, commits, issues done, story points, reviews, meeting h,
  focus h — each a sum of real rows. Yesterday's comparison and the sparkline come from
  `LEDGER.md`, not from a query.
- **Reflection** rows are the user's words — route them to the right section, marked
  `data-selfreport`, and never add them to a scoreboard count.

## Degrade honestly

Every non-`live-data` outcome earns one plain colophon line, and never a fabricated number:
- **live-empty** (confirmed or sporadic): "no new {tool} today" — after the anomaly check.
- **auth-fail**: "Jira couldn't authenticate today" — plus, unattended, "I'll ask you to
  reconnect next live run"; interactive, you will have already offered the handshake.
- **not-present / off**: only worth a line if the source was previously on.

If most lanes fail at once, say so in chat and offer to fix config or reconnect, rather than
shipping a hollow page. A short honest recap is a good recap; a padded one ends the habit. Full
recovery, anomaly, and tool-switch procedures are in `references/sources.md`.
