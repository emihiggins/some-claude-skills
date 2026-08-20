# Setup — the interview that builds the reader

Read this on the first run, when `PROFILE.md` is missing, or when the user asks to set up or
rebuild their recap. The goal is a profile specific enough that the first page could not have
been written for anyone else. Four rounds, one message each; **write `PROFILE.md`, `LEDGER.md`,
and `MEMORY.md` after every round**, not at the end. Batch choice-shaped questions into a
single `AskUserQuestion` per round.

**Round 1 is the whole interview.** Name, timezone, work hours, length, and one connected
source are enough to build a real page. Everything after makes it better and none is required.

## Round 0 — Scout before you ask (no message sent)

One parallel pass to learn what to offer, from connected tools only. Probe **every category**,
and for each source record whether it is **live**, **auth-gated** (present but behind the OAuth
handshake), or **not-present** — that classification is what Round 2 offers from. See
`references/sources.md` for the detection rules.

- **code** — `gh auth status` (both hosts) → GitHub host/org; `git config user.email` and any
  repos under the user's dev dirs → candidate local repo paths + author identity.
- **tracker** — Jira whoami via Atlassian MCP (`atlassianUserInfo` / `getAccessibleAtlassianResources`)
  → cloudId + account; recent projects from a quick `assignee = currentUser()`. (Linear/Asana: not
  present here → offer as `unsupported-here`.)
- **calendar / chat / docs / mail** — which MCP servers are **live** (real tools callable, e.g.
  Glean, Atlassian) vs **auth-gated** (only `authenticate`/`complete_authentication` stubs, e.g.
  Slack `mcp-auth:Slack`, Microsoft 365 `mcp-auth:Microsoft_365`). Do not run a handshake during
  setup; just note "available, needs a one-time connect."
- **notes** — read `~/Library/Application Support/obsidian/obsidian.json` for a vault path
  (`.vaults[].path`, prefer `open:true`), and test for Apple Notes at
  `~/Library/Group Containers/group.com.apple.notes/NoteStore.sqlite`. Report which exist.
- **deploys** — is `tarmac` on PATH?

