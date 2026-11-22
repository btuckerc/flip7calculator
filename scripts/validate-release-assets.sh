#!/usr/bin/env bash
set -euo pipefail

ASSETS_DIR="${ASSETS_DIR:-AppStoreAssets/1.4}"
METADATA_FILE="${METADATA_FILE:-$ASSETS_DIR/metadata-en-US.json}"
ICON_DIR="${ICON_DIR:-flip7calculator/Assets.xcassets/AppIcon.appiconset}"
RELEASE_STATE_FILE="${RELEASE_STATE_FILE:-AppStoreAssets/release-state.json}"

fail() {
  echo "FAIL  $1" >&2
  exit 1
}

pass() {
  echo "PASS  $1"
}

command -v jq >/dev/null 2>&1 || fail "jq is required"
command -v sips >/dev/null 2>&1 || fail "sips is required"
[[ -f "$METADATA_FILE" ]] || fail "missing metadata file: $METADATA_FILE"
jq empty "$METADATA_FILE" || fail "metadata is not valid JSON"
pass "metadata JSON parses"

check_length() {
  local path="$1"
  local maximum="$2"
  local label="$3"
  local value length
  value="$(jq -er "$path" "$METADATA_FILE")" || fail "missing $label"
  length="$(jq -nr --arg value "$value" '$value | length')"
  (( length <= maximum )) || fail "$label is $length characters; maximum is $maximum"
  pass "$label length is $length/$maximum"
}

check_length '.appInfo.name' 30 'app name'
check_length '.appInfo.subtitle' 30 'subtitle'
check_length '.version.keywords' 100 'keywords'
check_length '.version.promotionalText' 170 'promotional text'
check_length '.version.description' 4000 'description'
check_length '.version.whatsNew' 4000 "What's New"

for path in '.appInfo.privacyPolicyUrl' '.version.supportUrl'; do
  url="$(jq -er "$path" "$METADATA_FILE")" || fail "missing URL at $path"
  [[ "$url" == https://* ]] || fail "$path must use HTTPS"
done
pass "privacy and support URLs use HTTPS"

source_name="$(sed -n 's/^[[:space:]]*static let appName = "\(.*\)"/\1/p' flip7calculator/Utilities/AppBrand.swift | head -1)"
metadata_name="$(jq -r '.appInfo.name' "$METADATA_FILE")"
[[ -n "$source_name" && "$source_name" == "$metadata_name" ]] \
  || fail "AppBrand name and metadata name differ"
pass "AppBrand and metadata names agree"

for icon in AppIcon-1024.png AppIcon-1024-dark.png AppIcon-1024-tinted.png; do
  path="$ICON_DIR/$icon"
  [[ -f "$path" ]] || fail "missing icon: $path"
  properties="$(sips -g pixelWidth -g pixelHeight -g hasAlpha "$path" 2>/dev/null)"
  width="$(awk '/pixelWidth:/ {print $2}' <<<"$properties")"
  height="$(awk '/pixelHeight:/ {print $2}' <<<"$properties")"
  alpha="$(awk '/hasAlpha:/ {print $2}' <<<"$properties")"
  [[ "$width" == 1024 && "$height" == 1024 ]] || fail "$icon must be 1024x1024"
  [[ "$alpha" == no ]] || fail "$icon must not contain transparency"
done
pass "all app icon variants are opaque 1024x1024 PNGs"

check_screenshot_directory() {
  local directory="$1"
  local expected_width="$2"
  local expected_height="$3"
  local count=0
  local path properties width height

  [[ -d "$directory" ]] || fail "missing screenshot directory: $directory"
  while IFS= read -r path; do
    count=$((count + 1))
    properties="$(sips -g pixelWidth -g pixelHeight "$path" 2>/dev/null)"
    width="$(awk '/pixelWidth:/ {print $2}' <<<"$properties")"
    height="$(awk '/pixelHeight:/ {print $2}' <<<"$properties")"
    [[ "$width" == "$expected_width" && "$height" == "$expected_height" ]] \
      || fail "$(basename "$path") is ${width}x${height}; expected ${expected_width}x${expected_height}"
  done < <(find "$directory" -maxdepth 1 -name '*.png' -print | sort)
  (( count > 0 )) || fail "no PNG screenshots in $directory"
  pass "$count screenshots in $directory match ${expected_width}x${expected_height}"
}

check_screenshot_directory "$ASSETS_DIR/iPhone-6.9" 1320 2868
check_screenshot_directory "$ASSETS_DIR/iPad-13" 2064 2752

human_keywords="$(awk '
  /^## Keywords$/ { in_keywords = 1; next }
  in_keywords && /^```text$/ { getline; print; exit }
' APP_STORE_LISTING.md)"
json_keywords="$(jq -r '.version.keywords' "$METADATA_FILE")"
[[ "$human_keywords" == "$json_keywords" ]] \
  || fail "APP_STORE_LISTING.md keywords differ from $METADATA_FILE"
pass "human and machine-readable keywords agree"

[[ -f "$RELEASE_STATE_FILE" ]] || fail "missing release-state file: $RELEASE_STATE_FILE"
jq -e '
  (.bundleId | type == "string" and length > 0)
  and (.lastUploaded.version | type == "string" and length > 0)
  and (.lastUploaded.build | type == "number" and . >= 0)
  and (.lastUploaded.recordedAt | type == "string" and length > 0)
' "$RELEASE_STATE_FILE" >/dev/null || fail "release-state file is incomplete"
pass "release-state lower bound is recorded"

echo "Release asset validation passed. URL content and live App Store state still require network checks."
