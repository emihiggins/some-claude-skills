---
name: create-skill
description: "Unified authoring lifecycle for new skills, workflows, and agents within a Claude Code plugin. Handles atomic skills, multi-phase workflow orchestrators, standalone agent files, and targeted enhancements to existing ones — with scaffolding, taxonomy checks, and structural validation. Use when the user asks to 'create a skill', 'new skill', 'add an agent', 'create a workflow', 'improve/enhance this skill', or is otherwise authoring plugin surface area. NOT for using an existing skill, NOT for editing a skill's core logic once it exists (edit the file directly), and NOT for publishing or releasing skills."
argument-hint: "<mode> [name]"
---

# Create Skill

Unified lifecycle for authoring new skills, workflows, and agents. One entry point, multiple modes.

## Modes

| Mode | Trigger | What It Creates |
|------|---------|----------------|
| `create` | "create a skill", "new skill" | Atomic skill (`skills/{name}/SKILL.md`) |
| `create-workflow` | "create a workflow", "new workflow" | Workflow skill + co-located agents + scripts |
| `create-agent` | "create an agent", "add agent to workflow" | Agent .md file (shared or co-located) |
| `enhance` | "improve skill", "fix skill" | Targeted improvement to existing skill/agent |

If mode is ambiguous, ask:
```
Use AskUserQuestion:
  Question: "What would you like to create?"
  Header: "Mode"
  Options:
    1. "Atomic skill" - A focused skill that does one thing end-to-end
    2. "Workflow" - A multi-phase orchestrator with agents and scripts
    3. "Agent" - An agent for an existing or new workflow
    4. "Enhance existing" - Improve an existing skill or agent
```

---

## Mode: Create (Atomic Skill)

### Step 1: Gather Intent

```
Use AskUserQuestion:
  Question: "What should this skill do? (one sentence)"
  Header: "Purpose"
```

Then ask for name. Apply naming taxonomy:
- Starts with `ref-` → reference skill (knowledge-only, no actions)
- Starts with `tool-` → external tool reference
- No prefix → atomic action skill

### Step 2: Discover Existing Skills

Run the scan script:
```bash
"${CLAUDE_SKILL_DIR}/scripts/scan-skills.sh" "${CLAUDE_PLUGIN_ROOT}"
```

Check for overlap with existing skills. If similar skill exists, ask:
```
A similar skill already exists: {name} — "{description}"

1. Create anyway (different purpose)
2. Enhance the existing one instead
3. Cancel
```

### Step 3: Scaffold

Read the skill template:
```
Read: ${CLAUDE_SKILL_DIR}/references/skill-template.md
```

Create `skills/{name}/SKILL.md` using the template, filling in:
- Frontmatter (description, argument-hint)
- Purpose and scope
- Steps (placeholder — user fills in)
- Output contract (structured return format)

### Step 4: Validate

Run structural validation:
```bash
"${CLAUDE_SKILL_DIR}/scripts/validate-skill.sh" "${CLAUDE_PLUGIN_ROOT}/skills/{name}"
```

Report any issues. Offer to fix them.

### Step 5: Present Result

```
✅ Skill created: skills/{name}/SKILL.md

Next: Open the file and fill in the implementation steps.
The template includes placeholders for each section.
```

---

## Mode: Create-Workflow (Multi-Phase Orchestrator)

### Step 1: Gather Intent

Ask: What's the end-to-end process? How many phases? Is it composed (uses existing skills) or self-contained (needs custom agents)?

### Step 2: Discover Reusable Components

Scan existing skills and agents:
```bash
"${CLAUDE_SKILL_DIR}/scripts/scan-skills.sh" "${CLAUDE_PLUGIN_ROOT}"
```

Present reusable pieces: "These existing components might be useful: {list}".

### Step 3: Phase Design

For each phase, determine:

| Question | Options |
|----------|---------|
| **Execution model** | Inline (needs user interaction) vs Subagent (autonomous, context isolation) |
| **If subagent — model** | Opus (judgment-heavy: code, review, architecture) vs Sonnet (research, search, collection) |
| **If subagent — tools** | What tools does this agent need? MCP access? |
| **User gate after?** | Yes (checkpoint) or No (silent transition) |
| **Script needed?** | Deterministic work → shell script |

Present the phase design as a table:
```
| Phase | Name | Type | Model | Gate? | Notes |
|-------|------|------|-------|-------|-------|
| 0 | Preflight | Script | — | No | Validation |
| 1 | Gather | Agent | Sonnet | No | MCP access |
| 2 | Plan | Agent | Sonnet | Yes | User approves |
| 3 | Implement | Agent | Opus | No | Fresh context |
| 4 | Review | Agent | Opus | Yes | User decides |
```

