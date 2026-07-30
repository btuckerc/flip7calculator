#!/usr/bin/env bash
set -euo pipefail

result_path="${1:-}"
if [[ -z "$result_path" ]]; then
  echo "Usage: scripts/xcresult-summary.sh <result.xcresult>" >&2
  exit 1
fi

if [[ ! -d "$result_path" ]]; then
  echo "Result bundle not found: $result_path" >&2
  exit 1
fi

summary="$(xcrun xcresulttool get test-results summary --path "$result_path")"

if command -v jq >/dev/null 2>&1; then
  jq -r '
    "Result: \(.result)",
    "Tests: \(.totalTestCount) total, \(.passedTests) passed, \(.failedTests) failed, \(.skippedTests) skipped, \(.expectedFailures) expected failures",
    "Environment: \(.environmentDescription)",
    (if (.testFailures | length) > 0 then
      "Failures:",
      (.testFailures[] | "- \(.testIdentifierString): \(.failureText)")
    else empty end)
  ' <<<"$summary"
else
  printf '%s\n' "$summary"
fi
