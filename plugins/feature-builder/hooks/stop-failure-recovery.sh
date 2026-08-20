#!/usr/bin/env bash
# StopFailure hook — fires when an agent stops due to API errors (rate limits, etc.)
# v2.1.78+: This hook fires on unexpected failures, not normal stops.
#
# Purpose: Log the failure for the orchestrator/lead and write recovery context
# so the agent can be respawned with knowledge of what happened.

set -euo pipefail

if ! command -v jq &>/dev/null; then
  printf 'StopFailure hook: jq not found, skipping\n' >&2
  exit 0
fi

INPUT=$(cat)

AGENT_TYPE=$(printf '%s' "$INPUT" | jq -r '.agent_type // empty')
AGENT_ID=$(printf '%s' "$INPUT" | jq -r '.agent_id // empty')
ERROR=$(printf '%s' "$INPUT" | jq -r '.error // empty')
CWD=$(printf '%s' "$INPUT" | jq -r '.cwd // empty')

# Sanitize all untrusted fields — strip backticks, dollar signs, backslashes
sanitize() {
  printf '%s' "$1" | tr '`$\\' "'__"
}

SAFE_AGENT_TYPE=$(sanitize "$AGENT_TYPE")
SAFE_AGENT_ID=$(sanitize "$AGENT_ID")
SAFE_ERROR=$(sanitize "$ERROR")

# Find active session
if [ -z "$CWD" ]; then
  exit 0
fi

ACTIVE_SESSION_FILE="$CWD/.workflow-sessions/.active-session"
if [ ! -f "$ACTIVE_SESSION_FILE" ]; then
  exit 0
fi

SESSION_DIR=$(cat "$ACTIVE_SESSION_FILE" 2>/dev/null || echo "")
if [ -z "$SESSION_DIR" ] || [ ! -d "$SESSION_DIR" ]; then
  exit 0
fi

# Log the failure to session directory
FAILURE_LOG="$SESSION_DIR/agent-failures.md"
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
{
  printf '\n'
  printf '## Agent Failure: %s (%s)\n' "$SAFE_AGENT_TYPE" "$TIMESTAMP"
  printf '\n'
  printf -- '- **Agent:** %s\n' "$SAFE_AGENT_TYPE"
  [ -n "$SAFE_AGENT_ID" ] && printf -- '- **Agent ID:** %s\n' "$SAFE_AGENT_ID"
  printf -- '- **Error:** %.500s\n' "$SAFE_ERROR"
  printf '\n'
} >> "$FAILURE_LOG" 2>/dev/null || {
  printf 'WARNING: Could not write to %s\n' "$FAILURE_LOG" >&2
}

# Log to stderr for orchestrator visibility
printf 'StopFailure: %s agent failed — %.200s\n' "$SAFE_AGENT_TYPE" "$SAFE_ERROR" >&2

# Notify observatory if available
OBSERVATORY_URL="${CLAUDE_PLUGIN_OPTION_OBSERVATORY_URL-http://localhost:45678}"
if [ -n "$OBSERVATORY_URL" ] && command -v curl &>/dev/null; then
  if curl -sf -o /dev/null --connect-timeout 1 "$OBSERVATORY_URL/health" 2>/dev/null; then
    curl -s -X POST "$OBSERVATORY_URL/webhook/claude-event" \
      -H "Content-Type: application/json" \
      -d "$(jq -n \
        --arg t "$AGENT_TYPE" \
        --arg e "$(printf '%.500s' "$ERROR")" \
        --arg s "$(basename "$SESSION_DIR")" \
        --arg ts "$TIMESTAMP" \
        '{event: "agent_failure", agent_type: $t, error: $e, session: $s, timestamp: $ts}')" \
      --connect-timeout 1 \
      --max-time 2 \
      2>/dev/null || true
  fi
fi

# Exit 2 triggers asyncRewake — stderr (line 62) becomes a system reminder to Claude,
# proactively informing the orchestrator about the failure without requiring it to poll.
exit 2
