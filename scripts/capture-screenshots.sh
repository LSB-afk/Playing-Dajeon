#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_PATH="$ROOT_DIR/NolgoManyDJ.xcodeproj"
DERIVED_DATA="$ROOT_DIR/.build/DerivedData"
APP_PATH="$DERIVED_DATA/Build/Products/Debug-iphonesimulator/NolgoManyDJ.app"
OUTPUT_DIR="$ROOT_DIR/docs/screenshots"
BUNDLE_ID="com.nolgomanydj.app"
DEVICE_NAME="${DEVICE_NAME:-iPhone 17 Pro}"

if [[ -z "${DEVICE_UDID:-}" ]]; then
    DEVICE_UDID="$(xcrun simctl list devices available | awk -F '[()]' -v device="$DEVICE_NAME" '$0 ~ "    " device " \\(" { print $2; exit }')"
fi

if [[ -z "$DEVICE_UDID" ]]; then
    echo "사용 가능한 '$DEVICE_NAME' 시뮬레이터를 찾지 못했습니다." >&2
    exit 1
fi

mkdir -p "$DERIVED_DATA" "$OUTPUT_DIR"

open -a Xcode "$PROJECT_PATH"
open -a Simulator
xcrun simctl boot "$DEVICE_UDID" >/dev/null 2>&1 || true
xcrun simctl bootstatus "$DEVICE_UDID" -b
xcrun simctl ui "$DEVICE_UDID" appearance light
xcrun simctl status_bar "$DEVICE_UDID" override \
    --time 9:41 \
    --batteryState charged \
    --batteryLevel 100 \
    --wifiBars 3 \
    --cellularBars 4

xcodebuild \
    -project "$PROJECT_PATH" \
    -scheme NolgoManyDJ \
    -configuration Debug \
    -destination "platform=iOS Simulator,id=$DEVICE_UDID" \
    -derivedDataPath "$DERIVED_DATA" \
    CODE_SIGNING_ALLOWED=NO \
    build > "$ROOT_DIR/.build/screenshot-build.log"

xcrun simctl uninstall "$DEVICE_UDID" "$BUNDLE_ID" >/dev/null 2>&1 || true
xcrun simctl install "$DEVICE_UDID" "$APP_PATH"
xcrun simctl privacy "$DEVICE_UDID" grant location "$BUNDLE_ID"
xcrun simctl location "$DEVICE_UDID" set 36.3504,127.3845

SCENES=(
    "01-splash:splash:1.0"
    "02-onboarding:onboarding:1.5"
    "03-home:home:4.0"
    "04-search:search:4.0"
    "05-category:category:4.0"
    "06-map:map:5.0"
    "07-courses:courses:4.0"
    "08-course-detail:course-detail:5.0"
    "09-merchant-detail:store-detail:2.0"
    "10-saved:saved:4.0"
    "11-my-page:my-page:3.0"
    "12-owner-dashboard:owner-dashboard:3.0"
)

for entry in "${SCENES[@]}"; do
    IFS=':' read -r filename scene delay <<< "$entry"
    xcrun simctl terminate "$DEVICE_UDID" "$BUNDLE_ID" >/dev/null 2>&1 || true
    xcrun simctl launch --terminate-running-process "$DEVICE_UDID" "$BUNDLE_ID" \
        --screenshot-scene "$scene" >/dev/null
    sleep "$delay"
    xcrun simctl io "$DEVICE_UDID" screenshot --type=png "$OUTPUT_DIR/$filename.png"
    echo "captured $filename.png"
done

xcrun simctl status_bar "$DEVICE_UDID" clear
echo "스크린샷 저장 완료: $OUTPUT_DIR"
