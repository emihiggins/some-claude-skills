#!/bin/bash
# Parse test-results.md and produce a JSON summary.
# Used by the orchestrator to make routing decisions without reading the full file.
#
# Usage: summarize-tests.sh <test-results-md-path>
#
# Output: JSON on stdout

set -euo pipefail

TEST_FILE="${1:?Missing test-results.md path}"

if [[ ! -f "$TEST_FILE" ]]; then
  echo '{"error": "test-results.md not found", "exists": false}'
  exit 1
fi

python3 -c "
import re, json, sys

with open('$TEST_FILE') as f:
    content = f.read()

# Extract decision from '## Decision: PASS'
decision_match = re.search(r'##\s*Decision:\s*(\w+)', content)
decision = decision_match.group(1) if decision_match else 'unknown'

# Count passed criteria ([x] items under ### Passed)
passed_section = re.search(r'###\s*Passed\s*\n(.*?)(?=\n###|\n##|\Z)', content, re.DOTALL | re.IGNORECASE)
passed_count = len(re.findall(r'\[x\]', passed_section.group(1), re.IGNORECASE)) if passed_section else 0

# Count failed criteria ([ ] items under ### Failed)
failed_section = re.search(r'###\s*Failed\s*\n(.*?)(?=\n###|\n##|\Z)', content, re.DOTALL | re.IGNORECASE)
failed_count = len(re.findall(r'\[ \]', failed_section.group(1))) if failed_section else 0

# Count not-tested criteria
not_tested_section = re.search(r'###\s*Not Tested\s*\n(.*?)(?=\n###|\n##|\Z)', content, re.DOTALL | re.IGNORECASE)
not_tested_count = len(re.findall(r'\[ \]', not_tested_section.group(1))) if not_tested_section else 0

# Also try to extract from 'Passed: N' / 'Failed: N' in automated section
auto_passed = re.search(r'Passed:\s*(\d+)', content)
auto_failed = re.search(r'Failed:\s*(\d+)', content)
auto_total = re.search(r'Total:\s*(\d+)', content)

total = passed_count + failed_count + not_tested_count

print(json.dumps({
    'exists': True,
    'decision': decision,
    'passed_count': passed_count,
    'failed_count': failed_count,
    'not_tested_count': not_tested_count,
    'total_criteria': total,
    'automated_tests': {
        'passed': int(auto_passed.group(1)) if auto_passed else None,
        'failed': int(auto_failed.group(1)) if auto_failed else None,
        'total': int(auto_total.group(1)) if auto_total else None
    }
}, indent=2))
" 2>/dev/null || echo '{"error": "Failed to parse test-results.md", "exists": true}'