Ask user to approve or adjust the phase design.

### Step 4: Scaffold Agents

For each subagent phase, read the agent template:
```
Read: ${CLAUDE_SKILL_DIR}/references/agent-template.md
```

Create `skills/workflow-{name}/agents/{agent-name}.md` with:
- Frontmatter (name, description, tools, model, effortLevel, maxTurns, permissionMode)
- Input contract (what the orchestrator passes)
- Output contract (structured return format)
- Instructions (focused on that phase's responsibility)
- Constraints (what the agent must/must not do)

### Step 5: Scaffold Scripts

For deterministic operations identified in phase design:
- Create `skills/workflow-{name}/scripts/{script-name}.sh`
- Each script: JSON output on stdout, errors to stderr

### Step 6: Scaffold Orchestrator

Read the workflow template:
```
Read: ${CLAUDE_SKILL_DIR}/references/workflow-template.md
```

Create `skills/workflow-{name}/SKILL.md` wiring phases together:
- Phase transitions with visual markers
- State.json management
- Output contract parsing for each agent
- User gates at checkpoint phases
- Loop-back routing (if applicable)
- Error handling

### Step 7: Validate

```bash
"${CLAUDE_SKILL_DIR}/scripts/validate-skill.sh" "${CLAUDE_PLUGIN_ROOT}/skills/workflow-{name}"
```

Checks: all phases have output, no orphan agents, naming conventions, frontmatter complete.

### Step 8: Present Result

```
✅ Workflow created: skills/workflow-{name}/

Files:
  SKILL.md                    — Orchestrator ({N} phases)
  agents/{agent-1}.md         — {description}
  agents/{agent-2}.md         — {description}
  scripts/{script}.sh         — {description}

Next: Review each file and fill in implementation details.
```

---

## Mode: Create-Agent

### Step 1: Determine Location

```
Use AskUserQuestion:
  Question: "Where should this agent live?"
  Header: "Location"
  Options:
    1. "Shared (agents/)" - Reusable across workflows
    2. "Co-located with workflow" - Specific to one workflow
```

If co-located, ask which workflow:
```
Use AskUserQuestion:
  Question: "Which workflow?"
  Header: "Workflow"
  Options: {dynamically list workflow-* skills}
```

### Step 2: Define Contract

Ask:
- What does this agent do? (1 sentence)
- What input does it receive from the orchestrator?
- What output does it return?

### Step 3: Choose Model

```
Use AskUserQuestion:
  Question: "What type of work does this agent do?"
  Header: "Model"
  Options:
    1. "Judgment-heavy (code, review, architecture)" - Uses Opus
    2. "Research/search/collection" - Uses Sonnet (cheaper, faster)
```

### Step 4: Define Tools

```
Use AskUserQuestion:
  Question: "What tools does this agent need?"
  Header: "Tools"
  Options:
    1. "Read-only (Read, Glob, Grep)" - Research and analysis
    2. "Read + Write (Read, Glob, Grep, Write, Edit)" - Creates/modifies files
    3. "Full dev (Read, Glob, Grep, Bash, Write, Edit)" - Builds, tests, git
    4. "Full + MCP" - External integrations (Jira, Figma, etc.)
```

### Step 5: Scaffold

Read the agent template:
```
Read: ${CLAUDE_SKILL_DIR}/references/agent-template.md
```

Create agent .md file with complete frontmatter + instructions + contracts.

### Step 6: Wire Up

If co-located with a workflow, update the workflow's SKILL.md to reference the new agent in its agent table and delegation prompts.

---

## Mode: Enhance

### Step 1: Select Target

```
Use AskUserQuestion:
  Question: "What would you like to enhance?"
  Header: "Target"
  Options: {dynamically list skills and agents}
```

### Step 2: Score Against Quality Checklist

Read the quality checklist:
```
Read: ${CLAUDE_SKILL_DIR}/references/quality-checklist.md
```

Score the target against each criterion. Present results:
```
Quality Score: {N}/10

✅ Has description
✅ Has output contract
❌ Missing error handling
❌ No validation of inputs
⚠️ Steps could be more specific
```

### Step 3: Propose Fixes

For each failed criterion, propose a specific fix. Present as a list:
```
Proposed improvements:
1. Add input validation for {parameter}
2. Add error handling for {failure mode}
3. Specify output contract format

Apply these improvements?
1. Yes, all of them
2. Let me pick which ones
3. Cancel
```

### Step 4: Apply

Apply selected fixes using Edit tool. Show diff of changes.
