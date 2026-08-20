#!/bin/bash
# Artifact enforcement hook — verifies agent wrote required output file.
# Runs as SubagentStop hook.
# Uses JSON decision output for cleaner messaging.
# Fail-open: any error → exit 0 (allow completion).
# Available fields (v2.0.42+): agent_type, agent_id, agent_transcript_path, cwd

INPUT=$(cat)
AGENT_TYPE=$(echo "$INPUT" | jq -r '.agent_type // empty')
AGENT_ID=$(echo "$INPUT" | jq -r '.agent_id // empty')
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')

# Find active session
ACTIVE_SESSION_FILE="$CWD/.workflow-sessions/.active-session"
if [ ! -f "$ACTIVE_SESSION_FILE" ]; then
  exit 0  # No active workflow — not our concern
fi

SESSION_DIR=$(cat "$ACTIVE_SESSION_FILE" 2>/dev/null)
if [ -z "$SESSION_DIR" ] || [ ! -d "$SESSION_DIR" ]; then
  exit 0  # Fail-open
fi

# Map agent to expected artifact + minimum byte size
case "$AGENT_TYPE" in
  "requirements-gatherer")
    ARTIFACT="$SESSION_DIR/requirements.md"
    MIN_SIZE=100
    ;;
  "planner")
    ARTIFACT="$SESSION_DIR/plan.md"
    MIN_SIZE=200
    ;;
  "designer")
    ARTIFACT="$SESSION_DIR/design-brief.md"
    MIN_SIZE=100
    ;;
  "coder")
    exit 0  # Coder commits code — no single artifact file expected
    ;;
  "reviewer")
    # Reviewer writes review-{angle}.md (angle-specific). Check for any review-*.md file.
    FOUND_REVIEW=$(find "$SESSION_DIR" -maxdepth 1 -name "review-*.md" -newer "$SESSION_DIR/plan.md" 2>/dev/null | head -1)
    if [ -n "$FOUND_REVIEW" ]; then
      ARTIFACT="$FOUND_REVIEW"
    else
      ARTIFACT="$SESSION_DIR/review.md"  # fallback for legacy single-reviewer mode
    fi
    MIN_SIZE=100
    ;;
  "tester"|"ui-tester")
    ARTIFACT="$SESSION_DIR/test-results.md"
    MIN_SIZE=50
    ;;
  "compound")
    ARTIFACT="$SESSION_DIR/learnings.md"
    MIN_SIZE=50
    ;;
  *)
    exit 0  # Unknown agent — allow completion
    ;;
esac

# Check artifact exists
BASENAME=$(basename "$ARTIFACT")
if [ ! -f "$ARTIFACT" ]; then
  cat <<EOF
{
  "decision": "block",
  "reason": "You must write $BASENAME to $SESSION_DIR before completing. This file was not found."
}
EOF
  exit 0
fi

# Check minimum size
FILE_SIZE=$(wc -c < "$ARTIFACT" 2>/dev/null || echo "0")
if [ "$FILE_SIZE" -lt "$MIN_SIZE" ]; then
  cat <<EOF
{
  "decision": "block",
  "reason": "$BASENAME exists but appears incomplete (${FILE_SIZE} bytes, minimum ${MIN_SIZE}). Please write complete content before finishing."
}
EOF
  exit 0
fi

# Artifact present and sufficient — allow completion
exit 0
