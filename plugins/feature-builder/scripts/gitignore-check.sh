#!/bin/bash
# Check if .workflow-sessions is in .gitignore, optionally add it.
#
# Usage: gitignore-check.sh <working-dir> [--fix]
#
# Without --fix: reports status only (JSON)
# With --fix: adds the entry if missing, creates .gitignore if needed
#
# Output: JSON on stdout

set -euo pipefail

WORKING_DIR="${1:?Missing working-dir}"
FIX="${2:-}"

GITIGNORE="$WORKING_DIR/.gitignore"

EXISTS=false
HAS_ENTRY=false

if [[ -f "$GITIGNORE" ]]; then
  EXISTS=true
  if grep -qF '.workflow-sessions' "$GITIGNORE" 2>/dev/null; then
    HAS_ENTRY=true
  fi
fi

FIXED=false
if [[ "$FIX" == "--fix" && "$HAS_ENTRY" == "false" ]]; then
  if [[ "$EXISTS" == "true" ]]; then
    # Append to existing .gitignore (ensure newline before entry)
    printf '\n# Feature Builder workflow sessions (internal use only)\n.workflow-sessions/\n' >> "$GITIGNORE"
  else
    # Create new .gitignore
    printf '# Feature Builder workflow sessions (internal use only)\n.workflow-sessions/\n' > "$GITIGNORE"
    EXISTS=true
  fi
  HAS_ENTRY=true
  FIXED=true
fi

cat <<JSON
{
  "gitignore_exists": $EXISTS,
  "workflow_sessions_ignored": $HAS_ENTRY,
  "fixed": $FIXED
}
JSON
