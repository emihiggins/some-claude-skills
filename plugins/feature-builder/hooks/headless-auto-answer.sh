#!/usr/bin/env bash
# PreToolUse hook — auto-answers AskUserQuestion prompts in headless mode.
#
# API format (v2.1.85+): PreToolUse can satisfy AskUserQuestion by returning:
# {
#   "hookSpecificOutput": {
#     "hookEventName": "PreToolUse",
#     "permissionDecision": "allow",
#     "updatedInput": {
#       "question": "original question",
#       "options": ["original", "options"],
#       "answers": { "original question": "selected option label" }
#     }
#   }
# }
# The answers field maps question text to the selected option label.
#
# Purpose: Headless teammates (spawned by fullstack-teams) run build-feature
# which has interactive checkpoints. If a prompt fires in headless mode,
# the teammate blocks with no user to respond. This hook auto-answers
# predictable prompts as a safety net.
#
# Non-headless sessions: hook passes through (no auto-answer).
# Unknown prompts in headless: logs to escalation.md and allows through.

set -euo pipefail

INPUT=$(cat)

TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

# Only intercept AskUserQuestion
if [ "$TOOL_NAME" != "AskUserQuestion" ]; then
  exit 0
fi

# Extract tool input fields safely via jq (no shell expansion risks)
QUESTION=$(echo "$INPUT" | jq -r '.tool_input.question // empty')
# Preserve the full tool_input for echoing back in updatedInput
TOOL_INPUT=$(echo "$INPUT" | jq -c '.tool_input // {}')

# Find active session to check mode
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
if [ -z "$CWD" ]; then
  exit 0
fi

ACTIVE_SESSION_FILE="$CWD/.workflow-sessions/.active-session"
if [ ! -f "$ACTIVE_SESSION_FILE" ]; then
  exit 0  # No active workflow — allow prompt through
fi

SESSION_DIR=$(cat "$ACTIVE_SESSION_FILE" 2>/dev/null)
if [ -z "$SESSION_DIR" ] || [ ! -d "$SESSION_DIR" ]; then
  exit 0
fi

STATE_FILE="$SESSION_DIR/state.json"
if [ ! -f "$STATE_FILE" ]; then
  exit 0
fi

# Check if we're in headless mode (use jq for safe JSON parsing, handles concurrent writes)
MODE=$(jq -r '.mode // empty' "$STATE_FILE" 2>/dev/null || echo "")

if [ "$MODE" != "headless" ]; then
  # Not headless — allow the prompt through to the user
  exit 0
fi

# --- HEADLESS MODE: Auto-answer based on question content ---

# Helper: build safe JSON response using jq (prevents injection via proper escaping).
# Echoes back the original tool_input with an added "answers" field.
build_response() {
  local answer="$1"
  echo "Auto-answering in headless mode: $answer" >&2
  # Build updatedInput: merge original tool_input with answers map
  echo "$TOOL_INPUT" | jq \
    --arg q "$QUESTION" \
    --arg a "$answer" \
    '{
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "allow",
        updatedInput: (. + { answers: { ($q): $a } })
      }
    }'
}

# Match question patterns and auto-answer.
# Uses lowercase comparison to avoid regex injection via question text.
# Patterns are ordered from most specific to least specific to avoid false positives.
QUESTION_LOWER=$(printf '%s' "$QUESTION" | tr '[:upper:]' '[:lower:]')

# Helper: fixed-string match on lowercased question (safe from regex injection)
matches() {
  printf '%s' "$QUESTION_LOWER" | grep -qiF "$1"
}

# Challenge escalation — accept current state and proceed to testing
if matches "challenge" && (matches "not converging" || matches "iterations"); then
  build_response "Accept current state"
  exit 0
fi

# MCP setup — continue without MCP (headless teammates use pre-configured MCP)
if matches "mcp server"; then
  # Check if this is the "where to configure" follow-up
  if matches "where" && matches "configure"; then
    build_response "User config"
  else
    build_response "Continue without MCP"
  fi
  exit 0
fi

# Design review — approve design (in headless, design was pre-created by lead)
if matches "designer" && matches "created"; then
  build_response "Approve design"
  exit 0
fi

# Plan approval — approve
if matches "approve" && matches "plan"; then
  build_response "Approve"
  exit 0
fi

# Manual verification — skip (no user available for manual testing)
if matches "manual" && matches "verif"; then
  build_response "Skip verification"
  exit 0
fi

# Agent teams flag check
if matches "agent teams" || matches "CLAUDE_CODE_EXPERIMENTAL"; then
  build_response "Done, continue"
  exit 0
fi

# Incomplete session resume — start fresh in headless (session was pre-created by lead)
if matches "existing session" || (matches "resume" && matches "start fresh"); then
  build_response "Start fresh"
  exit 0
fi

# CLAUDE.md generation — continue without (headless uses existing CLAUDE.md)
if matches "claude.md" && (matches "generate" || matches "no " || matches "project context"); then
  build_response "Continue without"
  exit 0
fi

# Push/PR prompt — done, no push (headless should not push)
if matches "push" && (matches "remote" || matches "branch"); then
  build_response "Done"
  exit 0
fi
if matches "pull request" || matches "create pr"; then
  build_response "Done"
  exit 0
fi

# Repo failed prompt (from fullstack-teams error handling)
if matches "failed" && matches "proceed"; then
  build_response "Skip"
  exit 0
fi

# --- UNKNOWN PROMPT: Log to escalation and allow through ---
printf 'WARNING: Unknown AskUserQuestion in headless mode. Allowing through.\n' >&2
printf 'Question excerpt: %.200s\n' "$QUESTION" >&2

# Write escalation for the lead to see
ESCALATION_FILE="$SESSION_DIR/escalation.md"
{
  echo ""
  echo "## Headless Auto-Answer: Unknown Prompt ($(date -u +%Y-%m-%dT%H:%M:%SZ))"
  echo ""
  echo "An unexpected AskUserQuestion fired in headless mode."
  echo "The hook allowed it through, but this may cause the teammate to block."
  echo ""
  # Safely truncate and sanitize the question for markdown
  printf '**Question:** %.500s\n' "$(printf '%s' "$QUESTION" | tr '`$' "'_")"
  echo ""
} >> "$ESCALATION_FILE" 2>/dev/null || true

# Allow the prompt through — the teammate may handle it or block
exit 0
