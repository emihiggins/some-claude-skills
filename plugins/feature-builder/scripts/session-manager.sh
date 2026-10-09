#!/bin/bash
# Session lifecycle management for some-claude-skills workflow.
# Handles creation, discovery, resumption, abandonment, and cleanup of sessions.
#
# Usage: session-manager.sh <subcommand> [options]
#
# Subcommands:
#   init       <working-dir> <session-id> <ticket-id> <branch>  Create new session directory + state.json
#   find-active <working-dir>                                    Find incomplete sessions, return JSON
#   abandon    <session-dir> [reason]                            Mark session as abandoned
#   cleanup    <working-dir>                                     List stale sessions as JSON for orchestrator
#   delete     <session-dir>                                     Delete a session directory
#   clear-pointer <working-dir>                                  Remove .active-session and .pending-request.md
#
# All subcommands output JSON to stdout.
# Errors go to stderr with exit code 1.

set -euo pipefail

die() { echo "{\"error\": \"$1\"}" >&2; exit 1; }

SUBCOMMAND="${1:-}"
shift || true

case "$SUBCOMMAND" in

# ─── init ────────────────────────────────────────────────────────────────────
# Creates session directory, state.json, active-session pointer, and history/ dir.
# Expects the orchestrator to fill in mcpAvailable and testingCapability later via Edit.
#
# Args: <working-dir> <session-id> <ticket-id> <branch>
# Output: JSON with session_dir path
init)
  WORKING_DIR="${1:?Missing working-dir}"
  SESSION_ID="${2:?Missing session-id}"
  TICKET_ID="${3:?Missing ticket-id}"
  BRANCH="${4:?Missing branch}"

  SESSION_DIR="$WORKING_DIR/.workflow-sessions/$SESSION_ID"

  # Fail if session already exists
  if [[ -d "$SESSION_DIR" ]]; then
    die "Session directory already exists: $SESSION_DIR"
  fi

  # Create directory structure
  mkdir -p "$SESSION_DIR/history"

  # Write active-session pointer
  echo "$SESSION_DIR" > "$WORKING_DIR/.workflow-sessions/.active-session"

  TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  # Write initial state.json (orchestrator will update mcpAvailable, testingCapability, projectType later)
  cat > "$SESSION_DIR/state.json" <<STATEJSON
{
  "sessionId": "$SESSION_ID",
  "created": "$TIMESTAMP",
  "status": "in_progress",
  "ticketId": "$TICKET_ID",
  "branch": "$BRANCH",
  "projectType": "unknown",
  "claudeMdExists": true,
  "mcpAvailable": {},
  "testingCapability": "manual-only",
  "position": {
    "phase": "setup",
    "iteration": 1,
    "lastAgent": null
  },
  "approvals": {},
  "loop": {
    "totalIterations": 1,
    "loopBacks": []
  },
  "agents": []
}
STATEJSON

  cat <<JSON
{
  "session_dir": "$SESSION_DIR",
  "session_id": "$SESSION_ID",
  "state_json": "$SESSION_DIR/state.json",
  "created": "$TIMESTAMP"
}
JSON
  ;;

# ─── find-active ─────────────────────────────────────────────────────────────
# Finds incomplete (in_progress) sessions. Returns JSON array.
# The orchestrator uses this to decide resume vs fresh start.
#
# Args: <working-dir>
# Output: JSON array of session objects
find-active)
  WORKING_DIR="${1:?Missing working-dir}"
  SESSIONS_DIR="$WORKING_DIR/.workflow-sessions"

  # No sessions dir → empty array
  if [[ ! -d "$SESSIONS_DIR" ]]; then
    echo "[]"
    exit 0
  fi

  RESULTS="["
  FIRST=true

  for STATE_FILE in "$SESSIONS_DIR"/session-*/state.json; do
    # Handle no matches (glob returns literal pattern)
    [[ -f "$STATE_FILE" ]] || continue

    SESSION_DIR=$(dirname "$STATE_FILE")
    SESSION_ID=$(basename "$SESSION_DIR")

    # Parse fields from state.json using python3 (available on macOS)
    FIELDS=$(python3 -c "
import json, sys
try:
    d = json.load(open('$STATE_FILE'))
    status = d.get('status', 'unknown')
    if status != 'in_progress':
        sys.exit(1)
    print(json.dumps({
        'session_id': d.get('sessionId', '$SESSION_ID'),
        'session_dir': '$SESSION_DIR',
        'status': status,
        'ticket_id': d.get('ticketId', ''),
        'branch': d.get('branch', ''),
        'phase': d.get('position', {}).get('phase', 'unknown'),
        'created': d.get('created', ''),
        'project_type': d.get('projectType', 'unknown')
    }))
except Exception:
    sys.exit(1)
" 2>/dev/null) || continue

    if [[ "$FIRST" == "true" ]]; then
      FIRST=false
    else
      RESULTS+=","
    fi
    RESULTS+="$FIELDS"
  done

  RESULTS+="]"
  echo "$RESULTS"
  ;;

# ─── abandon ─────────────────────────────────────────────────────────────────
# Marks a session as abandoned in its state.json.
#
# Args: <session-dir> [reason]
# Output: JSON confirmation
abandon)
  SESSION_DIR="${1:?Missing session-dir}"
  REASON="${2:-User started new session}"

  STATE_FILE="$SESSION_DIR/state.json"
  if [[ ! -f "$STATE_FILE" ]]; then
    die "No state.json found at $STATE_FILE"
  fi

  TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  # Update state.json: status → abandoned
  python3 -c "
