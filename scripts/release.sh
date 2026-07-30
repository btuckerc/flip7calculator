#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=load-asc-credentials.sh
source "$script_dir/load-asc-credentials.sh"

action="${1:-}"
if [[ -z "$action" ]]; then
  echo "Usage: scripts/release.sh <preflight|archive|export|validate|upload>" >&2
  exit 1
fi

PROJECT="${PROJECT:-flip7calculator.xcodeproj}"
SCHEME="${SCHEME:-flip7calculator}"
CONFIGURATION="${CONFIGURATION:-Release}"
RELEASE_DIR="${RELEASE_DIR:-$HOME/Library/Developer/Xcode/Archives/FlippingSevenCalculator}"
EXPORT_OPTIONS="${EXPORT_OPTIONS:-scripts/ExportOptions-AppStore.plist}"
RELEASE_STATE_FILE="${RELEASE_STATE_FILE:-AppStoreAssets/release-state.json}"

release_settings="$(xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration "$CONFIGURATION" -showBuildSettings 2>/dev/null)"
release_version="$(awk '$1 == "MARKETING_VERSION" && $2 == "=" {print $3; exit}' <<<"$release_settings")"
release_build="$(awk '$1 == "CURRENT_PROJECT_VERSION" && $2 == "=" {print $3; exit}' <<<"$release_settings")"
release_bundle="$(awk '$1 == "PRODUCT_BUNDLE_IDENTIFIER" && $2 == "=" {print $3; exit}' <<<"$release_settings")"
[[ -n "$release_version" && -n "$release_build" && -n "$release_bundle" ]] \
  || { echo "Could not resolve release identity from Xcode build settings." >&2; exit 1; }

release_basename="$SCHEME-$release_version-$release_build"
ARCHIVE_PATH="${ARCHIVE_PATH:-$RELEASE_DIR/$release_basename.xcarchive}"
EXPORT_PATH="${EXPORT_PATH:-$RELEASE_DIR/$release_basename}"

require_clean_release_state() {
  if [[ -n "$(git status --porcelain)" && "${ALLOW_DIRTY_RELEASE:-NO}" != "YES" ]]; then
    echo "Refusing to create a non-reproducible release from a dirty worktree." >&2
    echo "Commit/stash intentionally, or set ALLOW_DIRTY_RELEASE=YES only with explicit approval." >&2
    exit 1
  fi
}

require_new_build_number() {
  [[ -f "$RELEASE_STATE_FILE" ]] || return 0
  command -v jq >/dev/null 2>&1 || { echo "jq is required to inspect $RELEASE_STATE_FILE" >&2; exit 1; }

  local recorded_bundle recorded_version recorded_build
  recorded_bundle="$(jq -er '.bundleId' "$RELEASE_STATE_FILE")"
  recorded_version="$(jq -er '.lastUploaded.version' "$RELEASE_STATE_FILE")"
  recorded_build="$(jq -er '.lastUploaded.build' "$RELEASE_STATE_FILE")"

  if [[ "$recorded_bundle" != "$release_bundle" ]]; then
    echo "Release-state bundle ID does not match the Xcode build." >&2
    exit 1
  fi

  if [[ "$release_version" == "$recorded_version" \
      && "$release_build" =~ ^[0-9]+$ \
      && "$recorded_build" =~ ^[0-9]+$ \
      && "$release_build" -le "$recorded_build" \
      && "${ALLOW_EXISTING_BUILD:-NO}" != "YES" ]]; then
    echo "Build $release_version ($release_build) is not newer than recorded upload $recorded_version ($recorded_build)." >&2
    echo "Increment CURRENT_PROJECT_VERSION, or set ALLOW_EXISTING_BUILD=YES only to reproduce an existing build without uploading it." >&2
    exit 1
  fi
}

require_credentials() {
  : "${ASC_KEY_ID:?Set ASC_KEY_ID without committing it}"
  : "${ASC_ISSUER_ID:?Set ASC_ISSUER_ID without committing it}"
  : "${ASC_KEY_PATH:?Set ASC_KEY_PATH without committing it}"
  [[ -f "$ASC_KEY_PATH" ]] || { echo "ASC_KEY_PATH does not exist" >&2; exit 1; }
}

