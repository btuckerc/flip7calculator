#!/usr/bin/env bash
set -euo pipefail

device_name="${1:-iPhone 16}"
os_version="${2:-latest}"
mode="${3:-destination}"

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required to resolve simulator destinations." >&2
  exit 1
fi

json="$(xcrun simctl list devices available --json)"

match="$(
  jq -r --arg name "$device_name" --arg os "$os_version" '
    [
      .devices
      | to_entries[]
      | select(.key | test("^com\\.apple\\.CoreSimulator\\.SimRuntime\\.iOS"))
      | .key as $runtime
      | .value[]
      | select(.isAvailable == true and .name == $name)
      | {
          udid: .udid,
          name: .name,
          version: ($runtime | capture("iOS-(?<v>.*)$").v | gsub("-"; ".")),
          version_key: ($runtime | capture("iOS-(?<v>.*)$").v | split("-") | map(tonumber))
        }
    ]
    | if $os == "" or $os == "latest"
      then sort_by(.version_key) | last
      else map(select(.version == $os)) | sort_by(.version_key) | last
      end
    | if . == null then empty else @base64 end
  ' <<<"$json"
)"

if [[ -z "$match" ]]; then
  echo "No available iOS simulator matched name='$device_name' os='$os_version'." >&2
  echo "Available iOS simulator names:" >&2
  jq -r '
    .devices
    | to_entries[]
    | select(.key | test("^com\\.apple\\.CoreSimulator\\.SimRuntime\\.iOS"))
    | .value[]
    | select(.isAvailable == true)
    | .name
  ' <<<"$json" | sort -u >&2
  exit 1
fi

decoded() {
  printf '%s' "$match" | base64 --decode | jq -r "$1"
}

udid="$(decoded '.udid')"
version="$(decoded '.version')"

case "$mode" in
  destination)
    printf 'platform=iOS Simulator,id=%s\n' "$udid"
    ;;
  udid)
    printf '%s\n' "$udid"
    ;;
  version)
    printf '%s\n' "$version"
    ;;
  *)
    echo "Unknown mode '$mode'. Use destination, udid, or version." >&2
    exit 1
    ;;
esac
