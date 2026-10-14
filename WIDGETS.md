# Amperfy Home Screen widgets

This fork adds **Now Playing** and **Recently Played**, each in small, medium,
and large Home Screen sizes. Recently Played groups songs by album. Playback
buttons use `AudioPlaybackIntent` to control the app's existing player without
opening its interface. Widgets read a small, atomic snapshot; they never open
the music database or receive your server credentials.

The widgets use Apple Music's pink gradient, artwork proportions, compact
system typography, and cover-grid layout. Now Playing also offers artwork
backgrounds. They keep Amperfy's own identity.

## Free builds

The **Build Amperfy with Widgets** GitHub Actions workflow runs on a standard
macOS runner, selects Xcode 26, runs the widget-state tests, compiles for the
simulator, and archives an iPhone/iPad build. Download **Amperfy-Widgets-IPA**
from the workflow's artifacts and unzip it to obtain `Amperfy-Widgets.ipa`.

The IPA has ad-hoc signatures for the sideloader to replace. It cannot be
installed directly or uploaded to TestFlight as-is. No Apple account or
signing credentials are required in GitHub. Standard runners are free for
public repositories. Artifact retention is limited to 14 days.

## Installation

Install the IPA through SideStore or AltStore Classic using your own Apple
Account. **Keep the AmperfyWidgets extension** when prompted. Both app and
extension need the same App Group; the snapshot reader honors the sideloader's
`ALTAppGroups` remapping. A free account needs refreshing within seven days.

Launch Amperfy, sign in to your music server, and play an album. Then add
Amperfy's Now Playing or Recently Played widget from the Home Screen widget
gallery. History starts with playback in this fork. Switching accounts clears
the visible history from the previous account.

This checkout requires **iOS/iPadOS 26 or newer**, matching upstream. The
sideload build uses only the App Group entitlement; CarPlay and Siri's older
entitlement-based integration are not included in that build. Home Screen
buttons use App Intents. Keep your existing app until the fork is verified;
the fork does not migrate the existing installation's music cache or login.

## Verification

CI must pass before calling the IPA compiled. A successful simulator compile
does not establish that a particular sideloader preserved the widget's App
Group or that widgets behave correctly on your physical phone. On-device
verification must cover current artwork, pause/resume/skip, album playback,
offline cached playback, cold app launches, account switching, and refresh
after re-signing. iOS controls widget refresh timing.

Source remains GPL-3.0-or-later, as in upstream Amperfy.
