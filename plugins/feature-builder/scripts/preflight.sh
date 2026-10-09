#!/bin/bash
# Pre-flight validation for build-feature workflow.
# Runs deterministic checks before the orchestrator starts.
# The orchestrator calls this once at the beginning and uses the JSON output
# to skip checks it would otherwise do manually (reducing tool calls).
#
# Usage: preflight.sh [working-dir]
#
# Output: JSON summary on stdout with all pre-flight state

set -euo pipefail

WORKING_DIR="${1:-.}"
cd "$WORKING_DIR"

# --- Git checks ---
IS_GIT_REPO=false
GIT_BRANCH=""
GIT_CLEAN=true
GIT_UNCOMMITTED=""
HAS_REMOTE=false

if git rev-parse --is-inside-work-tree &>/dev/null; then
  IS_GIT_REPO=true
  GIT_BRANCH=$(git branch --show-current 2>/dev/null || echo "")
  DIRTY=$(git status --porcelain 2>/dev/null || echo "")
  if [[ -n "$DIRTY" ]]; then
    GIT_CLEAN=false
    GIT_UNCOMMITTED=$(echo "$DIRTY" | head -10 | sed 's/"/\\"/g' | tr '\n' ' ')
  fi
  if git remote get-url origin &>/dev/null; then
    HAS_REMOTE=true
  fi
fi

# --- .gitignore check ---
GITIGNORE_EXISTS=false
WORKFLOW_SESSIONS_IGNORED=false

if [[ -f ".gitignore" ]]; then
  GITIGNORE_EXISTS=true
  if grep -q '^\\.workflow-sessions/' .gitignore 2>/dev/null || grep -q '^\.workflow-sessions' .gitignore 2>/dev/null; then
    WORKFLOW_SESSIONS_IGNORED=true
  fi
fi

# --- CLAUDE.md check (with monorepo awareness) ---
HAS_CLAUDE_MD=false
CLAUDE_MD_PATH=""
PROJECT_TYPE="unknown"
IS_MONOREPO_ASSET=false
GIT_ROOT_DIR=""
HAS_ASSET_CLAUDE_MD=false
ASSET_CLAUDE_MD_PATH=""
HAS_ROOT_CLAUDE_MD=false
ROOT_CLAUDE_MD_PATH=""

# Detect monorepo: git root differs from working dir
if [[ "$IS_GIT_REPO" == "true" ]]; then
  GIT_ROOT_DIR=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
  NORM_CWD=$(pwd -P)
  NORM_GIT_ROOT=$(cd "$GIT_ROOT_DIR" 2>/dev/null && pwd -P || echo "")
  if [[ -n "$NORM_GIT_ROOT" ]] && [[ "$NORM_CWD" != "$NORM_GIT_ROOT" ]]; then
    IS_MONOREPO_ASSET=true
  fi
fi

# Check asset-level CLAUDE.md (in working dir)
if [[ -f "CLAUDE.md" ]]; then
  HAS_ASSET_CLAUDE_MD=true
  ASSET_CLAUDE_MD_PATH="CLAUDE.md"
elif [[ -f ".claude/CLAUDE.md" ]]; then
  HAS_ASSET_CLAUDE_MD=true
  ASSET_CLAUDE_MD_PATH=".claude/CLAUDE.md"
fi

# Check root-level CLAUDE.md (in git root, only if monorepo)
if [[ "$IS_MONOREPO_ASSET" == "true" ]] && [[ -n "$GIT_ROOT_DIR" ]]; then
  if [[ -f "$GIT_ROOT_DIR/CLAUDE.md" ]]; then
    HAS_ROOT_CLAUDE_MD=true
    ROOT_CLAUDE_MD_PATH="$GIT_ROOT_DIR/CLAUDE.md"
  elif [[ -f "$GIT_ROOT_DIR/.claude/CLAUDE.md" ]]; then
    HAS_ROOT_CLAUDE_MD=true
    ROOT_CLAUDE_MD_PATH="$GIT_ROOT_DIR/.claude/CLAUDE.md"
  fi
fi

# Effective CLAUDE.md: asset takes priority, fall back to root
if [[ "$HAS_ASSET_CLAUDE_MD" == "true" ]]; then
  HAS_CLAUDE_MD=true
  CLAUDE_MD_PATH="$ASSET_CLAUDE_MD_PATH"
