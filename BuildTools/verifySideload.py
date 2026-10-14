"""Verify the packaged app really includes a matching WidgetKit extension."""
import plistlib
import sys
import zipfile

with zipfile.ZipFile(sys.argv[1]) as archive:
    app = plistlib.loads(archive.read("Payload/Amperfy.app/Info.plist"))
    widget = plistlib.loads(archive.read("Payload/Amperfy.app/PlugIns/AmperfyWidgets.appex/Info.plist"))
    assert widget["NSExtension"]["NSExtensionPointIdentifier"] == "com.apple.widgetkit-extension"
    assert widget["CFBundleIdentifier"].startswith(app["CFBundleIdentifier"] + ".")
    assert widget["CFBundleShortVersionString"] == app["CFBundleShortVersionString"]
    assert widget["CFBundleVersion"] == app["CFBundleVersion"]
    assert float(app["MinimumOSVersion"]) >= 26
    for path in ("Payload/Amperfy.app/Amperfy", "Payload/Amperfy.app/PlugIns/AmperfyWidgets.appex/AmperfyWidgets"):
        assert archive.getinfo(path).file_size > 0
print("PASS: IPA contains the app and matching WidgetKit extension (iOS 26+).")