set_authentication_args() {
  auth=()
  if [[ -n "${ASC_KEY_ID:-}" || -n "${ASC_ISSUER_ID:-}" || -n "${ASC_KEY_PATH:-}" ]]; then
    require_credentials
    auth=(
      -authenticationKeyPath "$ASC_KEY_PATH" \
      -authenticationKeyID "$ASC_KEY_ID" \
      -authenticationKeyIssuerID "$ASC_ISSUER_ID"
    )
  fi
}

run_xcodebuild() {
  local -a formatter=(cat)
  if command -v xcbeautify >/dev/null 2>&1; then
    formatter=(xcbeautify)
  fi
  set -o pipefail
  xcodebuild "$@" | "${formatter[@]}"
}

find_ipa() {
  local ipa
  ipa="$(find "$EXPORT_PATH" -maxdepth 1 -name '*.ipa' -print -quit 2>/dev/null || true)"
  [[ -n "$ipa" ]] || { echo "No IPA found in $EXPORT_PATH; run 'make export' first." >&2; exit 1; }
  printf '%s\n' "$ipa"
}

case "$action" in
  preflight)
    [[ -d "$PROJECT" ]] || { echo "Missing project: $PROJECT" >&2; exit 1; }
    [[ -f "$EXPORT_OPTIONS" ]] || { echo "Missing export options: $EXPORT_OPTIONS" >&2; exit 1; }
    require_clean_release_state
    require_new_build_number
    printf 'Release candidate: %s %s (%s)\n' "$release_bundle" "$release_version" "$release_build"
    printf 'Archive path: %s\n' "$ARCHIVE_PATH"
    if [[ -n "${ASC_KEY_ID:-}${ASC_ISSUER_ID:-}${ASC_KEY_PATH:-}" ]]; then
      require_credentials
      echo "App Store Connect credentials are complete (values hidden)."
    else
      echo "App Store Connect credentials are not loaded; archive may use the Xcode account, but validate/upload will not run."
    fi
    ;;
  archive)
    require_clean_release_state
    require_new_build_number
    mkdir -p "$RELEASE_DIR"
    rm -rf "$ARCHIVE_PATH"
    set_authentication_args
    run_xcodebuild archive \
      -project "$PROJECT" \
      -scheme "$SCHEME" \
      -configuration "$CONFIGURATION" \
      -destination 'generic/platform=iOS' \
      -archivePath "$ARCHIVE_PATH" \
      -allowProvisioningUpdates \
      "${auth[@]}"
    echo "Archive created: $ARCHIVE_PATH"
    ;;
  export)
    require_clean_release_state
    [[ -d "$ARCHIVE_PATH" ]] || { echo "Archive not found: $ARCHIVE_PATH" >&2; exit 1; }
    rm -rf "$EXPORT_PATH"
    mkdir -p "$EXPORT_PATH"
    set_authentication_args
    run_xcodebuild -exportArchive \
      -archivePath "$ARCHIVE_PATH" \
      -exportPath "$EXPORT_PATH" \
      -exportOptionsPlist "$EXPORT_OPTIONS" \
      -allowProvisioningUpdates \
      "${auth[@]}"
    echo "Exported IPA: $(find_ipa)"
    ;;
  validate|upload)
    require_clean_release_state
    require_credentials
    if [[ "$action" == "upload" && "${ALLOW_EXISTING_BUILD:-NO}" == "YES" ]]; then
      echo "ALLOW_EXISTING_BUILD may reproduce an archive but may not bypass upload build-number checks." >&2
      exit 1
    fi
    [[ "$action" == "validate" ]] || require_new_build_number
    ipa="$(find_ipa)"
    altool_action="--validate-app"
    [[ "$action" == "upload" ]] && altool_action="--upload-app"
    xcrun altool "$altool_action" -f "$ipa" \
      --api-key "$ASC_KEY_ID" \
      --api-issuer "$ASC_ISSUER_ID" \
      --p8-file-path "$ASC_KEY_PATH"
    ;;
  *)
    echo "Unknown action '$action'. Use preflight, archive, export, validate, or upload." >&2
    exit 1
    ;;
esac
