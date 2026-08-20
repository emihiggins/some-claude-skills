#!/usr/bin/env bash
# PreToolUse hook - blocks Bash commands that use cd to change directory
# Agents should use absolute or relative paths, not cd

set -euo pipefail

# Read PreToolUse hook input (JSON with tool info)
input=$(cat)

# Extract the command from Bash tool input
command=$(echo "$input" | jq -r '.tool_input.command // empty' 2>/dev/null || echo "")

# Skip if no command
if [[ -z "$command" ]]; then
  echo '{"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "allow"}}'
  exit 0
fi

# Check for cd patterns:
# - "cd /path &&" or "cd /path;" (cd as prefix before other commands)
# - standalone "cd /path"
# Allow: grep patterns containing "cd", variable names with cd, etc.
if echo "$command" | grep -qE '(^|[;&|]\s*)cd\s+'; then
  cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "Do not use 'cd' in Bash commands. The working directory is already set correctly. Use absolute paths or paths relative to the project root instead. For git commands, use 'git -C /path/to/repo' if you need to target a different directory."
  }
}
EOF
  exit 0
fi

# No violations - allow
cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow"
  }
}
EOF
exit 0
