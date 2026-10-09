#!/usr/bin/env bash
# Stop hook — state-aware enforcement of silent transitions.
# Checks workflow state to determine if stopping is legitimate.
# Only allows stops at explicit user checkpoints.
# Uses JSON decision output for cleaner messaging.
# Fail-open: any error reading state → exit 0 (allow).

set -euo pipefail

input=$(cat)
cwd=$(echo "$input" | jq -r '.cwd // empty' 2>/dev/null || echo "")

# --- Fail-open guard ---
if [[ -z "$cwd" ]]; then
  exit 0
fi

# --- Check if a workflow is active ---
active_session_file="$cwd/.workflow-sessions/.active-session"
if [[ ! -f "$active_session_file" ]]; then
  exit 0  # No active workflow — allow stop
fi

session_dir=$(cat "$active_session_file" 2>/dev/null || echo "")
if [[ -z "$session_dir" ]]; then
  exit 0  # Can't read pointer — fail-open
fi

# --- Read current phase from state.json ---
state_file="$session_dir/state.json"
if [[ ! -f "$state_file" ]]; then
  # No state.json yet = Phase 0 (Preflight).
  # Phase 0 has checkpoints AND silent transitions. Need to check response content.

  response=$(echo "$input" | jq -r '.response // empty' 2>/dev/null || echo "")

  # Phase 0 checkpoint indicators (legitimate stops):
  # - 0.2: Incomplete session prompt
  # - 0.5: CLAUDE.md missing prompt
  # - 0.6: Ticket number prompt
  # - 0.8: MCP availability prompts
  phase0_checkpoint_indicators=(
    "Found incomplete session"
    "Resume from where it left off"
    "No CLAUDE.md found"
    "CLAUDE.md tells agents about"
    "What is the ticket number"
    "Jira ticket"
    "GitHub issue"
    "UI Feature Detected"
    "Design System MCP"
    "Playwright MCP"
    "MCP server is not configured"
  )

  for indicator in "${phase0_checkpoint_indicators[@]}"; do
    if echo "$response" | grep -q "$indicator"; then
      exit 0  # Legitimate Phase 0 checkpoint — allow stop
    fi
  done

  # Phase 0 silent transition indicators (should NOT stop):
  phase0_silent_indicators=(
    "Session initialized"
    "Preflight checks"
    "Detecting project type"
    "Checking MCP availability"
    "Java version check"
    "Project Type:"
    "Build Tool:"
  )

  for indicator in "${phase0_silent_indicators[@]}"; do
    if echo "$response" | grep -q "$indicator"; then
      cat <<EOF
{
  "decision": "block",
  "reason": "Phase 0 silent transition detected. Continue immediately to the next preflight step without waiting for user input."
}
EOF
      exit 0
    fi
  done

  # No clear indicators — fail-open (allow stop during early Phase 0)
  exit 0
fi

phase=$(jq -r '.position.phase // empty' "$state_file" 2>/dev/null || echo "")
status=$(jq -r '.status // empty' "$state_file" 2>/dev/null || echo "")

# --- If workflow is already completed/abandoned, allow stop ---
if [[ "$status" == "completed" ]] || [[ "$status" == "abandoned" ]]; then
  exit 0
fi

# --- Checkpoint allowlist: phases where stopping for user input is legitimate ---
checkpoint_phases=(
  "brainstorm"
  "design-review"
  "design-approval"
  "plan-review"
  "challenge-escalation"
  "manual-verification"
  "completion"
)

# --- Fullstack-teams has additional valid wait phases ---
# Check if this is a teams/fullstack session (has teamName or mode=fullstack in state)
mode=$(jq -r '.mode // empty' "$state_file" 2>/dev/null || echo "")
team_name=$(jq -r '.teamName // empty' "$state_file" 2>/dev/null || echo "")
if [[ -n "$team_name" ]] || [[ "$mode" == "fullstack-teams" ]] || [[ "$mode" == "compete" ]]; then
  checkpoint_phases+=(
    "implementation"      # Waiting for teammates to complete
    "integration"         # Cross-repo verification
    "requirements"        # Gathering requirements (may need user input)
    "ready_for_design"    # Between setup and design
  )
fi

for cp in "${checkpoint_phases[@]}"; do
  if [[ "$phase" == "$cp" ]]; then
    exit 0  # Legitimate checkpoint — allow stop
  fi
done

# --- Secondary check: pattern-match known violation phrases ---
# Even at checkpoint phases, these phrases indicate the model is being lazy
response=$(echo "$input" | jq -r '.response // empty' 2>/dev/null || echo "")
violation_phrases=(
  "ready to proceed"
  "shall i continue"
  "let me know when ready"
  "waiting for confirmation"
  "should i proceed"
  "would you like me to continue"
  "can i continue"
  "may i proceed"
)

for phrase in "${violation_phrases[@]}"; do
  if echo "$response" | grep -iq "$phrase"; then
    cat <<EOF
{
  "decision": "block",
  "reason": "Silent transition violation: You said '$phrase'. Continue to the next workflow step immediately without waiting for user input. See Core Principle #5."
}
EOF
    exit 0
  fi
done

# --- Phase is NOT a checkpoint — block the stop ---
if [[ -n "$phase" ]]; then
  cat <<EOF
{
  "decision": "block",
  "reason": "Workflow active (phase: $phase) — not a user checkpoint. Continue to the next step immediately. Do not stop or wait for user input."
}
EOF
  exit 0
fi

# Empty phase — fail-open
exit 0
