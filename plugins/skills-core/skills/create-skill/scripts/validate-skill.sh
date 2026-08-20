#!/bin/bash
# Validate structural correctness of a skill, workflow, or agent.
# Checks for required sections, naming conventions, and completeness.
#
# Usage: validate-skill.sh <skill-or-agent-path>
#
# For skills: pass the skill directory (e.g., skills/brainstorm/)
# For agents: pass the agent .md file (e.g., agents/coder.md)
#
# Output: JSON on stdout with pass/fail and issues list

set -euo pipefail

TARGET="${1:?Missing skill/agent path}"

ISSUES="[]"
WARNINGS="[]"
TYPE="unknown"

add_issue() {
  ISSUES=$(python3 -c "
import json
issues = json.loads('$ISSUES')
issues.append('$1')
print(json.dumps(issues))
")
}

add_warning() {
  WARNINGS=$(python3 -c "
import json
warnings = json.loads('$WARNINGS')
warnings.append('$1')
print(json.dumps(warnings))
")
}

# Determine type: skill directory, workflow directory, or agent file
if [[ -d "$TARGET" ]]; then
  SKILL_FILE="$TARGET/SKILL.md"
  if [[ ! -f "$SKILL_FILE" ]]; then
    echo '{"valid": false, "type": "unknown", "issues": ["No SKILL.md found in directory"], "warnings": []}'
    exit 0
  fi

  NAME=$(basename "$TARGET")
  if [[ "$NAME" == workflow-* ]]; then
    TYPE="workflow"
  else
    TYPE="skill"
  fi

  CONTENT=$(cat "$SKILL_FILE")

elif [[ -f "$TARGET" ]]; then
  TYPE="agent"
  NAME=$(basename "$TARGET" .md)
  CONTENT=$(cat "$TARGET")
  SKILL_FILE="$TARGET"
else
  echo '{"valid": false, "type": "unknown", "issues": ["Path does not exist: '"$TARGET"'"], "warnings": []}'
  exit 0
fi

# --- Universal checks ---

# U1: Frontmatter with description
if ! echo "$CONTENT" | head -5 | grep -q '^---'; then
  add_issue "U1: Missing frontmatter (--- block at top)"
elif ! echo "$CONTENT" | grep -q '^description:'; then
  add_issue "U1: Frontmatter missing description field"
fi

# U2: Output contract
if ! echo "$CONTENT" | grep -qi 'output contract'; then
  add_issue "U2: Missing output contract section"
fi

# U5: No placeholders left
if echo "$CONTENT" | grep -qE '\{placeholder\}|TODO|FIXME'; then
  add_warning "U5: Contains placeholders or TODOs"
fi

# --- Type-specific checks ---

case "$TYPE" in
  skill)
    # S2: Input documented
    if ! echo "$CONTENT" | grep -qi '## Input'; then
      add_warning "S2: Missing ## Input section"
    fi

    # S4: No hardcoded paths
    if echo "$CONTENT" | grep -qE '/Users/|/home/'; then
      add_warning "S4: Contains hardcoded absolute paths"
    fi
    ;;

  workflow)
    # W1: Phase transitions
    if ! echo "$CONTENT" | grep -qi 'phase'; then
      add_issue "W1: No phase transitions documented"
    fi

    # W2: Agent table
    if ! echo "$CONTENT" | grep -qi 'subagent\|Available.*Agent'; then
      add_issue "W2: No agent table found"
    fi

    # W6: Error handling
    if ! echo "$CONTENT" | grep -qi 'error handling'; then
      add_warning "W6: Missing error handling section"
    fi

    # Check for co-located agents
    AGENTS_DIR="$TARGET/agents"
    if [[ -d "$AGENTS_DIR" ]]; then
      for AGENT_FILE in "$AGENTS_DIR"/*.md; do
        [[ -f "$AGENT_FILE" ]] || continue
        AGENT_NAME=$(basename "$AGENT_FILE" .md)
        # Check agent is referenced in SKILL.md
        if ! echo "$CONTENT" | grep -q "$AGENT_NAME"; then
          add_warning "Orphan agent: agents/$AGENT_NAME.md not referenced in SKILL.md"
        fi
      done
    fi
    ;;

  agent)
    # A1: Complete frontmatter
    for FIELD in "name:" "description:" "tools:" "model:"; do
      if ! echo "$CONTENT" | head -20 | grep -q "^$FIELD"; then
        add_issue "A1: Frontmatter missing $FIELD"
      fi
    done

    # A3: Output contract with structured format
    if ! echo "$CONTENT" | grep -qi 'SUCCESS:\|VERDICT:'; then
      add_issue "A3: Output contract missing SUCCESS/VERDICT fields"
    fi

    # A6: MCP access declared
    if ! echo "$CONTENT" | grep -qi 'MCP Access'; then
      add_warning "A6: MCP access not declared"
    fi

    # A9: check-artifact.sh hook
    if ! echo "$CONTENT" | grep -q 'check-artifact'; then
      add_warning "A9: Missing check-artifact.sh Stop hook"
    fi
    ;;
esac

# --- Output ---
ISSUE_COUNT=$(python3 -c "import json; print(len(json.loads('$ISSUES')))")
WARNING_COUNT=$(python3 -c "import json; print(len(json.loads('$WARNINGS')))")
VALID="true"
if [[ "$ISSUE_COUNT" -gt 0 ]]; then
  VALID="false"
fi

cat <<JSON
{
  "valid": $VALID,
  "type": "$TYPE",
  "name": "$NAME",
  "path": "$TARGET",
  "issues": $ISSUES,
  "issue_count": $ISSUE_COUNT,
  "warnings": $WARNINGS,
  "warning_count": $WARNING_COUNT
}
JSON
