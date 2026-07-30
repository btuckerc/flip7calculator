#!/usr/bin/env bash
set -uo pipefail

PROJECT="${PROJECT:-flip7calculator.xcodeproj}"
SCHEME="${SCHEME:-flip7calculator}"
SIMULATOR_NAME="${SIMULATOR_NAME:-iPhone 16}"
SIMULATOR_OS="${SIMULATOR_OS:-latest}"
CACHE_ROOT="${CACHE_ROOT:-$HOME/Library/Caches/FlippingSevenCalculator}"

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=load-asc-credentials.sh
source "$script_dir/load-asc-credentials.sh"

errors=0
warnings=0

pass() { printf 'PASS  %s\n' "$1"; }
info() { printf 'INFO  %s\n' "$1"; }
warn() { printf 'WARN  %s\n' "$1"; warnings=$((warnings + 1)); }
fail() { printf 'FAIL  %s\n' "$1"; errors=$((errors + 1)); }

if [[ "$(uname -s)" == "Darwin" ]]; then
  pass "macOS host"
else
  fail "Apple builds require macOS"
fi

for tool in xcodebuild xcrun make git jq; do
  if command -v "$tool" >/dev/null 2>&1; then
    pass "$tool available"
  else
    fail "$tool is required"
  fi
done

if command -v xcodebuild >/dev/null 2>&1; then
  xcode_version="$(xcodebuild -version 2>/dev/null | head -1 | awk '{print $2}')"
  xcode_major="${xcode_version%%.*}"
  if [[ "$xcode_major" =~ ^[0-9]+$ ]] && (( xcode_major >= 26 )); then
    pass "Xcode $xcode_version meets the current App Store SDK floor"
  else
    fail "Xcode 26 or newer is required for current App Store uploads (found ${xcode_version:-unknown})"
  fi
fi

if command -v xcbeautify >/dev/null 2>&1; then
  pass "xcbeautify available ($(xcbeautify --version 2>/dev/null || echo unknown))"
else
  warn "xcbeautify is optional but strongly recommended for readable agent logs"
fi

if [[ -d "$PROJECT" ]]; then
  pass "project exists at $PROJECT"
else
  fail "project not found at $PROJECT"
fi

if command -v xcodebuild >/dev/null 2>&1 && [[ -d "$PROJECT" ]]; then
  if xcodebuild -list -json -project "$PROJECT" 2>/dev/null \
      | jq -e --arg scheme "$SCHEME" '.project.schemes | index($scheme)' >/dev/null; then
    pass "scheme '$SCHEME' is discoverable"
  else
    fail "scheme '$SCHEME' is not discoverable"
  fi
fi

if command -v jq >/dev/null 2>&1 && command -v xcrun >/dev/null 2>&1; then
  if destination="$($script_dir/find-simulator.sh "$SIMULATOR_NAME" "$SIMULATOR_OS" destination 2>/dev/null)"; then
    pass "simulator destination resolved ($destination)"
  else
    fail "no simulator matched '$SIMULATOR_NAME' / '$SIMULATOR_OS'; run 'make destinations'"
  fi
fi

if mkdir -p "$CACHE_ROOT" && touch "$CACHE_ROOT/.write-test" 2>/dev/null; then
  rm -f "$CACHE_ROOT/.write-test"
  pass "cache root is writable ($CACHE_ROOT)"
else
  fail "cache root is not writable ($CACHE_ROOT)"
fi

if xcrun --find mcpbridge >/dev/null 2>&1; then
  pass "Apple Xcode MCP bridge is installed"
  info "Open the project in Xcode and enable external-agent access before using the bridge"
else
  info "Xcode MCP bridge unavailable; use Make/xcodebuild (the native bridge requires Xcode 26.3+)"
fi

release_vars=(ASC_KEY_ID ASC_ISSUER_ID ASC_KEY_PATH)
release_count=0
for variable in "${release_vars[@]}"; do
  [[ -n "${!variable:-}" ]] && release_count=$((release_count + 1))
done

if (( release_count == 0 )); then
  info "App Store Connect credentials are not loaded; simulator work is unaffected"
elif (( release_count != ${#release_vars[@]} )); then
  warn "App Store Connect credentials are incomplete; set ASC_KEY_ID, ASC_ISSUER_ID, and ASC_KEY_PATH together"
elif [[ ! -f "$ASC_KEY_PATH" ]]; then
  fail "ASC_KEY_PATH does not point to a file"
else
  pass "App Store Connect credential variables are complete (secret values not printed)"
fi

dirty_count="$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
if [[ "$dirty_count" == "0" ]]; then
  pass "git worktree is clean"
else
  info "git worktree has $dirty_count changed paths; preserve them and do not archive without explicit release intent"
fi

printf '\nDoctor finished with %d error(s) and %d warning(s).\n' "$errors" "$warnings"
(( errors == 0 ))