import json
with open('$STATE_FILE', 'r') as f:
    d = json.load(f)
d['status'] = 'abandoned'
d['abandonedAt'] = '$TIMESTAMP'
d['abandonReason'] = '''$REASON'''
with open('$STATE_FILE', 'w') as f:
    json.dump(d, f, indent=2)
" 2>/dev/null || die "Failed to update state.json"

  cat <<JSON
{
  "abandoned": true,
  "session_dir": "$SESSION_DIR",
  "timestamp": "$TIMESTAMP",
  "reason": "$REASON"
}
JSON
  ;;

# ─── cleanup ─────────────────────────────────────────────────────────────────
# Lists stale sessions (abandoned, completed, unknown) as JSON.
# Does NOT delete — the orchestrator presents results to the user and calls delete.
#
# Args: <working-dir>
# Output: JSON with stale and active arrays
cleanup)
  WORKING_DIR="${1:?Missing working-dir}"
  SESSIONS_DIR="$WORKING_DIR/.workflow-sessions"

  if [[ ! -d "$SESSIONS_DIR" ]]; then
    echo '{"stale": [], "active": []}'
    exit 0
  fi

  STALE="["
  ACTIVE="["
  STALE_FIRST=true
  ACTIVE_FIRST=true

  for SESSION_DIR in "$SESSIONS_DIR"/session-*/; do
    [[ -d "$SESSION_DIR" ]] || continue

    SESSION_ID=$(basename "$SESSION_DIR")
    STATE_FILE="$SESSION_DIR/state.json"

    # Parse session info
    INFO=$(python3 -c "
import json, os, sys
from datetime import datetime
try:
    d = json.load(open('$STATE_FILE'))
    status = d.get('status', 'unknown')
    created = d.get('created', '')
    # Calculate age in days
    age_days = 0
    if created:
        try:
            ct = datetime.fromisoformat(created.replace('Z', '+00:00'))
            age_days = (datetime.now(ct.tzinfo) - ct).days
        except Exception:
            pass
    print(json.dumps({
        'session_id': d.get('sessionId', '$SESSION_ID'),
        'session_dir': '$SESSION_DIR'.rstrip('/'),
        'status': status,
        'ticket_id': d.get('ticketId', ''),
        'branch': d.get('branch', ''),
        'phase': d.get('position', {}).get('phase', 'unknown'),
        'created': created,
        'age_days': age_days
    }))
except Exception:
    # Missing or corrupt state.json
    print(json.dumps({
        'session_id': '$SESSION_ID',
        'session_dir': '$SESSION_DIR'.rstrip('/'),
        'status': 'unknown',
        'ticket_id': '',
        'branch': '',
        'phase': 'unknown',
        'created': '',
        'age_days': -1
    }))
" 2>/dev/null) || continue

    STATUS=$(python3 -c "import json; print(json.loads('$INFO'.replace(\"'\", ''))['status'])" 2>/dev/null || echo "unknown")

    case "$STATUS" in
      in_progress)
        if [[ "$ACTIVE_FIRST" == "true" ]]; then ACTIVE_FIRST=false; else ACTIVE+=","; fi
        ACTIVE+="$INFO"
        ;;
      *)
        if [[ "$STALE_FIRST" == "true" ]]; then STALE_FIRST=false; else STALE+=","; fi
        STALE+="$INFO"
        ;;
    esac
  done

  STALE+="]"
  ACTIVE+="]"

  cat <<JSON
{
  "stale": $STALE,
  "active": $ACTIVE
}
JSON
  ;;

# ─── delete ──────────────────────────────────────────────────────────────────
# Deletes a session directory. Orchestrator calls this after user approval.
#
# Args: <session-dir>
# Output: JSON confirmation
delete)
  SESSION_DIR="${1:?Missing session-dir}"

  if [[ ! -d "$SESSION_DIR" ]]; then
    die "Session directory does not exist: $SESSION_DIR"
  fi

  rm -rf "$SESSION_DIR"

  cat <<JSON
{
  "deleted": true,
  "session_dir": "$SESSION_DIR"
}
JSON
  ;;

# ─── clear-pointer ───────────────────────────────────────────────────────────
# Removes .active-session pointer and .pending-request.md.
# Called during Phase 7 cleanup.
#
# Args: <working-dir>
# Output: JSON confirmation
clear-pointer)
  WORKING_DIR="${1:?Missing working-dir}"
  SESSIONS_DIR="$WORKING_DIR/.workflow-sessions"

  REMOVED_ACTIVE=false
  REMOVED_PENDING=false

  if [[ -f "$SESSIONS_DIR/.active-session" ]]; then
    rm -f "$SESSIONS_DIR/.active-session"
    REMOVED_ACTIVE=true
  fi

  if [[ -f "$SESSIONS_DIR/.pending-request.md" ]]; then
    rm -f "$SESSIONS_DIR/.pending-request.md"
    REMOVED_PENDING=true
  fi

  cat <<JSON
{
  "removed_active_pointer": $REMOVED_ACTIVE,
  "removed_pending_request": $REMOVED_PENDING
}
JSON
  ;;

# ─── Unknown / help ──────────────────────────────────────────────────────────
*)
  die "Unknown subcommand: '$SUBCOMMAND'. Use: init, find-active, abandon, cleanup, delete, clear-pointer"
  ;;

esac
