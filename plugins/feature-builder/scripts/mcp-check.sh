#!/bin/bash
# Check which MCP servers are configured in the project.
# Reads .mcp.json or .claude/mcp.json and reports configured server names.
#
# NOTE: This checks *configuration*, not runtime availability.
# The orchestrator still uses ToolSearch to verify servers are actually responsive.
#
# Usage: mcp-check.sh <working-dir>
#
# Output: JSON on stdout with configured servers and known integrations

set -euo pipefail

WORKING_DIR="${1:?Missing working-dir}"

HAS_CONFIG=false
CONFIG_PATH=""

# Check both config locations
if [[ -f "$WORKING_DIR/.mcp.json" ]]; then
  HAS_CONFIG=true
  CONFIG_PATH="$WORKING_DIR/.mcp.json"
elif [[ -f "$WORKING_DIR/.claude/mcp.json" ]]; then
  HAS_CONFIG=true
  CONFIG_PATH="$WORKING_DIR/.claude/mcp.json"
fi

# Parse server names and detect known integrations
if [[ "$HAS_CONFIG" == "true" ]]; then
  python3 -c "
import json, sys

with open('$CONFIG_PATH') as f:
    config = json.load(f)

servers = list(config.get('mcpServers', {}).keys())

# Map known server names to integration types
known = {
    'jira': False,
    'figma': False,
    'designSystem': False,
    'github': False,
    'playwright': False
}

for name in servers:
    nl = name.lower()
    if 'jira' in nl or 'atlassian' in nl or 'confluence' in nl:
        known['jira'] = True
    if 'figma' in nl:
        known['figma'] = True
    if 'design' in nl or 'ds' in nl:
        known['designSystem'] = True
    if 'github' in nl:
        known['github'] = True
    if 'playwright' in nl:
        known['playwright'] = True

print(json.dumps({
    'has_config': True,
    'config_path': '$CONFIG_PATH',
    'servers': servers,
    'integrations': known
}, indent=2))
" 2>/dev/null
else
  cat <<JSON
{
  "has_config": false,
  "config_path": "",
  "servers": [],
  "integrations": {
    "jira": false,
    "figma": false,
    "designSystem": false,
    "github": false,
    "playwright": false
  }
}
JSON
fi
