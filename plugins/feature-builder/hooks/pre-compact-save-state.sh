#!/usr/bin/env bash
# PreCompact hook — saves session state before compaction and optionally blocks
# compaction during critical phases (implementation, challenge-fix).
#
# Writes a comprehensive snapshot to compaction-snapshot.json so PostCompact
# can re-inject richer context than grep-based extraction provides.
#
# Blocks compaction ONCE during active implementation/challenge-fix phases
# to protect in-progress agent context. The "block once" pattern prevents
# infinite blocking if context pressure is genuinely too high.

set -euo pipefail

if ! command -v jq &>/dev/null; then
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
  exit 0  # No active workflow — allow compaction
fi

SESSION_DIR=$(cat "$ACTIVE_SESSION_FILE" 2>/dev/null || echo "")
if [ -z "$SESSION_DIR" ] || [ ! -d "$SESSION_DIR" ]; then
  exit 0
fi

STATE_FILE="$SESSION_DIR/state.json"
if [ ! -f "$STATE_FILE" ]; then
  exit 0
fi

# Read full state
STATE_CONTENT=$(cat "$STATE_FILE" 2>/dev/null || echo "{}")
PHASE=$(printf '%s' "$STATE_CONTENT" | jq -r '.position.phase // empty' 2>/dev/null || echo "")
ITERATION=$(printf '%s' "$STATE_CONTENT" | jq -r '.position.iteration // 0' 2>/dev/null || echo "0")
TICKET=$(printf '%s' "$STATE_CONTENT" | jq -r '.ticketId // empty' 2>/dev/null || echo "")
BRANCH=$(printf '%s' "$STATE_CONTENT" | jq -r '.branch // empty' 2>/dev/null || echo "")
MODE=$(printf '%s' "$STATE_CONTENT" | jq -r '.mode // empty' 2>/dev/null || echo "")

# Build artifact inventory as newline-delimited JSON entries, then wrap in array
ARTIFACT_ENTRIES=""
for artifact in requirements.md design.md design-brief.md plan.md review.md review-patterns.md review-correctness.md review-testing.md review-stack.md test-results.md learnings.md escalation.md agent-failures.md; do
  ARTIFACT_PATH="$SESSION_DIR/$artifact"
  if [ -f "$ARTIFACT_PATH" ]; then
    SIZE=$(wc -c < "$ARTIFACT_PATH" 2>/dev/null || echo "0")
    [ -n "$ARTIFACT_ENTRIES" ] && ARTIFACT_ENTRIES="$ARTIFACT_ENTRIES,"
    ARTIFACT_ENTRIES="$ARTIFACT_ENTRIES{\"name\":\"$artifact\",\"size\":$SIZE,\"exists\":true}"
  fi
done
ARTIFACTS="[$ARTIFACT_ENTRIES]"

# Write comprehensive snapshot
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
jq -n \
  --arg ts "$TIMESTAMP" \
  --arg phase "$PHASE" \
  --arg iteration "$ITERATION" \
  --arg ticket "$TICKET" \
  --arg branch "$BRANCH" \
  --arg mode "$MODE" \
  --arg session_dir "$SESSION_DIR" \
  --argjson artifacts "$ARTIFACTS" \
  --argjson state "$STATE_CONTENT" \
  '{
    timestamp: $ts,
    session_dir: $session_dir,
    phase: $phase,
    iteration: ($iteration | tonumber),
    ticketId: $ticket,
    branch: $branch,
    mode: $mode,
    artifacts: $artifacts,
    state: $state
  }' > "$SESSION_DIR/compaction-snapshot.json" 2>/dev/null || {
  printf 'PreCompact: failed to write snapshot\n' >&2
  exit 0
}

# Critical phase gate: block compaction once during implementation/challenge-fix
case "$PHASE" in
  implementation|challenge-fix)
    BLOCK_MARKER="$SESSION_DIR/.compaction-blocked-once"
    if [ ! -f "$BLOCK_MARKER" ]; then
      touch "$BLOCK_MARKER"
      printf 'PreCompact: blocking first compaction during active %s phase — context is critical for in-progress work\n' "$PHASE" >&2
      exit 2  # Block compaction
    fi
    # Second attempt: allow — snapshot is saved, PostCompact will recover
    ;;
esac

exit 0
