#!/usr/bin/env bash
# UserPromptSubmit hook — injects active session context on every user prompt.
# Ensures the orchestrator always knows where it is, even after compaction or long pauses.
#
# This fires on EVERY user prompt, so it must be very fast.
# The .active-session file check is O(1) and short-circuits immediately when no workflow is active.

set -euo pipefail

if ! command -v jq &>/dev/null; then
  exit 0
fi

INPUT=$(cat)

CWD=$(printf '%s' "$INPUT" | jq -r '.cwd // empty')
if [ -z "$CWD" ]; then
  exit 0
fi

# Fast path: no active session = no context to inject
ACTIVE_SESSION_FILE="$CWD/.workflow-sessions/.active-session"
if [ ! -f "$ACTIVE_SESSION_FILE" ]; then
  exit 0
fi

SESSION_DIR=$(cat "$ACTIVE_SESSION_FILE" 2>/dev/null || echo "")
if [ -z "$SESSION_DIR" ] || [ ! -d "$SESSION_DIR" ]; then
  exit 0
fi

STATE_FILE="$SESSION_DIR/state.json"
if [ ! -f "$STATE_FILE" ]; then
  exit 0
fi

# Extract key fields via jq — handles both compact and pretty-printed JSON
STATE_CONTENT=$(cat "$STATE_FILE" 2>/dev/null || echo "{}")
PHASE=$(printf '%s' "$STATE_CONTENT" | jq -r '.position.phase // empty' 2>/dev/null || echo "")
ITERATION=$(printf '%s' "$STATE_CONTENT" | jq -r '.position.iteration // 0' 2>/dev/null || echo "0")
BRANCH=$(printf '%s' "$STATE_CONTENT" | jq -r '.branch // empty' 2>/dev/null || echo "")
SESSION_ID=$(basename "$SESSION_DIR")

# Output to stdout — UserPromptSubmit hooks inject stdout as additionalContext
PARTS="[Feature Builder] Session: $SESSION_ID"
[ -n "$PHASE" ] && PARTS="$PARTS | Phase: $PHASE"
[ -n "$ITERATION" ] && [ "$ITERATION" != "0" ] && PARTS="$PARTS | Iter: $ITERATION"
[ -n "$BRANCH" ] && PARTS="$PARTS | Branch: $BRANCH"

echo "$PARTS"

exit 0
