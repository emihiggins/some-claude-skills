#!/usr/bin/env bash
# UserPromptSubmit hook: a minimal skill recommender.
#
# Reads the hook JSON payload from stdin, extracts the user prompt, and scans
# this marketplace's skills for a name/trigger match. When it finds one, it
# prints a short suggestion to stdout, which Claude Code injects as context.
#
# This is a deliberately small starting point. Extend the matching logic (e.g.
# score against the "Use when" trigger phrases in each SKILL.md description) as
# your marketplace grows.
set -euo pipefail

# --- read the prompt from the hook payload -------------------------------
PAYLOAD="$(cat || true)"
PROMPT=""
if command -v jq >/dev/null 2>&1 && [ -n "$PAYLOAD" ]; then
  PROMPT="$(printf '%s' "$PAYLOAD" | jq -r '.prompt // empty' 2>/dev/null || true)"
fi
# Fallback: if jq is unavailable or the payload was not JSON, treat it as raw.
if [ -z "$PROMPT" ]; then
  PROMPT="$PAYLOAD"
fi
[ -z "$PROMPT" ] && exit 0

# Lowercase the prompt for case-insensitive matching (tr is portable).
PROMPT_LC="$(printf '%s' "$PROMPT" | tr '[:upper:]' '[:lower:]')"

# --- locate the skills directory -----------------------------------------
ROOT="${CLAUDE_PLUGIN_ROOT:-.}"
SKILLS_DIR="$ROOT/skills"
[ -d "$SKILLS_DIR" ] || exit 0

# --- scan skills for a name match ----------------------------------------
NAMES=""
for skill_dir in "$SKILLS_DIR"/*/; do
  [ -d "$skill_dir" ] || continue
  name="$(basename "$skill_dir")"
  # Turn the kebab-case name into a loose phrase for matching.
  phrase="$(printf '%s' "$name" | tr '-' ' ')"
  case "$PROMPT_LC" in
    *"$phrase"*|*"$name"*)
      NAMES="$NAMES/$name"
      ;;
  esac
done

[ -z "$NAMES" ] && exit 0

echo "Relevant skills in this marketplace may help with this request:"
printf '%s' "$NAMES" | tr '/' '\n' | grep -v '^$' | while IFS= read -r n; do
  echo "  - /$n"
done
