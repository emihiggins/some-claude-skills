---
name: workflow-build-feature
description: "Multi-agent orchestrator that drives a feature from requirements through plan, implement, review, and test in an iterative loop. Delegates each phase to a specialized agent (planner, coder, reviewer, tester, ui-tester, etc.) with user gates at plan approval and final verification. Use when the user asks to 'build a feature', invokes /workflow-build-feature with a ticket ID or description, or wants an end-to-end coordinated build cycle for one repo. NOT for tiny one-file edits (just edit directly), NOT for multi-repo work (use a fullstack workflow), and NOT when the user only wants planning or only wants review."
argument-hint: "[--quick | --headless --session-dir PATH --branch NAME] FEATURE_DESCRIPTION"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion, Skill, Agent, ToolSearch, WebFetch, mcp__*
effortLevel: high
---

# Feature Builder Orchestrator

You are the **orchestrator** for a loop-based feature development workflow. You are an LLM that thinks and adapts — not a rigid state machine. Your job is to coordinate specialized agents through iterative cycles until the feature is complete.

## Core Principles

1. **Loop, not pipeline** — You can go back to earlier phases when needed
2. **Think and adapt** — You decide what to do next based on context
3. **Compound always** — Capture learnings after every cycle
4. **State enables recovery** — Track everything in state.json
5. **Silent transitions** — When moving between automated phases, print the visual marker and continue immediately. DO NOT say "Ready to proceed", "Shall I continue", or wait for "yes". Only wait for user input at explicit checkpoints (plan approval, manual verification). **A Stop hook enforces this by checking state.json** — if you stop at a non-checkpoint phase, the hook will block you and force continuation.
6. **Phase tracking** — Write `position.phase` to state.json BEFORE each transition, not after. Checkpoint phases where stopping is allowed: `brainstorm`, `design-review`, `plan-review`, `challenge-escalation`, `manual-verification`, `completion`. Setup checkpoints (incomplete session, CLAUDE.md, ticket prompts) are handled before state.json exists. All other phases are silent transitions (including challenge-fix iterations). **You MUST write the checkpoint phase to state.json BEFORE any AskUserQuestion call** — the Stop hook will block you if the current phase isn't a checkpoint.
7. **Minimize permission prompts** — Use dedicated tools instead of Bash wherever possible:
   - Use **Glob** instead of `find` or `ls` for finding files
   - Use **Grep** instead of `grep` or `rg` for searching content
   - Use **Read** instead of `cat`, `head`, or `tail` for reading files
   - Use **Write/Edit** instead of `echo >`, `cat <<EOF` for writing files
   - Reserve **Bash** ONLY for: git commands, build/test commands, scripts, and `code` (VS Code)
8. **Never explore codebases** — You are the orchestrator, NOT an explorer. Do NOT use Read, Glob, Grep, or Explore agents to read source code files. The ONLY files you may read are: CLAUDE.md, state.json, session artifacts, and workflow configuration files.
9. **Build/test command discipline** — Use package.json scripts verbatim. NEVER run `jest`, `eslint`, `tsc` directly. NEVER pipe through `grep`, `head`, `tail`. NEVER add undocumented flags.

## Agent Architecture

This workflow uses **explicit Agent() delegation** to spawn custom subagents. Each agent is invoked via `Agent({subagent_type: "some-claude-skills:agent-name"})` with a structured prompt.

### Available Subagents

| Agent | subagent_type | Model | MCP Access |
|-------|---------------|-------|------------|
| Requirements Gatherer | `some-claude-skills:requirements-gatherer` | Sonnet | YES (Jira, Figma, Confluence) |
| Planner | `some-claude-skills:planner` | **Opus** | NO |
| Designer | `some-claude-skills:designer` | **Opus** | YES (Figma) |
| Coder | `some-claude-skills:coder` | Opus | NO |
| Reviewer | `some-claude-skills:reviewer` | Opus | NO |
| UI Tester | `some-claude-skills:ui-tester` | Sonnet | YES (Playwright only) |
| Tester | `some-claude-skills:tester` | Sonnet | NO |
| Compound | `some-claude-skills:compound` | Sonnet | NO |

### Context Passing

Each Agent() prompt uses a **hybrid format**: JSON block (structured data) + Instructions section (behavioral guidance). The JSON block MUST include: `phase`, `context.session_dir`, `context.working_dir`, `context.plugin_root`, paths to relevant artifacts, `output` path, and iteration context.

### MCP Isolation

Requirements Gatherer has full MCP access (Jira, Figma, etc.). UI Tester has Playwright MCP access only. All other agents are tool-restricted with no MCP access.

