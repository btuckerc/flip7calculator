#!/usr/bin/env bash
set -euo pipefail

# Capture deterministic real-app screenshots on iPhone 6.9" and iPad 13" simulators.
# Usage: scripts/capture-appstore-raw.sh <output_dir> <iphone_udid> <ipad_udid>

OUT_DIR="${1:?output dir required}"
IPHONE_UDID="${2:?iphone udid required}"
IPAD_UDID="${3:?ipad udid required}"
BUNDLE_ID="com.tcraig.flip7calculator.ios"
DERIVED_DATA="${DERIVED_DATA:-$HOME/Library/Caches/FlippingSevenCalculator/DerivedData}"
APP_PATH="$DERIVED_DATA/Build/Products/Debug-iphonesimulator/flip7calculator.app"

mkdir -p "$OUT_DIR/iphone" "$OUT_DIR/ipad"

xcodebuild build \
  -project flip7calculator.xcodeproj \
  -scheme flip7calculator \
  -configuration Debug \
  -destination "platform=iOS Simulator,id=$IPHONE_UDID" \
  -derivedDataPath "$DERIVED_DATA" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  >/dev/null

test -d "$APP_PATH" || { echo "Built app not found at $APP_PATH" >&2; exit 1; }

capture_device() {
  local udid="$1"
  local subdir="$2"
  shift 2
  local fixtures=("$@")

  xcrun simctl boot "$udid" >/dev/null 2>&1 || true
  xcrun simctl bootstatus "$udid" -b
  xcrun simctl ui "$udid" appearance dark
  xcrun simctl status_bar "$udid" override \
    --time "9:41" \
    --dataNetwork wifi \
    --wifiMode active \
    --wifiBars 3 \
    --cellularMode active \
    --cellularBars 4 \
    --batteryState charged \
    --batteryLevel 100
  xcrun simctl install "$udid" "$APP_PATH"

  for fixture in "${fixtures[@]}"; do
    xcrun simctl terminate "$udid" "$BUNDLE_ID" >/dev/null 2>&1 || true
    xcrun simctl launch "$udid" "$BUNDLE_ID" -appStoreCapture "$fixture" -releaseMarketingPreview >/dev/null
    sleep 2.0
    xcrun simctl io "$udid" screenshot "$OUT_DIR/$subdir/$fixture.png" >/dev/null
    echo "Captured $subdir/$fixture.png"
  done

  xcrun simctl terminate "$udid" "$BUNDLE_ID" >/dev/null 2>&1 || true
  xcrun simctl status_bar "$udid" clear >/dev/null 2>&1 || true
  xcrun simctl shutdown "$udid" >/dev/null 2>&1 || true
}

capture_device "$IPHONE_UDID" iphone live live-bonus stats setup game-over
capture_device "$IPAD_UDID" ipad live live-bonus stats game-over
