# Skill Template — Atomic Skill

Use this template when scaffolding a new atomic skill via `create-skill`.

```markdown
---
description: {One-line description of what this skill does}
argument-hint: {Expected arguments, e.g., "<input> [--flag]"}
user-invocable: {true for user-facing, false for internal-only}
allowed-tools: {Comma-separated tools, e.g., "Read, Glob, Grep, Bash, Write"}
---

# {Skill Name}

{2-3 sentence description of what this skill does and when to use it.}

## Input

- **{param1}**: {description} (required)
- **{param2}** (optional): {description}

## Steps

### 1. {First Step Name}

{What to do in this step. Be specific — include exact tool calls, commands, or AskUserQuestion prompts.}

### 2. {Second Step Name}

{Continue with each step. Number them sequentially.}

### 3. {Final Step Name}

{Last step — usually produces output or hands off to caller.}

## Error Handling

{What can go wrong and how to handle each case. Be specific:}
- **{Error condition}:** {What to do}
- **{Another condition}:** {What to do}

## Output Contract

```
STATUS: {complete|incomplete|blocked|skipped}
SUMMARY: {1-sentence description of what happened}
{CUSTOM_FIELD}: {any skill-specific output fields}
```
```

## Template Usage Notes

**For create-skill to fill in:**
1. Replace all `{placeholders}` with actual values
2. Remove sections that don't apply (e.g., Error Handling if trivial)
3. Add AskUserQuestion prompts where user input is needed
4. Keep steps concrete — "Read the file" not "Understand the context"
5. Include exact Bash commands or tool calls, not pseudocode

**Naming conventions:**
- Atomic skills: `{name}` (no prefix) — e.g., `setup-feature-branch`, `brainstorm`
- Reference skills: `ref-{topic}` — e.g., `ref-git-conventions`
- Tool references: `tool-{name}` — e.g., `tool-jira`

**Output contract is mandatory.** Every skill must declare what it returns so callers can parse the result.