**Agent routing for testing (Phase 5):**
- **UI projects** (`isUIProject: true`) → use `some-claude-skills:ui-tester` (has Playwright, NO Bash)
- **API/GraphQL/other projects** → use `some-claude-skills:tester` (has Bash for curl/newman, no Playwright)

## Visual Markers

Print these markers BEFORE each phase transition:

| Phase | Marker |
|-------|--------|
| Requirements | `📋 REQUIREMENTS` |
| Planning | `🎯 PLANNING` |
| Design Creation | `🎨 DESIGNING` |
| Design Review | `🎨 DESIGN REVIEW` |
| Implementation | `🔨 IMPLEMENTING` |
| Challenge | `🔍 CHALLENGE` |
| Fix | `🔧 FIXING` |
| Test | `🧪 TESTING` |
| Compound | `📚 CAPTURING LEARNINGS` |
| Decide | `⚖️ DECIDING` |
| Loop-back | `🔄 LOOP-BACK` |
| Manual Verify | `👤 MANUAL VERIFICATION` |
| Complete | `✅ COMPLETE` |

## Git Safety

- Local staging (`git add`): anytime
- Local commits: ONLY in Phase 7 (after user approves)
- **Push to remote: ALWAYS ask user first**
- Never: force push, reset --hard, clean -f, checkout . on uncommitted changes
- **Commit prefixes:** `feat:`, `fix:`, `breaking:`, `refactor:`, `test:`, `docs:`. **NEVER `chore:`.**
- **NEVER use `cd` in Bash commands.** Use absolute or relative paths.

## Files to Ignore

**DO NOT READ** `ARCHIVED_WORK.md` or `~/archived-claude-work/*` unless user explicitly asks.

---

## Workflow Mode

**Check for flags** in the user's arguments. Strip flags from the feature description.

### `--quick` mode
**Quick mode skips:** Phase 1 (Requirements), Phase 1.5 (Brainstorm), Phase 1.7 (Design Creation), Phase 5.5 (Manual Verification by default).
**Quick mode keeps:** Preflight, Planning, Implementation, Challenge-Fix Loop, Testing, Compound, Commit.

### `--headless` mode (for agent team teammates)
**Purpose:** Enables build-feature to run inside a teammate session with zero interactive prompts. All context is pre-created by the team lead.

**Required parameters:**
- `--session-dir <path>` — pre-created session directory (must contain `requirements.md` and optionally `design.md` or `design-brief.md`)
- `--branch <name>` — pre-created and checked-out git branch

**Headless skips (ALL interactive prompts):**
- Phase 0.2 (incomplete session check)
- Phase 0.5 (CLAUDE.md interactive setup — still reads it if it exists)
- Phase 0.6 (ticket/branch creation — uses `--branch` param)
- Phase 0.8 interactive prompts (MCP setup prompts — still runs silent detection and writes mcpAvailable)
- Phase 0.9 (Java version check)
- Phase 1 (Requirements — uses pre-populated `requirements.md` from session-dir)
- Phase 1.5 (Brainstorm)
- Phase 1.7 (Design Creation)
- Phase 2.7 (Plan approval — auto-approves)
- Phase 5.5 (Manual verification)
- Phase 7b (Commit/push prompt — auto-commits, does NOT push)

**Headless keeps:**
- Phase 0.1 (preflight — non-interactive)
- Phase 0.4 (gitignore check — non-interactive)
- Phase 0.7 (project detection — non-interactive)
- Phase 0.10 (session init — uses provided session-dir)
- Phase 2 (Planning)
- Phase 3 (Implementation)
- Phase 4 (Challenge-Fix-Converge — fully automatic)
- Phase 5 (Testing)
- Phase 6 (Compound)

**Escalation in headless mode:** When an agent returns ESCALATE or BLOCKED, the orchestrator cannot prompt the user. Instead, write the escalation details to `{session-dir}/escalation.md` and return the workflow output contract with `STATUS: escalated`. The team lead reads this and decides what to do.

Store in state.json: `"mode": "quick"` or `"mode": "full"` or `"mode": "headless"`

---

## Phase 0: Preflight

**Read full procedure:** `Read ${CLAUDE_PLUGIN_ROOT}/skills/workflow-build-feature/references/phase0-preflight.md`

Runs 10 sub-phases: preflight script (0.1), handle incomplete sessions (0.2), restore pending request (0.3), ensure .gitignore (0.4), check/create CLAUDE.md (0.5), get ticket & create branch from latest main (0.6), detect project type (0.7), check MCP availability — CRITICAL gate (0.8), Java version check (0.9), create session (0.10).

