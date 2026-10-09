#!/usr/bin/env bash
# PermissionDenied hook — auto-retry on permission failures for known-safe operations.
# v2.1.89+: Return {"retry": true} to retry the denied tool call.
# Only retries for operations within the workflow session directory or known repo paths.
# Fail-safe: unknown paths are NOT retried (let the user decide).

set -euo pipefail

INPUT=$(cat)

FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Auto-retry for workflow session files (these are always safe)
if [ -n "$FILE_PATH" ] && [[ "$FILE_PATH" == *".workflow-sessions/"* ]]; then
  echo '{"retry": true}'
  exit 0
fi

# Auto-retry for .claude/ directory operations (settings, configs)
if [ -n "$FILE_PATH" ] && [[ "$FILE_PATH" == *"/.claude/"* ]]; then
  echo '{"retry": true}'
  exit 0
fi

# Auto-retry for Bash commands referencing workflow sessions
if [ -n "$COMMAND" ] && [[ "$COMMAND" == *".workflow-sessions"* ]]; then
  echo '{"retry": true}'
  exit 0
fi

# Don't retry anything else — let the user handle it
echo '{}'
exit 0
