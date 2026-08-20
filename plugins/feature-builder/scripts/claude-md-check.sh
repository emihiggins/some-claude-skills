#!/bin/bash
# Check if CLAUDE.md exists and extract projectType from it.
# In monorepos, detects both asset-level and root-level CLAUDE.md files.
#
# Usage: claude-md-check.sh <working-dir>
#
# Output: JSON on stdout with existence flags, paths, monorepo detection, and projectType

set -euo pipefail

WORKING_DIR="${1:?Missing working-dir}"

# --- Asset-level CLAUDE.md (in working dir) ---
ASSET_EXISTS=false
ASSET_PATH=""

if [[ -f "$WORKING_DIR/CLAUDE.md" ]]; then
  ASSET_EXISTS=true
  ASSET_PATH="$WORKING_DIR/CLAUDE.md"
elif [[ -f "$WORKING_DIR/.claude/CLAUDE.md" ]]; then
  ASSET_EXISTS=true
  ASSET_PATH="$WORKING_DIR/.claude/CLAUDE.md"
fi

# --- Monorepo detection: check if git root differs from working dir ---
IS_MONOREPO_ASSET=false
ROOT_EXISTS=false
ROOT_PATH=""
GIT_ROOT=""

if command -v git &>/dev/null; then
  GIT_ROOT=$(cd "$WORKING_DIR" && git rev-parse --show-toplevel 2>/dev/null || echo "")
fi

if [[ -n "$GIT_ROOT" ]]; then
  # Normalize paths for comparison
  NORM_WORKING=$(cd "$WORKING_DIR" && pwd -P)
  NORM_ROOT=$(cd "$GIT_ROOT" 2>/dev/null && pwd -P || echo "")

  if [[ "$NORM_WORKING" != "$NORM_ROOT" ]]; then
    IS_MONOREPO_ASSET=true

    # Check for root-level CLAUDE.md
    if [[ -f "$GIT_ROOT/CLAUDE.md" ]]; then
      ROOT_EXISTS=true
      ROOT_PATH="$GIT_ROOT/CLAUDE.md"
    elif [[ -f "$GIT_ROOT/.claude/CLAUDE.md" ]]; then
      ROOT_EXISTS=true
      ROOT_PATH="$GIT_ROOT/.claude/CLAUDE.md"
    fi
  fi
fi

# --- Determine effective CLAUDE.md (asset takes priority, fall back to root) ---
EXISTS=false
CLAUDE_MD_PATH=""
PROJECT_TYPE="unknown"

if [[ "$ASSET_EXISTS" == "true" ]]; then
  EXISTS=true
  CLAUDE_MD_PATH="$ASSET_PATH"
elif [[ "$ROOT_EXISTS" == "true" ]]; then
  EXISTS=true
  CLAUDE_MD_PATH="$ROOT_PATH"
fi

# Extract projectType from effective CLAUDE.md
if [[ "$EXISTS" == "true" ]]; then
  PT=$(grep -iE 'project.?type' "$CLAUDE_MD_PATH" 2>/dev/null | head -1 | \
    sed 's/.*[:`] *//' | tr -d '`*()' | awk '{print $1}' | tr '[:upper:]' '[:lower:]')
  case "$PT" in
    ui|react|vue|angular|frontend) PROJECT_TYPE="ui" ;;
    api|rest|backend|service) PROJECT_TYPE="api" ;;
    graphql) PROJECT_TYPE="graphql" ;;
    node|python|kotlin|java) PROJECT_TYPE="api" ;;
    *) PROJECT_TYPE="unknown" ;;
  esac
fi

cat <<JSON
{
  "exists": $EXISTS,
  "path": "$CLAUDE_MD_PATH",
  "project_type": "$PROJECT_TYPE",
  "monorepo": {
    "is_asset": $IS_MONOREPO_ASSET,
    "git_root": "$GIT_ROOT",
    "asset_claude_md": {
      "exists": $ASSET_EXISTS,
      "path": "$ASSET_PATH"
    },
    "root_claude_md": {
      "exists": $ROOT_EXISTS,
      "path": "$ROOT_PATH"
    }
  }
}
JSON