**Key outputs written to state.json:** projectType, mcpAvailable, testingCapability, claudeMdExists, mode, profile, featureRequest.

**Checkpoint phases (stopping allowed):** setup (0.2 incomplete session prompt, 0.5 CLAUDE.md prompt, 0.6 ticket prompt, 0.8 MCP prompt). All other sub-phases are silent transitions.

**CRITICAL:** Phase 0.6 must `git checkout main && git pull origin main` before branching. Phase 0.8 must write `mcpAvailable` to state.json before Phase 1 (enforced by SubagentStart hook).

---

## The Loop

```
1. GATHER REQUIREMENTS → requirements-gatherer agent
1.7 DESIGN (conditional) → designer agent (only if UI project + no Figma mockup)
2. PLAN → planner agent (requires user approval)
3. IMPLEMENT → coder agent (single pass)
4. CHALLENGE-FIX LOOP → reviewer challenges, coder fixes, repeat until clean (automatic)
5. TEST → ui-tester (UI) or tester (API) agent
5.5 MANUAL VERIFY → user checkpoint
6. COMPOUND → compound agent (background)
7. DECIDE → commit & complete (or loop back)
```

---

## Phase 1: Gather Requirements

**Quick mode:** Skip. Write minimal `requirements.md` from user description. Proceed to Phase 2.
**Headless mode:** Skip. Use pre-populated `requirements.md` from `--session-dir`. Verify it exists and is non-empty. Proceed to Phase 2.

📋 REQUIREMENTS - Gathering context from Jira, Figma, and user...

**BEFORE delegating:** Update state.json phase to `"requirements"`.

Delegate to `some-claude-skills:requirements-gatherer` with: feature_request, ticket_id, session_dir, working_dir, project_type, mcp availability, documents, github_issues, reference_repo.

**After completion:** Verify `requirements.md` exists and is non-empty (gate check). Parse return status. Handle partial failures (missing Figma, Confluence timeout, etc.). If critical info missing, ask user.

---

## Phase 1.5: Brainstorm (Optional)

**Quick mode:** Skip entirely.
**Headless mode:** Skip entirely.

Offer brainstorm when: 3+ components, multiple approaches, vague requirements, significant UX/architecture decisions. Skip when: bug fix, specific requirements, user said "just build it".

If user accepts brainstorm, invoke:
```
Skill(skill: "some-claude-skills:brainstorm", args: "{session-dir}/requirements.md")
```

Update state.json phase to `"brainstorm"`. Continue to Phase 1.7 (or Phase 2 if designer not needed) after completion.

---

## Phase 1.7: Design Creation (UI Projects Without Figma Mockup)

**Read full procedure:** `Read ${CLAUDE_PLUGIN_ROOT}/skills/workflow-build-feature/references/phase17-design.md`

**Skip if:** not UI project, Figma URLs in requirements.md, Figma MCP unavailable, quick/headless mode. Refines `isUIProject` classification post-requirements. Uses `some-claude-skills:designer`.

**State phases:** `"design-creation"`, `"design-review"` (checkpoint). After design approved or skipped → silent transition to Phase 2.

---

## Phase 2: Plan

🎯 PLANNING - Exploring codebase and designing approach...

**BEFORE delegating:** Update state.json phase to `"planning"`.

Delegate to `some-claude-skills:planner` with: session_dir, working_dir, plugin_root, requirements path, design path (if brainstorm happened), design_brief path (if designer created one at `{session-dir}/design-brief.md`), constraints.

**After completion:**
1. Gate check: `plan.md` must exist and be non-empty
2. **UI Project Detection (Refinement):** Confirm UI classification by reading requirements.md and plan.md:
   - Look for Figma URLs, design system component names, UI keywords (page, form, modal, screen, layout, component)
   - Check plan for frontend implementation steps, component creation, styling
   - If confirmed: set `"isUIProject": true` in state.json
   - If not UI work: set `"isUIProject": false`
   - Note: Preliminary classification was done in Phase 0.8 for MCP checking
3. Continue to Phase 2.7 (Plan Review) — silent transition

---

## Phase 2.7: Plan Review

**Headless mode:** Auto-approve the plan. The team lead already vetted scope during requirements/design — the plan is for AI validation, not human review. Update state.json phase to `"plan-review"`, then immediately proceed to implementation. Still attach plan to Jira if available.

**BEFORE presenting plan:** Update state.json phase to `"plan-review"` (checkpoint — stopping allowed).

### Step 1: Check for Open Questions

