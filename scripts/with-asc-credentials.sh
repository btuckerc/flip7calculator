#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=load-asc-credentials.sh
source "$script_dir/load-asc-credentials.sh"

: "${ASC_KEY_ID:?App Store Connect key ID is unavailable in the environment or Keychain}"
: "${ASC_ISSUER_ID:?App Store Connect issuer ID is unavailable in the environment or Keychain}"
: "${ASC_KEY_PATH:?App Store Connect key path is unavailable in the environment or Keychain}"
[[ -f "$ASC_KEY_PATH" ]] || { echo "App Store Connect private key is unavailable" >&2; exit 1; }
[[ "$(stat -f '%Lp' "$ASC_KEY_PATH")" == "600" ]] \
  || { echo "App Store Connect private key must have 0600 permissions" >&2; exit 1; }
openssl pkey -in "$ASC_KEY_PATH" -check -noout >/dev/null 2>&1 \
  || { echo "App Store Connect private key is invalid" >&2; exit 1; }

if [[ "${1:-}" == "--check" ]]; then
  echo "App Store Connect credentials loaded from secure local storage (values hidden)."
  exit 0
fi

(( $# > 0 )) || { echo "Usage: scripts/with-asc-credentials.sh <command> [arguments...]" >&2; exit 1; }
exec "$@"

