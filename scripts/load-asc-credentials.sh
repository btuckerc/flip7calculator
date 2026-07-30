#!/usr/bin/env bash

# Load App Store Connect credentials from this Mac's login Keychain without
# exposing their values in the repository or ordinary command output.

ASC_KEYCHAIN_SERVICE_PREFIX="${ASC_KEYCHAIN_SERVICE_PREFIX:-com.tcraig.flipping-seven.app-store-connect}"
ASC_KEYCHAIN_ACCOUNT="${ASC_KEYCHAIN_ACCOUNT:-${USER:-}}"

if [[ "$(uname -s)" != "Darwin" || -z "$ASC_KEYCHAIN_ACCOUNT" ]] \
    || ! command -v security >/dev/null 2>&1; then
  return 0 2>/dev/null || exit 0
fi

asc_keychain_value() {
  security find-generic-password \
    -a "$ASC_KEYCHAIN_ACCOUNT" \
    -s "$ASC_KEYCHAIN_SERVICE_PREFIX.$1" \
    -w 2>/dev/null
}

key_path_from_keychain=NO

if [[ -z "${ASC_KEY_ID:-}" ]]; then
  ASC_KEY_ID="$(asc_keychain_value key-id || true)"
fi
if [[ -z "${ASC_ISSUER_ID:-}" ]]; then
  ASC_ISSUER_ID="$(asc_keychain_value issuer-id || true)"
fi
if [[ -z "${ASC_KEY_PATH:-}" ]]; then
  ASC_KEY_PATH="$(asc_keychain_value key-path || true)"
  [[ -z "$ASC_KEY_PATH" ]] || key_path_from_keychain=YES
fi

# The operational file is backed up in Keychain because Apple only provides
# the private-key download once. Restore it only when using the stored path.
if [[ "$key_path_from_keychain" == "YES" && -n "$ASC_KEY_PATH" && ! -f "$ASC_KEY_PATH" ]]; then
  encoded_key="$(asc_keychain_value private-key-p8-base64 || true)"
  if [[ -n "$encoded_key" ]]; then
    key_directory="$(dirname "$ASC_KEY_PATH")"
    temporary_key="$ASC_KEY_PATH.tmp.$$"
    umask 077
    mkdir -p "$key_directory"
    chmod 700 "$key_directory"
    printf '%s' "$encoded_key" | /usr/bin/base64 -D > "$temporary_key"
    if openssl pkey -in "$temporary_key" -check -noout >/dev/null 2>&1; then
      chmod 600 "$temporary_key"
      mv "$temporary_key" "$ASC_KEY_PATH"
    else
      rm -f "$temporary_key"
    fi
  fi
  unset encoded_key key_directory temporary_key
fi

export ASC_KEY_ID ASC_ISSUER_ID ASC_KEY_PATH
unset key_path_from_keychain

