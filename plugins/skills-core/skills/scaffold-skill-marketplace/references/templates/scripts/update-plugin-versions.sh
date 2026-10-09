#!/usr/bin/env bash
# Bump the version across all plugin manifest files in lockstep.
# Usage: bash scripts/update-plugin-versions.sh <new-version>
# Called by semantic-release (see .releaserc.json) and can be run manually.
set -euo pipefail

VERSION="${1:-}"
if [ -z "$VERSION" ]; then
  echo "Usage: $0 <new-version>" >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "ERROR: jq is required but not installed." >&2
  exit 1
fi

# Resolve repo root as the parent of this script's directory.
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

PLUGIN_JSON="$ROOT/.claude-plugin/plugin.json"
MARKETPLACE_JSON="$ROOT/.claude-plugin/marketplace.json"

update_json() {
  # $1 = file, $2 = jq filter
  local file="$1" filter="$2" tmp
  tmp="$(mktemp)"
  jq --arg v "$VERSION" "$filter" "$file" >"$tmp"
  mv "$tmp" "$file"
  echo "  updated $file -> $VERSION"
}

echo "Bumping version to $VERSION"
update_json "$PLUGIN_JSON" '.version = $v'
update_json "$MARKETPLACE_JSON" '.metadata.version = $v | .plugins |= map(.version = $v)'
echo "Done."
