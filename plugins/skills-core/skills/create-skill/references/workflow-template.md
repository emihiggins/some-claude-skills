# Workflow Template — Multi-Phase Orchestrator

Use this template when scaffolding a new workflow via `create-skill create-workflow`.

```markdown
---
description: {One-line description of the end-to-end workflow}
argument-hint: {Expected arguments}
---

# {Workflow Name}

{2-3 sentence description of the workflow's purpose and what it orchestrates.}

## Core Principles

1. {Key principle — e.g., "Loop, not pipeline" or "Pipeline with gates"}
2. {Key principle — e.g., "Silent transitions between automated phases"}
3. {Key principle — e.g., "Scripts for deterministic work, agents for judgment"}

## Available Subagents

| Agent | subagent_type | Model | Tools | MCP |
|-------|---------------|-------|-------|-----|
| {Agent 1} | `{plugin-name}:{agent-name}` | {Opus/Sonnet} | {tools} | {YES/NO} |
| {Agent 2} | `{plugin-name}:{agent-name}` | {Opus/Sonnet} | {tools} | {YES/NO} |

## Visual Markers

| Phase | Marker |
|-------|--------|
| {Phase 1} | `{emoji} {PHASE NAME}` |
| {Phase 2} | `{emoji} {PHASE NAME}` |

---

## Phase 0: Preflight

{Run validation scripts. Parse output. Handle edge cases.}

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/{script}.sh" "{args}"
```

---

## Phase {N}: {Phase Name}

{emoji} {PHASE NAME} - {description}...

**BEFORE delegating:** Update state.json phase to `"{phase-name}"`.

**Delegate via Agent:**

```
Agent({
  subagent_type: "{plugin-name}:{agent-name}",
  description: "{what the agent does}",
  prompt: <<PROMPT
{Brief instruction for the agent.}

\`\`\`json
{
  "phase": "{PHASE_NAME}",
  "context": {
    "session_dir": "{session-dir}",
    "working_dir": "{project root}",
    "plugin_root": "{plugin-root}"
  },
  "output": "{session-dir}/{artifact}.md"
}
\`\`\`

## Instructions
- {Specific instruction 1}
- {Specific instruction 2}
PROMPT
})
```

**Parse output contract:**
- `VERDICT: {value}` → {routing decision}
- `VERDICT: {value}` → {routing decision}

{If checkpoint — update state.json phase, present options to user.}

---

## Error Handling

### Agent Completion Validation

After EVERY agent returns:
1. Check for silent failure (0 tokens / instant completion)
2. Check expected output exists
3. If failed: offer Retry or Abort

### {Workflow-specific error handling}

{How this workflow handles its unique failure modes.}

---

## State Management

State file: `.workflow-sessions/session-{id}/state.json`

After EVERY phase transition, update state.json via Write tool.

## Output Contract

```
STATUS: {complete|incomplete|failed}
{CUSTOM_FIELDS}: {workflow-specific output fields}
```
```

## Template Usage Notes

**For create-skill to fill in:**
1. One `## Phase {N}` section per phase from the phase design
2. Phases with agents get the full Agent() delegation block
3. Phases with scripts get the Bash invocation
4. User gates get AskUserQuestion prompts
5. Output contract parsing after every agent phase

**Phase types:**
- **Script phase:** Run a shell script, parse JSON output
- **Agent phase:** Delegate via Agent(), parse output contract
- **Inline phase:** Orchestrator handles directly (user interaction, simple decisions)
- **Skill phase:** Invoke another skill via Skill()

**Gate types:**
- **Checkpoint:** Stopping allowed, user can review and approve
- **Silent transition:** No stopping, continue immediately to next phase

**Loop support:** If the workflow can loop back (like build-feature), include:
- Loop counter in state.json
- Loop-back routing in decision phases
- Fresh Agent() context on each loop iteration

**Composed workflows (orchestrator-of-orchestrators):**
A workflow can invoke other `workflow-*` skills as child workflows. The contract:
- Child workflows return an output contract (STATUS, custom fields)
- Parent workflow parses the output and routes (continue, retry, skip, abort)
- User gates between child workflow invocations
- Each child runs independently with its own session state
- Example: `workflow-fullstack` invokes `workflow-build-feature` per repo with design context

When composing workflows:
1. Define the child workflow's output contract clearly
2. Parse it in the parent workflow after each invocation
3. Track completion in the parent's state.json (which child completed, which failed)
4. Handle partial completion (some children pass, some fail)
