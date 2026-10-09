# Phase 4: Challenge-Fix-Converge — Full Procedure

> **Read by orchestrator on-demand** when entering Phase 4. Not loaded with SKILL.md.

This is the quality convergence loop. Multiple parallel reviewers challenge the implementation from different angles, the coder fixes what's found, and reviewers re-challenge — repeating automatically until the code is clean or max iterations are reached. **No user prompts during this loop.**

```
MAX_CHALLENGE_ITERATIONS = 6
challengeIteration = 0

while challengeIteration < MAX_CHALLENGE_ITERATIONS:
    challengeIteration++

    // CHALLENGE: spawn parallel reviewer sub-agents from different angles
    spawn parallel reviewer agents (patterns, correctness, testing, stack)
    aggregate findings into review.md

    // EVALUATE: check findings
    if ALL PASS and critical == 0 and major == 0:
        CONVERGED → break to Phase 5

    if ANY NEEDS_REPLAN:
        → route back to planner (Phase 2), restart

    if ANY BLOCKED:
        → escalate to user

    // FIX: coder addresses ALL findings from all angles + ensures checks pass
    coder_result = run coder with phase: "ADDRESS_CHALLENGE_FINDINGS"

    if coder ESCALATE:
        → escalate to user

// If loop exhausted without convergence:
→ escalate to user with summary of remaining issues
```

**Note:** The coder is responsible for running automated checks (lint, type-check, tests) and ensuring they pass before returning `VERDICT: COMPLETE`. Challengers verify code quality from their angles — they don't re-run builds unless suspicious. The correctness challenger may re-run checks as part of its verification.

## 4.1: Challenge (Parallel Multi-Angle Review)

🔍 CHALLENGE ({challengeIteration}/{MAX}) - Parallel review: patterns, correctness, testing, stack...

**BEFORE delegating:** Update state.json:
- `position.phase` → `"challenge"`
- `challengeIteration` → current iteration number

**Determine review angles:** Always spawn these 3 base angles:
- `patterns` — architectural pattern compliance (grep existing code, verify new follows same)
- `correctness` — logic bugs, edge cases, error handling, data flow
- `testing` — test quality, coverage gaps, untested scenarios

**Plus 1 stack-specific angle** (if applicable):
- If `projectType` is `ui`/`react`/`vue`/`angular` → spawn `stack` angle (loads ui-checklist.md)
- If `projectType` is `api`/`rest`/`backend` → spawn `stack` angle (loads api-checklist.md)
- If `projectType` is `graphql` → spawn `stack` angle (loads graphql-checklist.md)
- If `projectType` is `unknown` → skip stack angle (3 reviewers only)

**Spawn all reviewer agents in parallel** (single response with multiple Agent calls):

```
Agent(some-claude-skills:reviewer, angle: "patterns", projectType, session_dir, working_dir, plugin_root, requirements, plan, iteration)
Agent(some-claude-skills:reviewer, angle: "correctness", projectType, session_dir, working_dir, plugin_root, requirements, plan, iteration)
Agent(some-claude-skills:reviewer, angle: "testing", projectType, session_dir, working_dir, plugin_root, requirements, plan, iteration)
Agent(some-claude-skills:reviewer, angle: "stack", projectType, session_dir, working_dir, plugin_root, requirements, plan, iteration)  // if applicable
```

**On re-challenge (iteration 2+):** Also pass `previous_review_path: "{session-dir}/review.md"` and `iteration: {challengeIteration}` to all reviewers.

## 4.1.1: Aggregate Review Results

After ALL parallel reviewers complete, aggregate their findings:

1. **Read each `review-{angle}.md`** from the session directory
2. **Determine overall verdict** — worst verdict wins:
   - Any BLOCKED → overall BLOCKED
   - Any NEEDS_REPLAN → overall NEEDS_REPLAN
   - Any NEEDS_WORK → overall NEEDS_WORK
   - All PASS → overall PASS
3. **Sum findings** across all angles: total CRITICAL_COUNT, MAJOR_COUNT
4. **Write merged `review.md`** combining all angle findings:

```markdown
# Code Review (Iteration {N})

## Decision: {worst verdict across all angles}

## Summary
{1-2 sentence merged assessment}

## Automated Checks
{from automated-checks.md}

## Review Angles

### Patterns — {VERDICT}
{findings from review-patterns.md}

### Correctness — {VERDICT}
{findings from review-correctness.md}

### Testing — {VERDICT}
{findings from review-testing.md}

### Stack ({projectType}) — {VERDICT}
{findings from review-stack.md, if applicable}

## Aggregate Counts
- Critical: {total across all angles}
- Major: {total across all angles}
- Minor: {total}
- Notes: {total}
```

5. **Route based on aggregate result:**

   **If ALL PASS AND total critical = 0 AND total major = 0:**
   - **CONVERGED** — code is clean from all angles
   - Print: `✅ Challenge passed (iteration {N}) — all {M} reviewers agree: code is clean`
   - Silent transition to Phase 5 (Test)

   **If ANY NEEDS_WORK:**
   - Print: `🔄 Challenge iteration {N}: {critical_count} critical, {major_count} major across {angles with issues} — fixing...`
   - Proceed to Phase 4.2 (Fix)

   **If ANY NEEDS_REPLAN:**
   - Route back to planner with review.md context
   - After planner updates: restart from Phase 3

   **If ANY BLOCKED:**
   - Update state.json phase to `"challenge-escalation"` (checkpoint)
   - Escalate to user with summary

## 4.2: Fix

🔧 FIXING - Addressing challenge findings from all angles (iteration {N})...

**BEFORE delegating:** Update state.json phase to `"challenge-fix"`.

Delegate to `some-claude-skills:coder` with:
- `phase: "ADDRESS_CHALLENGE_FINDINGS"`
- `iteration: {challengeIteration}`
- `review_path: "{session-dir}/review.md"` (the merged review with findings from all angles)
- session_dir, working_dir, plugin_root, plan path, requirements path

The merged review.md contains findings from all angles (patterns, correctness, testing, stack). The coder addresses ALL findings in one pass.

**Parse coder output:**
- `VERDICT: COMPLETE` → loop back to Phase 4.1 (parallel re-challenge from all angles)
- `VERDICT: ESCALATE` → update state.json phase to `"challenge-escalation"` (checkpoint), escalate to user
- `VERDICT: BLOCKED` → update state.json phase to `"challenge-escalation"` (checkpoint), escalate to user

**After coder completes:** Loop back to Phase 4.0 automatically (silent transition).

## 4.3: Convergence Failure

If `challengeIteration >= MAX_CHALLENGE_ITERATIONS` and still not clean:

**BEFORE prompting:** Update state.json phase to `"challenge-escalation"` (checkpoint).

```
Use AskUserQuestion:
  Question: "The challenge-fix loop has run {N} iterations but issues persist. Latest findings: {summary from review.md}."
  Header: "⚠️ Challenge Loop Not Converging"
  Options:
    1. "Continue iterating" - Run more challenge-fix cycles
    2. "Accept current state" - Proceed to testing as-is
    3. "Re-plan" - Go back to planning phase
    4. "Abort" - Stop the workflow
```

- "Continue" → reset iteration counter, continue loop
- "Accept" → proceed to Phase 5 (testing)
- "Re-plan" → route back to Phase 2
- "Abort" → exit gracefully