Turn that into concrete proposals ("You're on github.expedia.biz in eg-internal, Jira shows
ESCTEN, and I found an Obsidian vault at ~/Documents/Obsidian Vault — track those?") so Round 2
confirms rather than asks cold. Read identifiers and paths, never private content. Nothing
connected → ask in prose in Round 2.

## Round 1 — Open, and set the shape

One warm paragraph: what this is (one page each evening from your own work, plus a running
ledger), what it costs (a few questions now), and that they can change any of it later.

Ask, as choices:
- **"How long should the recap be?"** — *Quick (≤400 words, scoreboard + top wins)* ·
  *Standard (~800, the full page)* · *Full (~1500, with rollups and every thread)*.
- **"When does your workday end, and which days?"** — sets the `as of` default and the streak's
  "working days" (weekdays vs every day).

In prose alongside: what to call them, and confirm the timezone (`Area/City`) and the language
they are writing in. Infer and confirm rather than ask.

Write all three files now, from this alone.

## Round 2 — Sources, by category, offered not requested

Go **category by category** — calendar, tracker, code, notes, chat, docs, deploys — and for each
ask which tool the user actually uses, defaulting to what the scout found. The point is that no
two users have the same stack: someone may keep notes in Obsidian and someone else in Apple Notes;
someone tracks in Jira and someone in GitHub Issues; some have no tracker at all. Offer the
scout's live/auth-gated options plus "something else" and "none".

For each chosen source, write a row to `PROFILE.md § Sources` with its **access token** (how it is
reached — see `sources.md`): e.g. `cli:gh@github.expedia.biz`, `mcp:atlassian`,
`mcp:Glean/meeting_lookup`, `local:obsidian:<vault path>`, `local:apple-notes`, `mcp-auth:Slack`.
Per-category specifics to capture:
- **code** — host, org, repos, local repo paths (the `GH_HOST` rule for enterprise).
- **tracker** — account is `currentUser()`, story-point field (default `customfield_10031`), or off.
- **calendar** — Glean vs M365 (or none); needed for meeting-vs-focus hours.
- **notes** — Obsidian (store the vault path) and/or Apple Notes, or none.
- **chat** — Slack (`mcp-auth`, default off, noisier) / Teams-via-Glean / none.
- **docs** — Confluence / M365 SharePoint / none.
- **deploys** — service names to watch, or off.

For an **auth-gated** source the user wants, mark it `on` with its `mcp-auth:` access; the first
run does the one-time handshake. For a tool named but **not reachable here** (Notion, Linear,
Google Cal), record it `on` with `access unsupported-here` and say plainly it is not wired yet
(pointer: `sources.md` adapter contract) — so nothing is lost and it is easy to add later. Say
which sources the scout could not confirm; an unconfirmed one stays off until turned on. Mark
guesses `(guessed)`. Also seed a `MEMORY § Source health` row per enabled source.

## Round 3 — Goals and what counts

- **"What are you working toward, and is there a number on it?"** — one or two goals **with a
  numeric target** where one exists (`HDC migration: 20 apps`), so the ledger can plot a slope.
  A goal with no measurable target still gets a light weekly touch; say so.
- **"What counts as 'done' for you?"** — e.g. merged-to-main vs deployed-to-prod; whether
  review-only days should hold the streak. This tunes the scoreboard and streak rules.

## Round 4 — Register and delivery

- **"Which quote register?"** — *Builder / operator* (founders, engineers, people who shipped)
  · *Plain and stoic* · *Literary* · *No quotes*. One real quote as each preview.
- **"Where should it land, and should I run it on a schedule?"** — *Here in chat* · *Just save
  the file* · *A scheduled evening run*. If scheduled, go to § Schedule.

## Weights and confirmation

Derive nothing numeric to ask about; confirm in one line: "So — GitHub (enterprise, eg-internal)
and Jira ESCTEN as the core, calendar on for the hours, Slack off, and the HDC migration as the
goal to track. Right?" Fix the file on the spot if wrong; don't re-run the round.

## Write the files

`PROFILE.md` in the shape shown in `SKILL.md § Reader files`, human-editable. `LEDGER.md` and
`MEMORY.md` from the skeletons in `references/ledger.md` — empty tables with headers, streak 0,
started today. Show the sources, goal, and length in three lines and ask if it looks right.

## If they stop answering

The profile on disk after Round 1 is already valid. Next "wrap up my day" runs the recap; open
with the page and offer to finish setup. "Just start" → fill the rest at defaults (all optional
sources off except the one the scout confirmed), build the page, invite corrections. Never
re-ask a declined question. Never invent a goal or a source that was not confirmed.

## Schedule

Only when asked, and only after two preconditions hold, both borrowed from daily-brief:
1. **A folder that outlasts the session** — `~/day-review/` on disk, not the session workspace.
2. **A channel that reaches them** (Round 4).

Use the **Remote MCP scheduled-task tools (`create_trigger`)**, never in-session cron. Cron
fires in UTC — convert from the user's offset, and shift the day fields when the conversion
crosses midnight:

| Reader | Local | UTC | Cron |
|---|---|---|---|
| Denver, weekdays | 17:30 (UTC−6) | 23:30 same day | `30 23 * * 1-5` |
| New York, weekdays | 17:30 (UTC−4) | 21:30 same day | `30 21 * * 1-5` |
| London, weekdays | 18:00 (UTC+1) | 17:00 same day | `0 17 * * 1-5` |

DST does not move a UTC cron, so a fixed evening time drifts an hour for half the year — say so
once and put the changeover in `PROFILE.md § Reminders`. The trigger prompt must stand alone:

> Run the day-review skill and produce today's recap for {name}. The reader folder is
> `{absolute path}` — read `PROFILE.md`, `LEDGER.md`, and `MEMORY.md` there first, then write
> today's page into `reviews/`. This is an unattended run: skip the reflection questions, make
> the reasonable call on anything ambiguous, and note assumptions in the colophon. Deliver by
> {channel}.

Record the trigger id in `PROFILE.md § Reader → Delivery`; tell them "say 'stop it' any time".
A scheduled evening run with delivery "here in chat" writes a page nobody sees — say so and
prefer a push/save channel.

## Then run one

Offer to build today's recap immediately. The first page is what tells them whether the sources
and goal are right, and it is far easier to correct a real page than a list of settings.
Whatever they say afterward goes to `PROFILE.md § Lessons` and applies from the next run.
