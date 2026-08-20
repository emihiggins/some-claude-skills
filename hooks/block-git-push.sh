#!/usr/bin/env bash
# PreToolUse hook — blocks git push during active workflow phases.
# Allows push at completion phase (Phase 7b) where the orchestrator
# offers the user push/PR options.
#
# Without an active workflow session, push is always allowed.

set -euo pipefail

INPUT=$(cat)
COMMAND=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null || echo "")

if [[ -z "$COMMAND" ]]; then
  echo '{"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "allow"}}'
  exit 0
fi

# Only check git push commands
if ! printf '%s' "$COMMAND" | grep -qE '(^|[;&|]\s*)git\s+push(\s|$)'; then
  echo '{"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "allow"}}'
  exit 0
fi

# Check if there's an active workflow session
CWD=$(printf '%s' "$INPUT" | jq -r '.cwd // empty' 2>/dev/null || echo "")
if [ -z "$CWD" ]; then
  # No cwd — allow (can't determine context)
  echo '{"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "allow"}}'
  exit 0
fi

ACTIVE_SESSION_FILE="$CWD/.workflow-sessions/.active-session"
if [ ! -f "$ACTIVE_SESSION_FILE" ]; then
  # No active workflow — push is fine
  echo '{"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "allow"}}'
  exit 0
fi

SESSION_DIR=$(cat "$ACTIVE_SESSION_FILE" 2>/dev/null || echo "")
STATE_FILE="$SESSION_DIR/state.json"

if [ -z "$SESSION_DIR" ] || [ ! -f "$STATE_FILE" ]; then
  # Can't read state — allow (don't block on broken state)
  echo '{"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "allow"}}'
  exit 0
fi

# Read current phase
PHASE=$(printf '%s' "$(cat "$STATE_FILE")" | jq -r '.position.phase // empty' 2>/dev/null || echo "")

# Allow push at completion phase (Phase 7b — user explicitly requested push/PR)
if [ "$PHASE" = "completion" ]; then
  echo '{"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "allow"}}'
  exit 0
fi

# Block push during all other workflow phases
cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "Git push blocked during active workflow (phase: ${PHASE:-unknown}). Push is only allowed at completion phase when the user explicitly requests it."
  }
}
EOF
exit 0
