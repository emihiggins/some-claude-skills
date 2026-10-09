# Sources — adapters, auth recovery, and health

Read this whenever a lane needs detail: how to reach a given tool, what to do when it fails to
connect, and how to tell "nothing happened today" from "something is broken". `gather.md` owns
the sweep orchestration; this file owns the per-source specifics and the resilience protocols.

The design goal is **adaptability**: a source is an *adapter* with a fixed shape, so a user's
setup is just a list of adapters, and adding a new tool later is mechanical.

## The adapter contract

Every source, present or future, is described the same way:

```
category   calendar | tracker | code | notes | chat | docs | deploys
tool       glean-calendar | m365 | jira | github | obsidian | apple-notes | slack | teams | ...
access     how it is reached — stored verbatim in PROFILE § Sources so the skill remembers
           HOW it last connected (the recovery path). One of:
             mcp:<Server>[/<tool>]      a live MCP server (Glean, Atlassian)
             mcp-auth:<Server>          an MCP server behind the OAuth handshake (Slack, Microsoft_365)
             cli:<bin>[@<host>]         a command-line tool (gh, spin)
             local:<kind>:<path>        a filesystem read (obsidian vault, apple-notes)
             unsupported-here           named by the user but no adapter in this environment
detect()   the probe that returns one of: live · auth-expired · not-present
gather()   runs the query/read and returns rows in the gather.md stat contract
```

To **add a source later**, add one adapter block below following this shape. Nothing else in the
skill needs to change — `gather.md` iterates whatever `PROFILE § Sources` lists.

## Access-method → how detect() and recovery work

| access prefix | detect() live-check | auth-fail signal | recovery (interactive) |
|---|---|---|---|
| `mcp:` | the real tool is present and a call succeeds | 401/permission error from a call | usually none needed; if it 401s, treat as `mcp-auth:` for that server |
| `mcp-auth:` | the server's **real** tools are callable | only `authenticate`/`complete_authentication` stubs exist for that server, or a call 401s | run the **handshake** (below) |
| `cli:gh` | `gh auth status --hostname <host>` exits 0 | it exits non-zero / "not logged in" | tell the user to run `! gh auth login --hostname <host>` |
| `cli:spin` | `spin application list` succeeds | auth error from the CLI | tell the user to re-authenticate the CLI (`~/.spin/config`) |
| `local:` | the path exists and is readable | n/a (a missing path is **not-present**, handled as a possible tool-switch) | re-detect the path; offer the tool-switch flow |

**The MCP handshake (mcp-auth recovery).** An MCP server that needs auth exposes *only*
`mcp__claude_ai_<Server>__authenticate` (no args) and `__complete_authentication({callback_url})`;
a live one exposes its real tools instead. To recover, interactive only:
1. Call `mcp__claude_ai_<Server>__authenticate` → it returns an authorization URL.
2. Give the user the URL: "Open this to reconnect <tool>, then paste the address it lands on."
3. Call `__complete_authentication({callback_url: <what they paste>})`. On success the real tools
   become callable; retry `gather()`.
4. Record `access` and `last_success` in the health table.

Never store the token or the callback URL anywhere. Auth lives in the MCP server and `gh`'s
keyring — PROFILE holds only the non-secret `access` token above.

## Adapters (wired in this environment)

**calendar · glean-calendar** — `access mcp:Glean/meeting_lookup`. detect: the tool is live here.
gather: `meeting_lookup(after=today, before=today)`; count non-cancelled meetings you attended →
meeting hours; focus hours = work-hours − meetings. (This is the v1 calendar lane.)

**calendar/docs/mail · m365** — `access mcp-auth:Microsoft_365` (server
`https://microsoft365.mcp.claude.com/mcp`). detect via the handshake rule. gather: Outlook
calendar for the day, and SharePoint/OneDrive docs you edited today. Use as an alternative to
glean-calendar when the user lives in Outlook.

**tracker · jira** — `access mcp:atlassian`. detect: `getAccessibleAtlassianResources` returns a
cloudId. gather three queries, because your work shows up under more than one relationship:
- `assignee = currentUser() AND updated >= startOfDay()` — issues you worked (and a Done-today
  variant for Shipped);
- `reporter = currentUser() AND created >= startOfDay()` — **tickets you filed today**, often for
  another team (e.g. a platform request); these are Shipped actions even though they're unassigned
  to you. Do not miss them by querying assignee alone.
- optionally `"Request participants" = currentUser()` for service-desk items you raised.
Request `key,summary,status,project,created,resolutiondate` plus story points `customfield_10031`.
A filed ticket links via `https://<site>/browse/<KEY>`.

**code · github** — `access cli:gh@<host>`. detect: `gh auth status --hostname <host>`. gather:
`gh search prs --author @me --merged-at ">=<DAY>"`, open PRs, `--reviewed-by @me`; honor
`GH_HOST` for enterprise. Local git commits via `git -C <path> log --since`. (v1 lane.)

**docs · confluence** — `access mcp:atlassian`. gather: `searchConfluenceUsingCql`
`contributor = currentUser() AND lastmodified >= startOfDay()`. (v1 lane.)

**chat · slack** — `access mcp-auth:Slack` (server `https://mcp.slack.com/mcp`). detect via the
handshake rule. gather: your own messages/threads today; summarize your contributions only, never
quote other people. Default off (noisier, higher permission).

