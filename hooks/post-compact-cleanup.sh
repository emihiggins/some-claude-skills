#!/usr/bin/env bash
# Post-compaction state re-injection hook
# Fires after conversation compaction completes.
# Re-injects critical session state that may have been lost during compaction.
# This is especially important for long-running agents (coder, sentinel)
# that compact mid-task and lose context about what phase they're in.
#
# Uses compaction-snapshot.json (from PreCompact hook) when available for
# richer context recovery. Falls back to grep-based state.json extraction.

set -euo pipefail

if ! command -v jq &>/dev/null; then
  echo "--- Post-Compaction Context Recovery ---"
  echo "IMPORTANT: Context was compacted. jq not available for state extraction. Re-read state.json manually."
  echo "--- End Context Recovery ---"
  exit 0
fi

INPUT=$(cat)

CWD=$(printf '%s' "$INPUT" | jq -r '.cwd // empty')

if [ -z "$CWD" ]; then
  exit 0
fi

# Find active session
ACTIVE_SESSION_FILE="$CWD/.workflow-sessions/.active-session"
if [ ! -f "$ACTIVE_SESSION_FILE" ]; then
  exit 0  # No active workflow
fi

SESSION_DIR=$(cat "$ACTIVE_SESSION_FILE" 2>/dev/null)
if [ -z "$SESSION_DIR" ] || [ ! -d "$SESSION_DIR" ]; then
  exit 0
fi

STATE_FILE="$SESSION_DIR/state.json"
if [ ! -f "$STATE_FILE" ]; then
  echo "Compaction complete. No state.json found." >&2
  exit 0
fi

# Build context summary — output to STDOUT so it gets injected into conversation context.
# PostCompact hooks: stdout -> model context, stderr -> log only.
echo "--- Post-Compaction Context Recovery ---"

# Try snapshot-first path (richer context from PreCompact hook)
SNAPSHOT_FILE="$SESSION_DIR/compaction-snapshot.json"
if [ -f "$SNAPSHOT_FILE" ]; then
  SNAPSHOT=$(cat "$SNAPSHOT_FILE")

  SESSION_PATH=$(printf '%s' "$SNAPSHOT" | jq -r '.session_dir // empty')
  TICKET=$(printf '%s' "$SNAPSHOT" | jq -r '.ticketId // empty')
  BRANCH=$(printf '%s' "$SNAPSHOT" | jq -r '.branch // empty')
  PHASE=$(printf '%s' "$SNAPSHOT" | jq -r '.phase // empty')
  ITERATION=$(printf '%s' "$SNAPSHOT" | jq -r '.iteration // 0')
  MODE=$(printf '%s' "$SNAPSHOT" | jq -r '.mode // empty')

  echo "Session: $(basename "$SESSION_PATH")"
  [ -n "$TICKET" ] && echo "Ticket: $TICKET"
  [ -n "$BRANCH" ] && echo "Branch: $BRANCH"
  [ -n "$PHASE" ] && echo "Current phase: $PHASE"
  [ "$ITERATION" != "0" ] && echo "Iteration: $ITERATION"
  [ -n "$MODE" ] && echo "Mode: $MODE"

  echo "Available artifacts:"
  printf '%s' "$SNAPSHOT" | jq -r '.artifacts[] | "  \u2713 \(.name) (\(.size) bytes)"' 2>/dev/null || true

  # Consume snapshot (one-shot)
  rm -f "$SNAPSHOT_FILE"
else
  # Fallback: grep-based extraction from state.json (handles both compact and pretty-printed JSON)
  PHASE=$(grep -oE '"phase"\s*:\s*"[^"]*"' "$STATE_FILE" 2>/dev/null | head -1 | sed 's/.*"phase"[[:space:]]*:[[:space:]]*"//;s/"//')
  TICKET=$(grep -oE '"ticketId"\s*:\s*"[^"]*"' "$STATE_FILE" 2>/dev/null | head -1 | sed 's/.*"ticketId"[[:space:]]*:[[:space:]]*"//;s/"//')
  BRANCH=$(grep -oE '"branch"\s*:\s*"[^"]*"' "$STATE_FILE" 2>/dev/null | head -1 | sed 's/.*"branch"[[:space:]]*:[[:space:]]*"//;s/"//')
  ITERATION=$(grep -oE '"iteration"\s*:\s*[0-9]+' "$STATE_FILE" 2>/dev/null | head -1 | sed 's/.*"iteration"[[:space:]]*:[[:space:]]*//')

  echo "Session: $(basename "$SESSION_DIR")"
  [ -n "$TICKET" ] && echo "Ticket: $TICKET"
  [ -n "$BRANCH" ] && echo "Branch: $BRANCH"
  [ -n "$PHASE" ] && echo "Current phase: $PHASE"
  [ -n "$ITERATION" ] && [ "$ITERATION" != "0" ] && echo "Iteration: $ITERATION"

  echo "Available artifacts:"
  for ARTIFACT in requirements.md design.md design-brief.md plan.md review.md test-results.md learnings.md escalation.md agent-failures.md; do
    if [ -f "$SESSION_DIR/$ARTIFACT" ]; then
      SIZE=$(wc -c < "$SESSION_DIR/$ARTIFACT" 2>/dev/null || echo "0")
      echo "  ✓ $ARTIFACT (${SIZE} bytes)"
    fi
  done

  for REVIEW_FILE in "$SESSION_DIR"/review-*.md; do
    if [ -f "$REVIEW_FILE" ]; then
      NAME=$(basename "$REVIEW_FILE")
      SIZE=$(wc -c < "$REVIEW_FILE" 2>/dev/null || echo "0")
      echo "  ✓ $NAME (${SIZE} bytes)"
    fi
  done
fi

echo ""
echo "IMPORTANT: Context was compacted. Re-read state.json and the relevant artifacts above to restore full context before continuing."
echo "--- End Context Recovery ---"

exit 0
