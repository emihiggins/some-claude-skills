#!/bin/bash
# Detect project type, build tool, and package manager.
# Used by agents to avoid repeated detection logic.
#
# Usage: detect-project.sh [working-dir]
#
# Output: JSON on stdout

set -euo pipefail

WORKING_DIR="${1:-.}"
cd "$WORKING_DIR"

PROJECT_TYPE="unknown"
BUILD_TOOL="unknown"
PACKAGE_MANAGER="unknown"
TEST_COMMAND="unknown"
LINT_COMMAND="unknown"

# Check if npm script exists
has_npm_script() {
  node -e "const p=require('./package.json'); process.exit(p.scripts && p.scripts['$1'] ? 0 : 1)" 2>/dev/null
}

if [[ -f "package.json" ]]; then
  # Detect package manager
  if [[ -f "pnpm-lock.yaml" ]]; then
    PACKAGE_MANAGER="pnpm"
  elif [[ -f "yarn.lock" ]]; then
    PACKAGE_MANAGER="yarn"
  elif [[ -f "bun.lockb" ]]; then
    PACKAGE_MANAGER="bun"
  else
    PACKAGE_MANAGER="npm"
  fi

  BUILD_TOOL="$PACKAGE_MANAGER"

  # Detect project type from dependencies
  if node -e "const p=require('./package.json'); const d={...p.dependencies,...p.devDependencies}; process.exit(d.react || d['@angular/core'] || d.vue ? 0 : 1)" 2>/dev/null; then
    PROJECT_TYPE="ui"
  elif node -e "const p=require('./package.json'); const d={...p.dependencies,...p.devDependencies}; process.exit(d['apollo-server'] || d['@apollo/server'] || d['graphql-yoga'] || d.nexus ? 0 : 1)" 2>/dev/null; then
    PROJECT_TYPE="graphql"
  elif node -e "const p=require('./package.json'); const d={...p.dependencies,...p.devDependencies}; process.exit(d.express || d['@hapi/hapi'] || d.fastify || d.koa ? 0 : 1)" 2>/dev/null; then
    PROJECT_TYPE="api"
  else
    PROJECT_TYPE="node"
  fi

  # Detect test command
  for script in "test" "test:unit" "test:ci"; do
    if has_npm_script "$script"; then
      TEST_COMMAND="$PACKAGE_MANAGER run $script"
      break
    fi
  done

  # Detect lint command
  for script in "lint" "test:lint"; do
    if has_npm_script "$script"; then
      LINT_COMMAND="$PACKAGE_MANAGER run $script"
      break
    fi
  done

elif [[ -f "pom.xml" ]]; then
  PROJECT_TYPE="api"
  BUILD_TOOL="maven"
  PACKAGE_MANAGER="mvn"
  TEST_COMMAND="mvn clean install"
  LINT_COMMAND="n/a"

elif [[ -f "build.gradle" ]] || [[ -f "build.gradle.kts" ]]; then
  PROJECT_TYPE="api"
  BUILD_TOOL="gradle"
  PACKAGE_MANAGER="gradle"
  TEST_COMMAND="./gradlew clean build"
  LINT_COMMAND="n/a"

elif [[ -f "requirements.txt" ]] || [[ -f "pyproject.toml" ]]; then
  PROJECT_TYPE="api"
  BUILD_TOOL="python"
  PACKAGE_MANAGER="pip"
  if command -v pytest &>/dev/null; then
    TEST_COMMAND="pytest"
  fi
  if command -v ruff &>/dev/null; then
    LINT_COMMAND="ruff check ."
  fi
fi

cat <<EOF
{
  "project_type": "$PROJECT_TYPE",
  "build_tool": "$BUILD_TOOL",
  "package_manager": "$PACKAGE_MANAGER",
  "test_command": "$TEST_COMMAND",
  "lint_command": "$LINT_COMMAND"
}
EOF
