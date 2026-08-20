#!/usr/bin/env bash
# PreToolUse hook - blocks direct test runner invocations
# Agents must use npm/pnpm scripts, not jest/eslint/tsc/vitest directly

set -euo pipefail

input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command // empty' 2>/dev/null || echo "")

if [[ -z "$command" ]]; then
  echo '{"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "allow"}}'
  exit 0
fi

# Check for direct test runner invocations at the start of a command or after ; & |
# Block: jest, eslint, tsc, vitest, mocha, prettier — whether invoked directly or via npx
# Allow: "npm run test", "pnpm test", "yarn test" (package.json scripts)
blocked_runners="jest|eslint|tsc|vitest|mocha|prettier"

if echo "$command" | grep -qE "(^|[;&|]\s*)(npx\s+|pnpx\s+)?(${blocked_runners})(\s|$)"; then

  cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "Do not run test runners directly. Use the project's npm/pnpm scripts instead (e.g., 'npm run test:unit', 'npm run lint'). Check CLAUDE.md for the correct commands."
  }
}
EOF
  exit 0
fi

echo '{"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "allow"}}'
exit 0
