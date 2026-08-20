#!/bin/bash
# Scan existing skills and agents in the plugin for discovery.
# Used by create-skill to check for overlap and suggest reusable components.
#
# Usage: scan-skills.sh <plugin-root>
#
# Output: JSON on stdout with skills and agents arrays

set -euo pipefail

PLUGIN_ROOT="${1:?Missing plugin root path}"

SKILLS="["
AGENTS="["
SKILL_FIRST=true
AGENT_FIRST=true

# Scan skills
for SKILL_DIR in "$PLUGIN_ROOT"/skills/*/; do
  [[ -d "$SKILL_DIR" ]] || continue
  SKILL_FILE="$SKILL_DIR/SKILL.md"
  [[ -f "$SKILL_FILE" ]] || continue

  NAME=$(basename "$SKILL_DIR")
  # Extract description from frontmatter
  DESC=$(grep '^description:' "$SKILL_FILE" 2>/dev/null | head -1 | sed 's/^description: *//' | sed 's/"/\\"/g')

  # Determine type
  if [[ "$NAME" == workflow-* ]]; then
    STYPE="workflow"
  elif [[ "$NAME" == ref-* ]]; then
    STYPE="reference"
  elif [[ "$NAME" == tool-* ]]; then
    STYPE="tool"
  else
    STYPE="atomic"
  fi

  if [[ "$SKILL_FIRST" == "true" ]]; then SKILL_FIRST=false; else SKILLS+=","; fi
  SKILLS+="{\"name\":\"$NAME\",\"type\":\"$STYPE\",\"description\":\"$DESC\",\"path\":\"$SKILL_DIR\"}"
done
SKILLS+="]"

# Scan shared agents
for AGENT_FILE in "$PLUGIN_ROOT"/agents/*.md; do
  [[ -f "$AGENT_FILE" ]] || continue

  NAME=$(basename "$AGENT_FILE" .md)
  DESC=$(grep '^description:' "$AGENT_FILE" 2>/dev/null | head -1 | sed 's/^description: *//' | sed 's/"/\\"/g')
  MODEL=$(grep '^model:' "$AGENT_FILE" 2>/dev/null | head -1 | sed 's/^model: *//')

  if [[ "$AGENT_FIRST" == "true" ]]; then AGENT_FIRST=false; else AGENTS+=","; fi
  AGENTS+="{\"name\":\"$NAME\",\"model\":\"$MODEL\",\"description\":\"$DESC\",\"path\":\"$AGENT_FILE\",\"location\":\"shared\"}"
done

# Scan co-located agents in workflow skills
for WORKFLOW_DIR in "$PLUGIN_ROOT"/skills/workflow-*/; do
  [[ -d "$WORKFLOW_DIR" ]] || continue
  AGENTS_DIR="$WORKFLOW_DIR/agents"
  [[ -d "$AGENTS_DIR" ]] || continue

  WORKFLOW_NAME=$(basename "$WORKFLOW_DIR")
  for AGENT_FILE in "$AGENTS_DIR"/*.md; do
    [[ -f "$AGENT_FILE" ]] || continue

    NAME=$(basename "$AGENT_FILE" .md)
    DESC=$(grep '^description:' "$AGENT_FILE" 2>/dev/null | head -1 | sed 's/^description: *//' | sed 's/"/\\"/g')
    MODEL=$(grep '^model:' "$AGENT_FILE" 2>/dev/null | head -1 | sed 's/^model: *//')

    if [[ "$AGENT_FIRST" == "true" ]]; then AGENT_FIRST=false; else AGENTS+=","; fi
    AGENTS+="{\"name\":\"$NAME\",\"model\":\"$MODEL\",\"description\":\"$DESC\",\"path\":\"$AGENT_FILE\",\"location\":\"$WORKFLOW_NAME\"}"
  done
done
AGENTS+="]"

cat <<JSON
{
  "skills": $SKILLS,
  "agents": $AGENTS
}
JSON
