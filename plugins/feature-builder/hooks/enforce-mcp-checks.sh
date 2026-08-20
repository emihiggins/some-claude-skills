#!/usr/bin/env bash
# PreToolUse hook - enforces Phase 0.8 (MCP checks) runs before session creation
# Blocks Write tool when creating state.json without mcpAvailable field

set -euo pipefail

# Read PreToolUse hook input (JSON with tool info)
input=$(cat)

# Extract tool parameters
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null || echo "")
content=$(echo "$input" | jq -r '.tool_input.content // empty' 2>/dev/null || echo "")

# Check if this is creating state.json in a session directory
# Use basename to match exactly "state.json" — glob *"state.json" falsely matches team-state.json
file_basename=$(basename "$file_path" 2>/dev/null || echo "")
if [[ "$file_basename" == "state.json" ]] && [[ "$file_path" == *".workflow-sessions/"* ]]; then

  # Scope: only enforce for build-feature sessions, not fullstack-teams or setup-workspace.
  # Fullstack-teams and setup-workspace manage their own state.json with different required fields.
  # Detect by checking if content has "mode": "headless" (teammate session) or workspace-level markers.
  if echo "$content" | grep -q '"mode"[[:space:]]*:[[:space:]]*"headless"'; then
    # Headless teammate session — fields are pre-populated by the orchestrator, skip enforcement
    cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow"
  }
}
EOF
    exit 0
  fi

  # Check for workspace-level session (has "repos" array — fullstack-teams state.json)
  if echo "$content" | grep -q '"repos"[[:space:]]*:'; then
    # Workspace orchestrator session — different schema, skip build-feature enforcement
    cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow"
  }
}
EOF
    exit 0
  fi

  # This is a build-feature session - verify MCP checks completed

  if ! echo "$content" | grep -q '"mcpAvailable"'; then
    # DENY the tool use - Step 5 was skipped
    cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "Phase 0.8 violation: Session creation attempted before MCP pre-flight checks. state.json missing 'mcpAvailable' field. Phase 0.8 (MCP checks) MUST complete before Phase 0.10 (initialize state.json)."
  }
}
EOF
    exit 0
  fi

  if ! echo "$content" | grep -q '"testingCapability"'; then
    # DENY the tool use - testingCapability not set
    cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "Phase 0.8 violation: state.json missing 'testingCapability' field. Must be 'automated' or 'manual-only'. Set based on Playwright availability (UI) or server start command (API)."
  }
}
EOF
    exit 0
  fi
fi

# No violations - allow tool use
cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow"
  }
}
EOF
exit 0