elif [[ "$HAS_ROOT_CLAUDE_MD" == "true" ]]; then
  HAS_CLAUDE_MD=true
  CLAUDE_MD_PATH="$ROOT_CLAUDE_MD_PATH"
fi

# Extract projectType from effective CLAUDE.md (normalized to ui/api/graphql/unknown)
if [[ "$HAS_CLAUDE_MD" == "true" ]]; then
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

# --- Active session check ---
HAS_ACTIVE_SESSION=false
ACTIVE_SESSION_DIR=""
ACTIVE_SESSION_PHASE=""

if [[ -f ".workflow-sessions/.active-session" ]]; then
  ACTIVE_SESSION_DIR=$(cat ".workflow-sessions/.active-session" 2>/dev/null || echo "")
  if [[ -n "$ACTIVE_SESSION_DIR" ]] && [[ -d "$ACTIVE_SESSION_DIR" ]]; then
    HAS_ACTIVE_SESSION=true
    # Try to read phase from state.json
    if [[ -f "$ACTIVE_SESSION_DIR/state.json" ]]; then
      ACTIVE_SESSION_PHASE=$(python3 -c "import json; d=json.load(open('$ACTIVE_SESSION_DIR/state.json')); print(d.get('position',{}).get('phase','unknown'))" 2>/dev/null || echo "unknown")
    fi
  fi
fi

# --- Pending request check ---
HAS_PENDING_REQUEST=false
PENDING_REQUEST=""

if [[ -f ".workflow-sessions/.pending-request.md" ]]; then
  HAS_PENDING_REQUEST=true
  PENDING_REQUEST=$(head -5 ".workflow-sessions/.pending-request.md" 2>/dev/null | sed 's/"/\\"/g' | tr '\n' ' ')
fi

# --- Project detection (reuse detect-project.sh logic) ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_INFO="{}"
if [[ -f "$SCRIPT_DIR/detect-project.sh" ]]; then
  PROJECT_INFO=$("$SCRIPT_DIR/detect-project.sh" "$WORKING_DIR" 2>/dev/null || echo '{}')
fi

# --- MCP availability (check for common MCP configs) ---
HAS_MCP_CONFIG=false
MCP_SERVERS=""

if [[ -f ".mcp.json" ]]; then
  HAS_MCP_CONFIG=true
  MCP_SERVERS=$(python3 -c "import json; d=json.load(open('.mcp.json')); print(','.join(d.get('mcpServers',{}).keys()))" 2>/dev/null || echo "")
elif [[ -f ".claude/mcp.json" ]]; then
  HAS_MCP_CONFIG=true
  MCP_SERVERS=$(python3 -c "import json; d=json.load(open('.claude/mcp.json')); print(','.join(d.get('mcpServers',{}).keys()))" 2>/dev/null || echo "")
fi

# --- Output ---
cat <<EOF
{
  "git": {
    "is_repo": $IS_GIT_REPO,
    "branch": "$GIT_BRANCH",
    "clean": $GIT_CLEAN,
    "uncommitted": "$GIT_UNCOMMITTED",
    "has_remote": $HAS_REMOTE
  },
  "gitignore": {
    "exists": $GITIGNORE_EXISTS,
    "workflow_sessions_ignored": $WORKFLOW_SESSIONS_IGNORED
  },
  "claude_md": {
    "exists": $HAS_CLAUDE_MD,
    "path": "$CLAUDE_MD_PATH",
    "project_type": "$PROJECT_TYPE",
    "monorepo": {
      "is_asset": $IS_MONOREPO_ASSET,
      "git_root": "$GIT_ROOT_DIR",
      "asset_claude_md": {
        "exists": $HAS_ASSET_CLAUDE_MD,
        "path": "$ASSET_CLAUDE_MD_PATH"
      },
      "root_claude_md": {
        "exists": $HAS_ROOT_CLAUDE_MD,
        "path": "$ROOT_CLAUDE_MD_PATH"
      }
    }
  },
  "session": {
    "has_active": $HAS_ACTIVE_SESSION,
    "active_dir": "$ACTIVE_SESSION_DIR",
    "active_phase": "$ACTIVE_SESSION_PHASE",
    "has_pending_request": $HAS_PENDING_REQUEST,
    "pending_request": "$PENDING_REQUEST"
  },
  "project": $PROJECT_INFO,
  "mcp": {
    "has_config": $HAS_MCP_CONFIG,
    "servers": "$MCP_SERVERS"
  }
}
EOF
