#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: scripts/xcode-task.sh <build|test> [extra xcodebuild args...]" >&2
  exit 1
fi

action="$1"
shift

PROJECT="${PROJECT:-flip7calculator.xcodeproj}"
SCHEME="${SCHEME:-flip7calculator}"
CONFIGURATION="${CONFIGURATION:-Debug}"
SIMULATOR_NAME="${SIMULATOR_NAME:-iPhone 16}"
SIMULATOR_OS="${SIMULATOR_OS:-latest}"
CACHE_ROOT="${CACHE_ROOT:-$HOME/Library/Caches/LuckyLedger}"
DERIVED_DATA="${DERIVED_DATA:-$CACHE_ROOT/DerivedData}"
RESULT_BUNDLE="${RESULT_BUNDLE:-}"

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
destination="$("$script_dir/find-simulator.sh" "$SIMULATOR_NAME" "$SIMULATOR_OS" destination)"

cmd=(
  xcodebuild "$action"
  -project "$PROJECT"
  -scheme "$SCHEME"
  -configuration "$CONFIGURATION"
  -destination "$destination"
  -derivedDataPath "$DERIVED_DATA"
  CODE_SIGNING_ALLOWED=NO
  CODE_SIGNING_REQUIRED=NO
)

if [[ "$action" == "test" && -n "$RESULT_BUNDLE" ]]; then
  mkdir -p "$(dirname "$RESULT_BUNDLE")"
  rm -rf "$RESULT_BUNDLE"
  cmd+=(-resultBundlePath "$RESULT_BUNDLE")
fi

if [[ $# -gt 0 ]]; then
  cmd+=("$@")
fi

formatter=(cat)
if command -v xcbeautify >/dev/null 2>&1; then
  formatter=(xcbeautify)
fi

echo "Using destination: $destination"
echo "Running: ${cmd[*]}"

set -o pipefail
"${cmd[@]}" | "${formatter[@]}"
