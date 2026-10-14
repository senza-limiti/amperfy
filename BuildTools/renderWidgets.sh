#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
set -o pipefail
xcodebuild -project Amperfy.xcodeproj -scheme WidgetGallery \
  -configuration Debug -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath build/gallery CODE_SIGNING_ALLOWED=NO build \
  2>&1 | tee build-gallery.log

simulator_id=$(xcrun simctl list devices available -j | python3 -c '
import json,sys
devices=json.load(sys.stdin)["devices"]
for runtime, entries in devices.items():
    if "iOS-26" in runtime:
        for device in entries:
            if device["name"].startswith("iPhone"):
                print(device["udid"]);sys.exit(0)
raise SystemExit("No iOS 26 iPhone simulator available")
')
xcrun simctl boot "$simulator_id" || true
xcrun simctl bootstatus "$simulator_id" -b
xcrun simctl status_bar "$simulator_id" override --time '9:41' --batteryState charged --batteryLevel 100
xcrun simctl install "$simulator_id" build/gallery/Build/Products/Debug-iphonesimulator/WidgetGallery.app
mkdir -p build/widget-previews
for variant in recent-small recent-medium recent-large now-small now-medium now-large; do
  xcrun simctl terminate "$simulator_id" org.senzalimiti.amperfy.gallery || true
  xcrun simctl launch "$simulator_id" org.senzalimiti.amperfy.gallery "$variant"
  sleep 3
  xcrun simctl io "$simulator_id" screenshot "build/widget-previews/$variant.png"
done
