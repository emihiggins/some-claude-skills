#!/usr/bin/env bash
# Silent webhook to session observatory. Exits 0 regardless of server availability.
# Fire-and-forget by design — no set -euo pipefail because this script must never
# fail or block the workflow, even if curl/jq fail or env vars are missing.
#
# Usage: echo '{"key":"val"}' | notify-observatory.sh <event-name>
# The hook input JSON from stdin is augmented with {"event": "<event-name>"} and POSTed.
#
# Observatory URL is configured via plugin userConfig (CLAUDE_PLUGIN_OPTION_OBSERVATORY_URL).
# Falls back to http://localhost:45678 if not configured. Empty string disables notifications.

INPUT=$(cat)
EVENT="${1:-unknown}"

# Resolve observatory URL from plugin userConfig
OBSERVATORY_URL="${CLAUDE_PLUGIN_OPTION_OBSERVATORY_URL-http://localhost:45678}"
if [ -z "$OBSERVATORY_URL" ]; then
  exit 0  # Explicitly disabled — skip
fi

# Quick check: is the observatory listening? (1s connect timeout)
if ! curl -sf -o /dev/null --connect-timeout 1 "$OBSERVATORY_URL/health" 2>/dev/null; then
  if ! curl -sf -o /dev/null --connect-timeout 1 "$OBSERVATORY_URL/" 2>/dev/null; then
    exit 0  # Server not running — skip silently
  fi
fi

# Merge event name into the hook input payload
BODY=$(printf '%s' "$INPUT" | jq -c --arg evt "$EVENT" '. + {event: $evt}' 2>/dev/null)
if [ -z "$BODY" ] || [ "$BODY" = "null" ]; then
  # stdin wasn't valid JSON — send minimal payload
  BODY="{\"event\":\"$EVENT\"}"
fi

# Forward to observatory
curl -sf -o /dev/null -X POST \
  -H 'Content-Type: application/json' \
  -d "$BODY" \
  --connect-timeout 2 \
  --max-time 3 \
  "$OBSERVATORY_URL/webhook/claude-event" 2>/dev/null

exit 0
