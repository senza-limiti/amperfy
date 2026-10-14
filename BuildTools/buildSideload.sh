#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

# Archive without an Apple account. Ad-hoc signatures retain the App Group
# entitlement so SideStore/AltStore can discover and re-sign both bundles.
xcodebuild -project Amperfy.xcodeproj -scheme AmperfySideload \
  -configuration Release -destination 'generic/platform=iOS' \
  -archivePath build/Amperfy.xcarchive \
  CODE_SIGNING_ALLOWED=NO archive

app_path="build/Amperfy.xcarchive/Products/Applications/Amperfy.app"
test -d "$app_path/PlugIns/AmperfyWidgets.appex"

if [[ -d "$app_path/Frameworks" ]]; then
  while IFS= read -r -d '' framework; do
    codesign --force --sign - "$framework"
  done < <(find "$app_path/Frameworks" -maxdepth 1 \( -name '*.framework' -o -name '*.dylib' \) -print0)
fi
codesign --force --sign - --entitlements AmperfyWidgets/AmperfyWidgets.entitlements \
  "$app_path/PlugIns/AmperfyWidgets.appex"
codesign --force --sign - --entitlements AmperfyWidgets/AmperfyWidgets.entitlements "$app_path"
codesign --verify --deep --strict "$app_path"

mkdir -p build/ipa/Payload
ditto "$app_path" build/ipa/Payload/Amperfy.app
(cd build/ipa && zip -qry ../Amperfy-Widgets.ipa Payload)
python3 BuildTools/verifySideload.py build/Amperfy-Widgets.ipa
