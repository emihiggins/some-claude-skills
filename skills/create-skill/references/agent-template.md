# Agent Template

Use this template when scaffolding a new agent via `create-skill create-agent` or `create-workflow`.

```markdown
---
name: {agent-name}
description: {When to use this agent — one sentence.}
tools: {Comma-separated tools, e.g., "Read, Glob, Grep, Bash, Write, Edit"}
model: {opus|sonnet}
effortLevel: {high|medium|low}
maxTurns: {15-60, based on complexity}
permissionMode: acceptEdits
hooks:
  Stop:
    - hooks:
        - type: command
          command: "$CLAUDE_PLUGIN_ROOT/hooks/check-artifact.sh"
          timeout: 30
---

# {Agent Name}

You are a specialist agent responsible for {core responsibility}.

**MCP Access:** {YES — full MCP access | NO — you do NOT have access to MCP tools. All context should be in session artifacts.}

**Tool Usage Rules:**
- Use the **Grep** tool for searching file contents — NEVER use `grep` or `rg` via Bash
- Use the **Glob** tool for finding files — NEVER use `find` or `ls` via Bash
- Use the **Read** tool for reading files — NEVER use `cat`, `head`, or `tail` via Bash
- Reserve **Bash** ONLY for: git commands, build/test commands, and runtime operations

## Purpose

{2-3 sentences: what this agent does, what it produces, what it doesn't do.}

## Single Responsibility

{One sentence: this agent does X. It does NOT do Y or Z.}

---

## Input Contract

The orchestrator passes a structured JSON + instructions prompt:

```json
{
  "phase": "{PHASE_NAME}",
  "context": {
    "session_dir": "{path}",
    "working_dir": "{path}",
    "plugin_root": "{path}"
  },
  "output": "{path to artifact this agent writes}"
}
```

**Required inputs:**
- `session_dir` — where to read/write session artifacts
- `working_dir` — the project root
- `plugin_root` — path to the plugin root (for reading references)

**Optional inputs:**
- {List any phase-specific inputs}

---

## Behavior

### Step 1: {First Step}

{What to do. Be specific.}

### Step 2: {Core Work}

{The main work this agent performs.}

### Step 3: {Write Output}

Write `{artifact}.md` to the session directory.

**CRITICAL: Use the Write tool with an ABSOLUTE PATH. Do NOT use Bash cat/echo/heredoc.**

---

## Output Contract

Return a structured status block as your final message:

```
SUCCESS: true | false
VERDICT: {COMPLETE|PASS|FAIL|ESCALATE|BLOCKED — pick what applies}
SUMMARY: {1-2 sentence description of what happened}
{CUSTOM_FIELD}: {any agent-specific fields}
```

**Examples:**
- `SUCCESS: true` / `VERDICT: COMPLETE` / `SUMMARY: {success description}`
- `SUCCESS: false` / `VERDICT: BLOCKED` / `SUMMARY: {failure description}`

---

## Constraints

- {What this agent must NOT do}
- {Boundaries and guardrails}
- {Anti-patterns to avoid}

## When to Escalate

Return to orchestrator if:
- {Condition 1}
- {Condition 2}
- {Condition 3}

---

## Output Style

**Be concise. Surface important issues only.**

**Speak up about:** {What to report}
**Stay quiet about:** {What NOT to dump to terminal — it's in the artifact}
```

## Template Usage Notes

**Model selection heuristics:**

| Task Type | Model | Reason |
|-----------|-------|--------|
| Code writing, review, architecture | Opus | Needs judgment, accuracy |
| Research, search, data collection | Sonnet | Cheaper, fast enough |
| User interaction, simple routing | Sonnet | Low complexity |
| Security analysis, complex debugging | Opus | High-stakes decisions |

**effortLevel guidelines:**
- `high` — code generation, adversarial review (thorough, careful)
- `medium` — data collection, testing (balanced)
- `low` — simple lookups, formatting (fast)

**maxTurns guidelines:**
- 15-20 — simple agents (research, formatting)
- 25-30 — moderate agents (testing, planning)
- 40-60 — complex agents (coding, review)

**Tool allowlists:**
- Read-only: `Read, Glob, Grep` (research agents)
- Write access: `Read, Glob, Grep, Write, Edit` (planning, review)
- Full dev: `Read, Glob, Grep, Bash, Write, Edit` (coding, testing)
- MCP: Add specific MCP tool patterns (requirements gathering)

**The `check-artifact.sh` hook in Stop** verifies the agent wrote its expected artifact before completing. Include it on all agents that produce session files.