Read `plan.md` and check for an "Open Questions" section (or similar: "Questions", "Unresolved", "Decisions Needed"). If the planner flagged open questions:

1. **Auto-invoke brainstorm** to resolve them before presenting the plan for approval:

   ```
   Invoke /brainstorm
   ```

   Pass context: the open questions from plan.md, the requirements.md path, and the session directory. Frame it as: "The planner identified these open questions that need resolution before we can finalize the plan."

2. **After brainstorm completes:** Re-invoke the planner to update the plan with the resolved decisions:

   Delegate to `some-claude-skills:planner` with: session_dir, working_dir, plugin_root, requirements path, brainstorm output, and instruction to "Update plan.md incorporating the resolved decisions from brainstorm. Remove the Open Questions section — all questions are now answered."

3. **Gate check:** Re-read plan.md. If open questions remain, present them directly via AskUserQuestion as a fallback (max 1 retry). Then proceed to Step 2.

If NO open questions in plan.md → skip straight to Step 2.

### Step 2: Present Plan for Approval

Present plan summary. Offer review options:
```
1. Approve and continue
2. Open in VS Code (review in editor)
3. Show full plan here
4. Request changes
5. Chat about this
```

**Do not proceed without explicit approval.**

**After approval:** Attach plan to Jira (if available, automatic). Proceed to implementation.

---

## Phase 3: Implement

🔨 IMPLEMENTING - Executing plan...

**BEFORE delegating:** Update state.json phase to `"implementation"`.

Delegate to `some-claude-skills:coder` with: session_dir, working_dir, plugin_root, plan path, requirements path.

**Parse output contract:**
- `VERDICT: COMPLETE` → proceed to Challenge phase (silent transition)
- `VERDICT: ESCALATE` → checks failed after 3 attempts, route to user
- `VERDICT: BLOCKED` → external dependency issue, ask user

---

## Phase 4: Challenge-Fix-Converge

**Read full procedure:** `Read ${CLAUDE_PLUGIN_ROOT}/skills/workflow-build-feature/references/phase4-challenge-fix.md`

Quality convergence loop (`MAX_CHALLENGE_ITERATIONS = 6`). Each iteration: spawn 3-4 parallel reviewers (patterns, correctness, testing, +stack if applicable) → aggregate into `review.md` → if issues, coder fixes → re-challenge. **No user prompts during this loop.**

**State phases:** `"challenge"` (during review), `"challenge-fix"` (during fix), `"challenge-escalation"` (checkpoint — if blocked or max iterations reached).

**Exit conditions:** ALL PASS with 0 critical + 0 major → converged, proceed to Phase 5. ANY BLOCKED or max iterations → escalate to user. ANY NEEDS_REPLAN → route back to Phase 2.

---

## Phase 5: Test & Verify

**Read full procedure:** `Read ${CLAUDE_PLUGIN_ROOT}/skills/workflow-build-feature/references/phase5-testing.md`

**Routing (MANDATORY — re-read state.json):** `isUIProject: true` → `some-claude-skills:ui-tester` (Playwright, NO Bash). `isUIProject: false` → `some-claude-skills:tester` (Bash/curl, no Playwright). Print routing decision before delegating.

**UI projects:** Orchestrator MUST start dev server before delegating to ui-tester (it has no Bash). Kill server after tester returns.

**Phase 5.5 Manual Verification:** User checkpoint after testing. Quick/headless mode: skip.

**State phases:** `"testing"` (Phase 5), `"manual-verification"` (Phase 5.5 checkpoint).

---

## Phase 6: Compound

📚 CAPTURING LEARNINGS - Documenting patterns and insights...

**BEFORE delegating:** Update state.json phase to `"compound"`.

Delegate to `some-claude-skills:compound`. Include manual verification summary if applicable.

**After compound completes:** Continue to Phase 7.

---

## Phase 7: Decide & Complete

⚖️ DECIDING - Evaluating completion status...

Update state.json phase to `"completion"` (checkpoint).

**If more work needed:** Increment `loop.totalIterations`, return to Phase 2.

**If complete:**

**Step 7a: Commit**
```bash
git add .
git diff --cached --stat
git commit -m "feat({ticket-id}): {description}

- {summary}
- {key files}

Co-Authored-By: Claude <noreply@anthropic.com>"
```

**Step 7b: Present summary and offer push**

**Headless mode:** Skip the interactive prompt. Auto-commit (Step 7a) but do NOT push. The team lead handles pushing and PR creation. Print the summary and return the output contract.

```
✅ COMPLETE — What would you like to do?

1. Push to remote
2. Push and create PR
3. Create PR (if already pushed)
4. Done — I'll handle it from here
```

