---
name: brainstorm
description: "Collaborative design exploration for a feature before any implementation planning starts. Walks the user through goals, constraints, alternatives, and open questions to arrive at a shared shape for the work. Use when the user asks to 'brainstorm', 'explore approaches', 'talk through the design', or when a feature request is still ambiguous and needs shaping before planning. NOT for writing the plan itself, NOT for implementation, and NOT for triaging bugs with a known root cause."
argument-hint: "[feature description or requirements path]"
---

# Brainstorm

Collaborative design exploration. Turns vague ideas into concrete designs through structured dialogue before any implementation begins.

**Hard gate:** Do NOT write any implementation code, create files in the project, or take any implementation action. This is design exploration only.

## Input

- **feature description**: What the user wants to build (free text)
- **requirements path** (optional): Path to an existing `requirements.md` from a workflow session

## Process

### Step 1: Understand Context

**If inside a workflow session** (session directory exists with `requirements.md`):
- Read `requirements.md` for gathered context
- Note the ticket ID, project type, and any external context already captured

**If standalone** (no session):
- Ask the user to describe what they want to build
- Keep it conversational — don't interrogate

**In both cases:**
- Read `CLAUDE.md` if it exists (project conventions, tech stack)
- Briefly scan relevant codebase areas for existing patterns and similar features (5-10 files max)

### Step 2: Ask Clarifying Questions

Ask questions **one at a time**. Do not batch multiple questions.

**Use AskUserQuestion with multiple choice options when possible.** Open-ended is fine when choices aren't clear-cut.

**Focus areas:**
- Purpose: What problem does this solve for the user?
- Constraints: Performance, compatibility, design system, existing patterns to follow?
- Success criteria: How will we know it's done and working?
- User-facing behavior: What does the user see and interact with?
- Scope boundaries: What is explicitly NOT part of this feature?

**Stop asking when:**
- You have enough to propose 2-3 distinct approaches
- User signals they want to move forward ("let's go", "that's enough", etc.)
- You've asked 3-5 questions (don't over-interrogate)

### Step 3: Propose 2-3 Approaches

Present approaches conversationally:

```
Based on what we've discussed, I see a few ways to approach this:

**Approach A: [Name]** (Recommended)
[2-3 sentences describing the approach and why you recommend it]

**Approach B: [Name]**
[2-3 sentences with trade-offs vs Approach A]

**Approach C: [Name]** (if applicable)
[2-3 sentences — only include if genuinely different, not padding]
```

Use AskUserQuestion to let the user pick:
```
Which approach fits best?
1. Approach A (Recommended)
2. Approach B
3. Hybrid / different idea
```

### Step 4: Present Design Incrementally

Once an approach is chosen, present the design **one section at a time**.

**Scale each section to its complexity:**
- Straightforward aspect → a few sentences
- Nuanced or ambiguous aspect → up to 200-300 words

**Sections to cover** (skip any that don't apply):

1. **Architecture** — High-level structure. What components, how they connect.
2. **Components** — What gets created or modified. Key responsibilities.
3. **Data Flow** — How data moves through the system. State management.
4. **Error Handling** — What can go wrong, how to handle it.
5. **Edge Cases** — Boundary conditions, empty states, loading states.

**After each section**, ask:
```
Does this look right, or should we adjust anything before moving on?
```

Be ready to revise. If the user pushes back, update the section and re-present.

### Step 5: YAGNI Check

Before finalizing, explicitly ask:

```
Before I write this up — is there anything in this design we don't actually need for v1?
Sometimes features creep in during brainstorming. Now's the time to cut.
```

Remove anything the user flags. Simpler is better.

### Step 6: Write design.md

Write the final design to the session directory (if in a workflow) or the current directory (if standalone).

**Structure:**

```markdown
# Design: [Feature Name]

## Problem
[1-2 sentences: what problem this solves]

## Approach
[The chosen approach with brief rationale]

### Why not [Alternative]?
[1 sentence per rejected alternative]

## Components
[What gets built/modified]

## Data Flow
[How data moves through the system]

## Error Handling
[What can go wrong and how to handle it]

## Edge Cases
[Boundary conditions and special states]

## Decisions Made
| Decision | Choice | Rationale |
|----------|--------|-----------|
| [question] | [answer] | [why] |
```

### Step 7: Handoff

**If running inside build-feature workflow:**
```
Design saved to {session-dir}/design.md.
Continuing to planning phase...
```
Return control to the orchestrator. Do NOT start planning yourself.

**If running standalone:**
```
Design saved to ./design.md.
You can reference this when starting the build-feature workflow — the planner will use it as input.
```

## Anti-Patterns

- **Dumping 5 questions at once** — one question at a time, always
- **Wall-of-text design** — present incrementally, get feedback per section
- **Gold-plating** — YAGNI. Cut anything not needed for v1.
- **Skipping approaches** — always propose 2-3 options, even if you have a strong preference
- **Writing code** — this is design only. No implementation, no scaffolding, no "let me just set up the file structure"
- **Over-questioning** — 3-5 questions max. If you need more, you're going too deep for brainstorming.
