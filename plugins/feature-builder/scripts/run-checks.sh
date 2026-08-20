#!/bin/bash
# Run all project checks (lint, type check, tests) in one invocation.
# Reduces permission prompts by combining what would be multiple Bash tool calls.
#
# Usage: run-checks.sh [working-dir]
#   working-dir: Project root (defaults to current directory)
#
# Output: JSON summary on stdout
# Exit code: 0 if all pass, 1 if any fail

set -euo pipefail

WORKING_DIR="${1:-.}"
cd "$WORKING_DIR"

# Results tracking
LINT_STATUS="skipped"
LINT_OUTPUT=""
TYPECHECK_STATUS="skipped"
TYPECHECK_OUTPUT=""
TEST_STATUS="skipped"
TEST_OUTPUT=""

# Detect project type
detect_project() {
  if [[ -f "package.json" ]]; then
    echo "node"
  elif [[ -f "pom.xml" ]]; then
    echo "maven"
  elif [[ -f "build.gradle" ]] || [[ -f "build.gradle.kts" ]]; then
    echo "gradle"
  elif [[ -f "requirements.txt" ]] || [[ -f "pyproject.toml" ]]; then
    echo "python"
  else
    echo "unknown"
  fi
}

# Run a command and capture output + exit code
run_check() {
  local output
  local exit_code
  output=$(eval "$1" 2>&1) && exit_code=0 || exit_code=$?
  echo "$output"
  return $exit_code
}

# Check if npm script exists
has_npm_script() {
  node -e "const p=require('./package.json'); process.exit(p.scripts && p.scripts['$1'] ? 0 : 1)" 2>/dev/null
}

PROJECT_TYPE=$(detect_project)

case "$PROJECT_TYPE" in
  node)
    # Detect package manager
    if [[ -f "pnpm-lock.yaml" ]]; then
      PM="pnpm"
    elif [[ -f "yarn.lock" ]]; then
      PM="yarn"
    elif [[ -f "bun.lockb" ]]; then
      PM="bun"
    else
      PM="npm"
    fi

    # Lint
    for script in "lint" "test:lint"; do
      if has_npm_script "$script"; then
        LINT_OUTPUT=$(run_check "$PM run $script" 2>&1) && LINT_STATUS="pass" || LINT_STATUS="fail"
        break
      fi
    done

    # Type check
    for script in "type-check" "typecheck" "tsc"; do
      if has_npm_script "$script"; then
        TYPECHECK_OUTPUT=$(run_check "$PM run $script" 2>&1) && TYPECHECK_STATUS="pass" || TYPECHECK_STATUS="fail"
        break
      fi
    done

    # Tests
    for script in "test" "test:unit" "test:ci"; do
      if has_npm_script "$script"; then
        TEST_OUTPUT=$(run_check "$PM run $script" 2>&1) && TEST_STATUS="pass" || TEST_STATUS="fail"
        break
      fi
    done
    ;;

  maven)
    # Full build including integration tests
    TEST_OUTPUT=$(run_check "mvn clean install" 2>&1) && TEST_STATUS="pass" || TEST_STATUS="fail"
    LINT_STATUS="n/a"
    TYPECHECK_STATUS="n/a"
    ;;

  gradle)
    TEST_OUTPUT=$(run_check "./gradlew clean build" 2>&1) && TEST_STATUS="pass" || TEST_STATUS="fail"
    LINT_STATUS="n/a"
    TYPECHECK_STATUS="n/a"
    ;;

  python)
    # Lint
    if command -v ruff &>/dev/null; then
      LINT_OUTPUT=$(run_check "ruff check ." 2>&1) && LINT_STATUS="pass" || LINT_STATUS="fail"
    fi

    # Type check
    if command -v mypy &>/dev/null; then
      TYPECHECK_OUTPUT=$(run_check "mypy ." 2>&1) && TYPECHECK_STATUS="pass" || TYPECHECK_STATUS="fail"
    fi

    # Tests
    if command -v pytest &>/dev/null; then
      TEST_OUTPUT=$(run_check "pytest" 2>&1) && TEST_STATUS="pass" || TEST_STATUS="fail"
    fi
    ;;

  *)
    echo '{"error": "Unknown project type", "project_type": "unknown"}'
    exit 1
    ;;
esac

# Determine overall status
OVERALL="pass"
if [[ "$LINT_STATUS" == "fail" ]] || [[ "$TYPECHECK_STATUS" == "fail" ]] || [[ "$TEST_STATUS" == "fail" ]]; then
  OVERALL="fail"
fi

# Truncate long outputs for JSON (keep last 100 lines)
truncate_output() {
  echo "$1" | tail -100 | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g'
}

# Output JSON summary
cat <<EOF
{
  "overall": "$OVERALL",
  "project_type": "$PROJECT_TYPE",
  "lint": {
    "status": "$LINT_STATUS",
    "output": "$(truncate_output "$LINT_OUTPUT")"
  },
  "typecheck": {
    "status": "$TYPECHECK_STATUS",
    "output": "$(truncate_output "$TYPECHECK_OUTPUT")"
  },
  "tests": {
    "status": "$TEST_STATUS",
    "output": "$(truncate_output "$TEST_OUTPUT")"
  }
}
EOF

[[ "$OVERALL" == "pass" ]] && exit 0 || exit 1
