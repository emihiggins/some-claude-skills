#!/bin/bash
# InstructionsLoaded hook — warns if target project has no CLAUDE.md.
# Only fires during active workflow sessions (checks .active-session pointer).
# Monorepo-aware: checks asset folder, .claude/ subdir, and git root.
# Fail-open: any error → exit 0 (allow).

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')

# Only relevant during active workflow sessions
ACTIVE_SESSION_FILE="$CWD/.workflow-sessions/.active-session"
if [ ! -f "$ACTIVE_SESSION_FILE" ]; then
  exit 0  # No active workflow — not our concern
fi

# Check for CLAUDE.md in multiple locations
# 1. Asset-level (working dir)
if [ -f "$CWD/CLAUDE.md" ] || [ -f "$CWD/.claude/CLAUDE.md" ]; then
  exit 0
fi

# 2. Git root (monorepo parent)
GIT_ROOT=$(cd "$CWD" && git rev-parse --show-toplevel 2>/dev/null || echo "")
if [ -n "$GIT_ROOT" ]; then
  if [ -f "$GIT_ROOT/CLAUDE.md" ] || [ -f "$GIT_ROOT/.claude/CLAUDE.md" ]; then
    exit 0
  fi
fi

echo "{\"notification\":\"WARNING: No CLAUDE.md found in project ($CWD) or repo root. The workflow works best with project-specific instructions. Run /generate-project-context to create one.\"}"
exit 0
