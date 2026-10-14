#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
xcrun simctl install booted build/simulator/Build/Products/Debug-iphonesimulator/Amperfy.app
launch_output=$(xcrun simctl launch booted org.senzalimiti.amperfy)
printf '%s\n' "$launch_output"
app_pid=${launch_output##*: }
sleep 5
kill -0 "$app_pid"
xcrun simctl io booted screenshot build/widget-previews/app-launch.png
printf '%s\n' 'PASS: Amperfy launched and remained running after widget publisher initialization.'
