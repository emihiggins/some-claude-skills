#!/usr/bin/env bash
# Validate a Claude Code skill directory against this marketplace's conventions.
#
# Usage: bash scripts/validate-skill.sh skills/<name>
#
# Prints ERRORs (block) and WARNINGs (advisory). Exits non-zero if any ERROR.
# Written to be portable to macOS bash 3.2 (no associative arrays, no ${x^^}).
set -uo pipefail

SKILL_DIR="${1:-}"
if [ -z "$SKILL_DIR" ]; then
  echo "Usage: $0 skills/<name>" >&2
  exit 2
fi
SKILL_DIR="${SKILL_DIR%/}"

ERRORS=0
WARNINGS=0
err()  { echo "ERROR:   $1"; ERRORS=$((ERRORS + 1)); }
warn() { echo "WARNING: $1"; WARNINGS=$((WARNINGS + 1)); }

KEBAB='^[a-z0-9]+(-[a-z0-9]+)*$'

# --- directory + entry point ---------------------------------------------
if [ ! -d "$SKILL_DIR" ]; then
  err "not a directory: $SKILL_DIR"
  echo ""; echo "$ERRORS error(s), $WARNINGS warning(s)."; exit 1
fi

FOLDER="$(basename "$SKILL_DIR")"
if ! printf '%s' "$FOLDER" | grep -Eq "$KEBAB"; then
  err "folder name '$FOLDER' is not kebab-case"
fi

SKILL_MD="$SKILL_DIR/SKILL.md"
if [ ! -f "$SKILL_MD" ]; then
  err "missing SKILL.md (case-sensitive) in $SKILL_DIR"
  echo ""; echo "$ERRORS error(s), $WARNINGS warning(s)."; exit 1
fi

if [ -f "$SKILL_DIR/README.md" ]; then
  err "skill folders must not contain a README.md (use SKILL.md only)"
fi

# --- frontmatter ----------------------------------------------------------
FIRST_LINE="$(head -n1 "$SKILL_MD")"
if [ "$FIRST_LINE" != "---" ]; then
  err "SKILL.md must start with a YAML frontmatter delimiter '---'"
  echo ""; echo "$ERRORS error(s), $WARNINGS warning(s)."; exit 1
fi

FM="$(awk '/^---[[:space:]]*$/{c++; next} c==1{print} c>=2{exit}' "$SKILL_MD")"
if [ -z "$FM" ]; then
  err "SKILL.md frontmatter is empty or has no closing '---'"
  echo ""; echo "$ERRORS error(s), $WARNINGS warning(s)."; exit 1
fi

# name
NAME="$(printf '%s\n' "$FM" | awk -F': *' '/^name:/{print $2; exit}')"
if [ -z "$NAME" ]; then
  err "frontmatter is missing required 'name'"
else
  if ! printf '%s' "$NAME" | grep -Eq "$KEBAB"; then
    err "name '$NAME' is not kebab-case"
  fi
  if [ "$NAME" != "$FOLDER" ]; then
    err "name '$NAME' must match folder name '$FOLDER'"
  fi
  case "$NAME" in
    claude*|anthropic*) err "name '$NAME' must not start with 'claude' or 'anthropic'" ;;
  esac
fi

# description (may be folded with '>')
DESC="$(printf '%s\n' "$FM" | awk '
  /^description:/ {cap=1; sub(/^description:[[:space:]]*>?[[:space:]]*/,""); if($0!="") print; next}
  cap && /^[[:space:]]+/ {sub(/^[[:space:]]+/,""); print; next}
  cap && /^[^[:space:]]/ {cap=0}
')"
if [ -z "$DESC" ]; then
  err "frontmatter is missing required 'description'"
else
  DESC_ONELINE="$(printf '%s' "$DESC" | tr '\n' ' ')"
  DLEN="$(printf '%s' "$DESC_ONELINE" | wc -c | tr -d ' ')"
  if [ "$DLEN" -gt 1024 ]; then
    err "description is $DLEN chars (max 1024)"
  fi
  if ! printf '%s' "$DESC_ONELINE" | grep -qi "use when"; then
    warn "description should include \"Use when ...\" trigger phrases"
  fi
  if ! printf '%s' "$DESC_ONELINE" | grep -qi "not for"; then
    warn "description should include \"NOT for ...\" negative triggers"
  fi
fi

# version (optional; if present must be semver)
VERSION="$(printf '%s\n' "$FM" | awk -F': *' '/^version:/{print $2; exit}')"
if [ -n "$VERSION" ]; then
  if ! printf '%s' "$VERSION" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+'; then
    warn "version '$VERSION' is not semver (x.y.z)"
  fi
fi

# --- category prefix (advisory) ------------------------------------------
case "$FOLDER" in
  tool-*|workflow-*|code-*) : ;;
  *)
    warn "'$FOLDER' has no known category prefix (tool-, workflow-, code-); ok if this is an atomic utility skill" ;;
esac

# --- required sections ----------------------------------------------------
case "$FOLDER" in
  workflow-*)
    if ! grep -Eq '^##[[:space:]]+(Workflow|Phases)\b' "$SKILL_MD"; then
      err "workflow skills must have a '## Workflow' or '## Phases' section"
    fi ;;
esac
grep -Eq '^##[[:space:]]+Prerequisites\b' "$SKILL_MD" || warn "consider adding a '## Prerequisites' section"
grep -Eq '^##[[:space:]]+Error Handling\b' "$SKILL_MD" || warn "consider adding a '## Error Handling' section"

# --- length ---------------------------------------------------------------
LINES="$(wc -l < "$SKILL_MD" | tr -d ' ')"
if [ "$LINES" -gt 500 ]; then
  warn "SKILL.md is $LINES lines (>500); move detail into references/"
fi

# --- raw XML/HTML tags in prose (outside code fences) --------------------
XML_HITS="$(awk '
  /^```/ {infence = !infence; next}
  infence {next}
  {
    line = $0
    gsub(/`[^`]*`/, "", line)   # ignore inline code spans
    if (line ~ /<[a-zA-Z\/]/) print NR": "$0
  }
' "$SKILL_MD")"
if [ -n "$XML_HITS" ]; then
  warn "raw XML/HTML-like tags found in prose (Agent Skills prefer plain markdown):"
  printf '%s\n' "$XML_HITS" | sed 's/^/           /'
fi

# --- orphan scripts -------------------------------------------------------
if [ -d "$SKILL_DIR/scripts" ]; then
  for s in "$SKILL_DIR/scripts"/*; do
    [ -f "$s" ] || continue
    base="$(basename "$s")"
    if ! grep -q "$base" "$SKILL_MD"; then
      warn "script '$base' is not referenced in SKILL.md (possible orphan)"
    fi
    case "$base" in
      *_*) warn "script '$base' uses underscores; prefer kebab-case" ;;
    esac
  done
fi

echo ""
echo "$ERRORS error(s), $WARNINGS warning(s)."
[ "$ERRORS" -eq 0 ]
