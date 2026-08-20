# Quality Checklist

Used by `create-skill enhance` mode to score skills, workflows, and agents against quality criteria.

## Universal Criteria (All Types)

| # | Criterion | Weight | Check |
|---|-----------|--------|-------|
| U1 | Has frontmatter with description | Required | `---` block at top with `description:` |
| U2 | Has output contract | Required | `## Output Contract` section with structured format |
| U3 | Steps are numbered and specific | Important | No vague "understand the context" — concrete actions |
| U4 | Error handling documented | Important | What can go wrong, what to do |
| U5 | No dead code or placeholders | Minor | No TODO, FIXME, or `{placeholder}` left over |
| U6 | Follows naming taxonomy | Required | `workflow-`, `ref-`, `tool-`, or no prefix |

## Skill-Specific Criteria

| # | Criterion | Weight | Check |
|---|-----------|--------|-------|
| S1 | Single responsibility | Required | Does one thing, not a mini-workflow |
| S2 | Input documented | Required | `## Input` section with parameters |
| S3 | AskUserQuestion for user input | Important | Not freeform prompts — structured options |
| S4 | No hardcoded paths | Important | Uses `${CLAUDE_PLUGIN_ROOT}`, `${CLAUDE_SKILL_DIR}` |

## Workflow-Specific Criteria

| # | Criterion | Weight | Check |
|---|-----------|--------|-------|
| W1 | Phase transitions documented | Required | Each phase has marker + state.json update |
| W2 | Agent table present | Required | `## Available Subagents` with model/tools/MCP |
| W3 | Output contract parsing | Required | After each agent, parse return status |
| W4 | User gates at checkpoints | Required | Stopping allowed at checkpoints only |
| W5 | Scripts for deterministic work | Important | Shell scripts for validation, parsing, detection |
| W6 | Error handling for agent failures | Required | Silent failure detection, recovery strategy |
| W7 | State management documented | Important | state.json fields, update timing |
| W8 | Loop-back support (if applicable) | Important | Fresh context on loop-backs |

## Agent-Specific Criteria

| # | Criterion | Weight | Check |
|---|-----------|--------|-------|
| A1 | Frontmatter complete | Required | name, description, tools, model, effortLevel, maxTurns, permissionMode |
| A2 | Input contract defined | Required | What JSON/context the orchestrator passes |
| A3 | Output contract defined | Required | Structured return format (SUCCESS/VERDICT/SUMMARY) |
| A4 | Single responsibility stated | Required | "You do X. You do NOT do Y." |
| A5 | Tool usage rules | Important | Grep not grep, Read not cat, etc. |
| A6 | MCP access declared | Required | Explicit YES or NO |
| A7 | Escalation conditions | Important | When to return to orchestrator |
| A8 | Anti-rationalization guards | Nice-to-have | "Don't skip tests", "Don't assume it works" |
| A9 | check-artifact.sh hook | Required | Stop hook verifies artifact was written |

## Scoring

- **Required:** Must pass. Failure = must fix.
- **Important:** Should pass. Failure = suggest fix but not blocking.
- **Minor / Nice-to-have:** Bonus quality. Mention but don't push.

**Score calculation:**
- Count of passed Required criteria / total Required criteria = quality score
- Report as: "{passed}/{total} required, {important_passed}/{important_total} important"

**Thresholds:**
- All required pass = "Ready for use"
- 1-2 required fail = "Needs fixes before use"
- 3+ required fail = "Needs significant work"
