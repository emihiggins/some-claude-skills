#!/usr/bin/env bash
# Hook: Enforce MCP availability check before requirements gathering
# Triggered: SubagentStart (matcher: requirements-gatherer)
# Purpose: Prevent workflow from proceeding without MCP detection
# Fail-open: any error → exit 0 (allow).

set -euo pipefail

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null || echo "")

# Fail-open if no cwd
if [[ -z "$CWD" ]]; then
  exit 0
fi

# Find active session
ACTIVE_SESSION_FILE="$CWD/.workflow-sessions/.active-session"
if [[ ! -f "$ACTIVE_SESSION_FILE" ]]; then
  exit 0  # No active workflow — not our concern
fi

SESSION_DIR=$(cat "$ACTIVE_SESSION_FILE" 2>/dev/null || echo "")
if [[ -z "$SESSION_DIR" ]] || [[ ! -d "$SESSION_DIR" ]]; then
  exit 0  # Fail-open
fi

# Find state.json
STATE_FILE="$SESSION_DIR/state.json"

if [[ ! -f "$STATE_FILE" ]]; then
  echo "ERROR: state.json not found at $STATE_FILE" >&2
  echo "Phase 0 (Preflight) must complete before requirements gathering" >&2
  exit 1
fi

# Check if mcpAvailable field exists
if ! grep -q '"mcpAvailable"' "$STATE_FILE"; then
  echo "ERROR: MCP availability check not completed" >&2
  echo "" >&2
  echo "Phase 0.8 must run before requirements gathering." >&2
  echo "The orchestrator must:" >&2
  echo "  1. Use ToolSearch to detect available MCP servers (design system, Playwright, Jira, Figma)" >&2
  echo "  2. If UI project and design system missing: prompt user for setup" >&2
  echo "  3. Write 'mcpAvailable' field to state.json" >&2
  echo "" >&2
  echo "Blocking requirements-gatherer start until this check completes." >&2
  exit 1
fi

# Extract isUIProject and mcpAvailable from state.json
IS_UI_PROJECT=$(grep -o '"isUIProject"[[:space:]]*:[[:space:]]*true' "$STATE_FILE" || echo "")
DS_AVAILABLE=$(grep -o '"designSystem"[[:space:]]*:[[:space:]]*true' "$STATE_FILE" || echo "")

# If UI project and design system not available, this should have been caught in Phase 0.8
if [[ -n "$IS_UI_PROJECT" ]] && [[ -z "$DS_AVAILABLE" ]]; then
  echo "WARNING: UI project detected but Design System MCP not available" >&2
  echo "Requirements gathering will proceed, but coder may need to search node_modules" >&2
  echo "Consider setting up Design System MCP for better component discovery" >&2
fi

# Check passed
exit 0
