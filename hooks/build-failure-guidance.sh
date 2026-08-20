#!/usr/bin/env bash
# PostToolUseFailure hook - provides guidance when build/test commands fail.
# Uses JSON systemMessage for structured feedback to Claude.
# Fail-open: any error → exit 0.

set -euo pipefail

input=$(cat)
tool_name=$(echo "$input" | jq -r '.tool_name // empty' 2>/dev/null || echo "")
command=$(echo "$input" | jq -r '.tool_input.command // empty' 2>/dev/null || echo "")

# Only handle Bash tool failures
if [[ "$tool_name" != "Bash" ]] || [[ -z "$command" ]]; then
  exit 0
fi

# Check if this is a build/test command failure
build_patterns="npm\s+(run|test|install)|pnpm\s+(run|test|install)|yarn\s+(run|test)|mvn\s+|./gradlew\s+|gradle\s+"

if echo "$command" | grep -qE "$build_patterns"; then
  cat <<EOF
{
  "systemMessage": "Build/test command failed. Before retrying: (1) Check CLAUDE.md for the correct command — do not improvise flags. (2) If the command matches CLAUDE.md, read the error output carefully and fix the root cause. (3) Do not retry the same command without making changes first."
}
EOF
  exit 0
fi

# Not a build/test command — no guidance needed
exit 0
