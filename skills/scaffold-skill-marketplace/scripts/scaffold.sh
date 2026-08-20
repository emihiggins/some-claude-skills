#!/usr/bin/env bash
# Scaffold a new Claude Code plugin-marketplace repository.
#
# Usage:
#   bash scaffold.sh --name <marketplace-name> [options]
#
# Options:
#   --name          Marketplace id (kebab-case). REQUIRED.
#   --plugin-name   Plugin id (kebab-case).            Default: <name>
#   --description   One-line marketplace description.  Default: derived from name
#   --owner-name    Owner display name.                Default: "Your Name"
#   --owner-email   Owner email.                       Default: "you@example.com"
#   --version       Initial version (semver).          Default: 0.1.0
#   --target-dir    Where to write the repo.           Default: ./<name>
#   --force         Overwrite a non-empty target dir.
#
# Files-only: does NOT run git or touch any remote. Portable to macOS bash 3.2.
set -euo pipefail

# --- locate skill root / templates ---------------------------------------
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATES="$SKILL_ROOT/references/templates"
VALIDATOR="$SKILL_ROOT/scripts/validate-skill.sh"

if [ ! -d "$TEMPLATES" ]; then
  echo "ERROR: templates directory not found at $TEMPLATES" >&2
  exit 1
fi

# --- defaults + arg parsing ----------------------------------------------
NAME=""
PLUGIN_NAME=""
DESCRIPTION=""
OWNER_NAME="Your Name"
OWNER_EMAIL="you@example.com"
VERSION="0.1.0"
TARGET_DIR=""
FORCE=0

while [ $# -gt 0 ]; do
  case "$1" in
    --name)         NAME="${2:-}"; shift 2 ;;
    --plugin-name)  PLUGIN_NAME="${2:-}"; shift 2 ;;
    --description)  DESCRIPTION="${2:-}"; shift 2 ;;
    --owner-name)   OWNER_NAME="${2:-}"; shift 2 ;;
    --owner-email)  OWNER_EMAIL="${2:-}"; shift 2 ;;
    --version)      VERSION="${2:-}"; shift 2 ;;
    --target-dir)   TARGET_DIR="${2:-}"; shift 2 ;;
    --force)        FORCE=1; shift ;;
    -h|--help)      sed -n '2,20p' "$0"; exit 0 ;;
    *) echo "ERROR: unknown argument: $1" >&2; exit 2 ;;
  esac
done

if [ -z "$NAME" ]; then
  echo "ERROR: --name is required" >&2
  exit 2
fi
if ! printf '%s' "$NAME" | grep -Eq '^[a-z0-9]+(-[a-z0-9]+)*$'; then
  echo "ERROR: --name '$NAME' must be kebab-case (lowercase, digits, hyphens)" >&2
  exit 2
fi

[ -z "$PLUGIN_NAME" ] && PLUGIN_NAME="$NAME"
[ -z "$DESCRIPTION" ] && DESCRIPTION="Claude Code skills and agents for $NAME"
[ -z "$TARGET_DIR" ] && TARGET_DIR="./$NAME"

# --- overwrite guard ------------------------------------------------------
if [ -d "$TARGET_DIR" ] && [ -n "$(ls -A "$TARGET_DIR" 2>/dev/null)" ]; then
  if [ "$FORCE" -ne 1 ]; then
    echo "ERROR: target dir '$TARGET_DIR' exists and is not empty. Use --force to overwrite." >&2
    exit 1
  fi
fi
mkdir -p "$TARGET_DIR"

# --- render helper --------------------------------------------------------
# Escape a value for use in a sed replacement with '|' as delimiter.
sed_escape() {
  printf '%s' "$1" | sed -e 's/[\\&|]/\\&/g'
}
E_MARKETPLACE_NAME="$(sed_escape "$NAME")"
E_PLUGIN_NAME="$(sed_escape "$PLUGIN_NAME")"
E_DESCRIPTION="$(sed_escape "$DESCRIPTION")"
E_OWNER_NAME="$(sed_escape "$OWNER_NAME")"
E_OWNER_EMAIL="$(sed_escape "$OWNER_EMAIL")"
E_VERSION="$(sed_escape "$VERSION")"

render() {
  # $1 = template (relative to $TEMPLATES), $2 = dest (relative to $TARGET_DIR)
  local src="$TEMPLATES/$1" dest="$TARGET_DIR/$2"
  mkdir -p "$(dirname "$dest")"
  sed \
    -e "s|{{MARKETPLACE_NAME}}|$E_MARKETPLACE_NAME|g" \
    -e "s|{{PLUGIN_NAME}}|$E_PLUGIN_NAME|g" \
    -e "s|{{DESCRIPTION}}|$E_DESCRIPTION|g" \
    -e "s|{{OWNER_NAME}}|$E_OWNER_NAME|g" \
    -e "s|{{OWNER_EMAIL}}|$E_OWNER_EMAIL|g" \
    -e "s|{{VERSION}}|$E_VERSION|g" \
    "$src" > "$dest"
}

# --- render all templates (template -> destination) ----------------------
render "claude-plugin/marketplace.json"         ".claude-plugin/marketplace.json"
render "claude-plugin/plugin.json"              ".claude-plugin/plugin.json"
render "github/workflows/release.yml"           ".github/workflows/release.yml"
render "github/workflows/pr-scope-check.yml"    ".github/workflows/pr-scope-check.yml"
render "github/PULL_REQUEST_TEMPLATE.md"        ".github/PULL_REQUEST_TEMPLATE.md"
render "hooks/hooks.json"                        "hooks/hooks.json"
render "hooks/scripts/recommend-skills.sh"       "hooks/scripts/recommend-skills.sh"
render "hooks/README.md"                         "hooks/README.md"
render "skills/example-tool-skill/SKILL.md"      "skills/example-tool-skill/SKILL.md"
render "scripts/update-plugin-versions.sh"       "scripts/update-plugin-versions.sh"
render "releaserc.json"                          ".releaserc.json"
render "CLAUDE.md"                               "CLAUDE.md"
render "CONTRIBUTING.md"                         "CONTRIBUTING.md"
render "README.md"                               "README.md"
render "gitignore"                               ".gitignore"

# --- copy the validator verbatim (no placeholders) -----------------------
mkdir -p "$TARGET_DIR/scripts"
cp "$VALIDATOR" "$TARGET_DIR/scripts/validate-skill.sh"

# --- make scripts executable ---------------------------------------------
chmod +x \
  "$TARGET_DIR/scripts/validate-skill.sh" \
  "$TARGET_DIR/scripts/update-plugin-versions.sh" \
  "$TARGET_DIR/hooks/scripts/recommend-skills.sh" 2>/dev/null || true

# --- done -----------------------------------------------------------------
echo "Scaffolded '$NAME' marketplace at: $TARGET_DIR"
echo ""
echo "Next steps:"
echo "  1. cd $TARGET_DIR"
echo "  2. git init && git add -A && git commit -m 'chore: initial marketplace scaffold'"
echo "  3. Create the GitHub repo and push."
echo "  4. Test locally:  claude --plugin-dir \"\$(pwd)\"   then run /skills"
echo "  5. Validate the sample:  bash scripts/validate-skill.sh skills/example-tool-skill"