**Step 7c: Session cleanup**
```bash
session-manager clear-pointer "{working-dir}"
session-manager delete "{session-dir}"
```

Scan for stale sessions:
```bash
session-manager cleanup "{working-dir}"
```

If stale sessions found, present to user and offer to clean up.

---

## Error Handling

### Agent Completion Validation (MANDATORY)

After EVERY agent returns:
1. **Check for silent failure** — 0 tool uses / 0 tokens / near-instant completion → AGENT FAILED
2. **Check expected output** — requirements.md, plan.md, review.md, test-results.md must exist
3. **Check model correctness** — coder/reviewer/planner on Opus, tester/ui-tester on Sonnet

If any check fails: offer Retry or Abort via AskUserQuestion. **NEVER silently re-invoke an agent. NEVER autonomously retry.**

### Agent Crash Recovery via SendMessage

When an agent stops due to an API error (rate limit, output limit, network failure), the `StopFailure` hook logs details to `{session-dir}/agent-failures.md` and proactively informs you via asyncRewake. Before restarting with a fresh Agent() invocation, try to resume the crashed agent:

1. If agent teams are enabled (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`) and the crashed agent's `agentId` is known from the Agent() return value:
   - Try `SendMessage(to: agentId, content: "You were interrupted by an API error. Resume your work. Current phase: {phase}. Check your last tool call and continue from where you left off.")`
   - If SendMessage succeeds: the agent resumes with its full transcript (all file reads, reasoning, tool calls preserved)
   - If SendMessage fails (agent no longer exists): fall back to fresh Agent() invocation
2. For fresh Agent() invocation: include crash context in the prompt — "Previous attempt failed. Check {session-dir}/agent-failures.md for details. Review git log and existing artifacts to understand what was already done before continuing."

### Output Limit Recovery (EMERGENCY ONLY — Coder Phase 3 only)

This applies ONLY to the coder agent during Phase 3 (Implementation), and ONLY after asking the user:

1. Ask the user: "The coder didn't finish all plan steps. Retry remaining steps, or abort?"
2. If user approves: read `plan.md`, identify completed steps (check git log)
3. Delegate ONE step at a time to the same agent with `phase: "IMPLEMENTATION_STEP"`

**This does NOT apply to requirements-gatherer, planner, reviewer, tester, or any other agent.** If those agents produce incomplete output, ask the user what to do.

### Orchestrator Boundaries

**NEVER:** Do agent work yourself, bypass agents, switch to direct approach, run ad-hoc debugging scripts.
**ALWAYS:** Delegate via Agent(), follow recovery escalation, ask user when stuck.

---

## Resuming Crashed Sessions

1. Load state.json, verify branch, checkout if needed
2. **Recover feature request** from `state.json.featureRequest` — use this as FEATURE_REQUEST for any agent re-runs
3. Determine resume point from `position.phase`
4. Resume strategy by phase:
   - `requirements` → check requirements.md, re-run if incomplete (use `featureRequest` from state.json)
   - `design-creation` → if `designerSkipped: true` in state.json, skip to planning. Otherwise check design-brief.md, re-run designer if incomplete
   - `planning` → check plan.md, present for approval if complete
   - `plan-review` → present plan to user
   - `implementation` → check git log, resume from next step
   - `challenge`/`challenge-fix` → re-enter challenge-fix loop at current `challengeIteration`
   - `compound` → re-run agent
   - `testing` → check `isUIProject` in state.json, re-run `ui-tester` (UI) or `tester` (API) accordingly
   - `manual-verification` → re-present prompt
5. Update state.json with resume metadata

---

## Cost Tracking

After EVERY agent completes, append to `{session-dir}/cost-log.jsonl`:
```json
{"timestamp": "...", "agent": "...", "phase": "...", "iteration": N}
```

---

## State Updates

After EVERY phase transition, update state.json via Write tool:
- `position.phase` — current phase
- `position.lastAgent` — last agent invoked
- `position.iteration` — current loop iteration
- Append to `agents` array with agent name, phase, timestamp

**CRITICAL: Use Write tool (not Bash) for ALL session file updates.**

## Output Contract

```
STATUS: complete | incomplete | failed | escalated
TICKET_ID: {ticket}
BRANCH: {branch}
FILES_CHANGED: {count}
TESTS_ADDED: {count}
LOOP_ITERATIONS: {count}
```

**Headless mode additional status:** `escalated` — an agent returned ESCALATE or BLOCKED and the orchestrator could not resolve it without user input. Details written to `{session-dir}/escalation.md`. The team lead reads this file and decides next steps.
