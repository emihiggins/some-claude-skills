#!/bin/bash
# Parse review.md and produce a JSON summary with issue counts by severity.
# Used by the orchestrator to make routing decisions without reading the full file.
#
# Usage: summarize-review.sh <review-md-path>
#
# Output: JSON on stdout

set -euo pipefail

REVIEW_FILE="${1:?Missing review.md path}"

if [[ ! -f "$REVIEW_FILE" ]]; then
  echo '{"error": "review.md not found", "exists": false}'
  exit 1
fi

python3 -c "
import re, json, sys

with open('$REVIEW_FILE') as f:
    content = f.read()

# Extract decision from '## Decision: PASS' or '## Decision: NEEDS_WORK'
decision_match = re.search(r'##\s*Decision:\s*(\w+)', content)
decision = decision_match.group(1) if decision_match else 'unknown'

# Count findings by severity section
# Each finding is a numbered or bulleted item under the severity heading
def count_in_section(heading):
    pattern = r'###\s*' + heading + r'.*?\n(.*?)(?=\n###|\n##|\Z)'
    match = re.search(pattern, content, re.DOTALL | re.IGNORECASE)
    if not match:
        return 0
    section = match.group(1)
    # Count lines that start with - or a number (findings)
    findings = [l for l in section.strip().split('\n') if re.match(r'\s*[-*\d]', l.strip()) and l.strip() not in ['-', '*']]
    return len(findings)

critical = count_in_section('CRITICAL')
major = count_in_section('MAJOR')
minor = count_in_section('MINOR')

print(json.dumps({
    'exists': True,
    'decision': decision,
    'critical_count': critical,
    'major_count': major,
    'minor_count': minor,
    'total_issues': critical + major + minor,
    'blocking': critical > 0
}, indent=2))
" 2>/dev/null || echo '{"error": "Failed to parse review.md", "exists": true}'