**chat · teams** — `access mcp:Glean/search`. gather: Glean search for your Teams messages today
(Glean indexes Teams). No dedicated Teams server here.

**notes · obsidian** — `access local:obsidian:<vault path>`. detect: read
`~/Library/Application Support/obsidian/obsidian.json` and take `.vaults[].path` (prefer the one
with `open:true`); or `find ~ -maxdepth 5 -type d -name .obsidian`. gather (**titles/paths only,
never note bodies**): if the vault is a git repo, `git -C <vault> log --since="<DAY> 00:00" --name-only`;
otherwise `find <vault> -name '*.md' -not -path '*/.obsidian/*' -not -path '*/.trash/*' -newermt "<DAY> 00:00"`.
Each changed note → a `note` row (title = filename, url = `-`, id = relative path).

**notes · apple-notes** — `access local:apple-notes`. detect: the store
`~/Library/Group Containers/group.com.apple.notes/NoteStore.sqlite` exists. gather (**titles/dates
only**): `osascript -e 'tell application "Notes" to get {name, modification date} of every note'`,
filter to today's date. Do not read the SQLite bodies (gzipped protobuf) and never print contents.

**deploys · spinnaker/datadog** — `access cli:spin`. gather: prod deploys / pipeline runs you
triggered today for the services in PROFILE, and/or Datadog deploy events. (v1 lane.)

## Adapter stubs (named-but-not-wired here)

If a user names one of these, record it in `PROFILE § Sources` with `access unsupported-here` and
tell them it is not reachable in this environment yet. To wire it, add a full adapter above.

- **tracker · linear** — would be a Linear MCP or `linear` CLI (neither present).
- **tracker · asana** — Asana MCP/CLI (not present).
- **notes/docs · notion** — a Notion MCP (not present); would gather pages edited today by you.
- **calendar · google** — no dedicated Google Calendar MCP; only reachable if Glean indexes it
  (`mcp:Glean/search`), so a `google-cal-via-glean` adapter is the realistic path.

## Source health (drives auth recovery + anomaly checks)

`MEMORY.md § Source health` holds one row per configured source (schema in `ledger.md`). Each run,
after a lane resolves, update its row:

- **live-data** → `last_success = today`, `status = live`, bump the last-4 seen ratio, `consec_empty = 0`, clear `needs_reauth`.
- **live-empty** → run the **anomaly check**, then set `status = live`, `consec_empty += 1`, and record the last-4 ratio with today as a miss.
- **auth-fail** → `status = auth-expired`; **do not touch** `last_success` or the seen ratio (history is preserved so the anomaly logic still knows the source is normally reliable). Interactive: run recovery now. Unattended: set `needs_reauth = true` and move on.
- **not-present** (a `local:` path or CLI genuinely gone) → likely a tool-switch; see below.

## Auth recovery — by run mode

- **Interactive run.** On `auth-fail`, run the recovery for the `access` prefix (handshake for
  `mcp-auth:`, `gh auth login` guidance for `cli:gh`). If the user reconnects, retry the lane and
  continue. If they decline, treat as skipped for today with a colophon line; keep history.
- **Unattended run.** Never prompt. Skip the lane, set `needs_reauth = true`, add one colophon
  line ("Jira couldn't authenticate today — I'll ask you to reconnect next time you run this
  live"). At **step 0 of the next interactive run**, read all `needs_reauth = true` rows and offer
  to reconnect them up front, before the sweep.

## Anomaly check — "confirm this isn't an error"

Only for a **reliable** source: one with data on **≥3 of the last 4 working-day runs** (from the
seen ratio). On a `live-empty` for such a source:

- **Interactive:** ask once — *"I couldn't find any new {tool} activity today. Confirm this isn't
  an error (e.g. a broken connection or a moved vault)."*
  - *Confirmed correct* → colophon line "no new {tool} today (confirmed)"; keep counting empties.
  - *Called an error* → re-run `detect()`. If `auth-expired`, run recovery. If `not-present` (path
    gone), run the tool-switch flow. Otherwise help debug rather than shipping the empty lane.
- **Unattended, or a sporadic source (seen < 3 of last 4):** no prompt — record the empty and add
  one colophon line. A `needs_reauth`/anomaly worth surfacing waits for the next interactive run.

## Tool-switching — keeping the living docs current

When the user says they changed tools (e.g. "I switched my notes to Obsidian", "I don't use Jira
anymore", "add my Notion"), update `PROFILE § Sources` immediately and reconcile health, so the
change persists and is never re-asked:

1. **Edit `PROFILE § Sources`**: set the category's `tool`, `on`, and `access` (re-detect a
   `local:` path now — e.g. read `obsidian.json` for the vault). Turn off the tool being replaced.
2. **Reconcile `MEMORY § Source health`**: retire the old source's row (or mark it off); seed a
   fresh row for the new one (`status = live` once detected, empty seen ratio). A fresh source is
   **not** "reliable" yet, so it will not trigger an anomaly prompt until it builds a streak.
3. **Confirm in one line** and apply from the next run (PROFILE is re-read every run). If mentioned
   mid-run, apply immediately and use the new source this run when possible.
4. For an `unsupported-here` tool, record it with the pointer to the adapter contract above and
   say plainly it is not reachable in this environment yet.

The user can also hand-edit `PROFILE § Sources` directly; it is human-editable and never written
silently by a normal run.
