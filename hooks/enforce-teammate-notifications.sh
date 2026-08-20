#!/bin/bash
# TeammateIdle hook — ensures teammates notified sentinel before going idle.
# Uses JSON output with "continue" field (v2.1.47+):
#   {"continue": true}  — allow idle
#   {"continue": false, "stopReason": "..."} — force teammate to continue working
#
# Since we cannot reliably inspect task storage (internal format varies),
# this hook always reminds non-sentinel teammates to complete notification steps.

INPUT=$(cat)
TEAMMATE_NAME=$(echo "$INPUT" | jq -r '.teammate_name // empty')

# Skip for sentinel — it watches, not implements
if [ "$TEAMMATE_NAME" = "sentinel" ]; then
  echo '{"continue": true}'
  exit 0
fi

# Skip for lead
if [ "$TEAMMATE_NAME" = "lead" ]; then
  echo '{"continue": true}'
  exit 0
fi

# Force non-sentinel teammates to confirm they completed all notification steps.
# This is a lightweight nudge — if they already notified, they'll confirm and idle next turn.
cat <<EOF
{
  "continue": false,
  "stopReason": "Before going idle, ensure you have completed ALL notification steps:\n1. Sent a completion/escalation message to 'sentinel' with your repo name, verdict, and session path\n2. Sent a completion/escalation message to 'lead' with your status\n3. Marked your task as complete via TaskUpdate\nIf you have already done all three, you may go idle. Otherwise, complete them now."
}
EOF
