# Stream Deck iPad hardware test

This is an Xcode SOURCE PROJECT, not an installable IPA. It has not been compiled or run on an iPad in this Windows workspace.

## What it tests
- Physical deck detection through your existing Square powered hub.
- Live numbered key displays and physical key down/up events.
- First ten keys: tap to select sample ticket; double tap (within 450ms between releases) starts five-second countdown; press during countdown cancels immediately.
- Hold a ticket key for at least one second, then release: logs a test reprint; no announcement.
- Optional speech after countdown, through the iPad's current audio output.
- Key 14 toggles batch overview; hold/release key 15 toggles a simulated pause.
- Device disconnect or app becoming inactive cancels pending countdowns.
- Battery status helps check charging while USB data is connected.
- Other keys display their physical index; use this to verify your model/layout.

No real SMS, printer, payments, Square POS integration, kiosk pause, ticket shifting, recent-order pages, or live batch counts are implemented. Sample tickets are fixed and remain in place after announcement. Keep test speech off until ready. This app must remain in the foreground.

## Requirements
1. USB-C iPad with an Apple M1 or newer chip. This project targets iPadOS 17 or later; the current Stream Deck Connect app may impose a higher minimum.
2. Elgato Stream Deck Connect installed; activate its driver following the app instructions.
3. Mac with Xcode 15+ (use a version supporting the iPad's installed OS), internet access for Swift package resolution, and Apple signing credentials/provisioning allowing the "Communicates with Drivers" entitlement.
4. Physical Elgato deck, suitable USB data cable, and your Square powered hub/stand arrangement. Square hub interoperability is NOT confirmed by this project.

## Build and install
1. Transfer this entire folder to the Mac; preserve its directory structure.
2. Open Example/StreamDeckKitExample.xcodeproj.
3. Choose the "StreamDeckKitExample App" scheme and the connected iPad.
4. In Signing & Capabilities select your development team. Use a unique bundle identifier.
5. Confirm the "Communicates with Drivers" capability is present in signing/provisioning. Merely keeping the entitlement file does not grant Apple permission.
6. Resolve packages and Build/Run. On-device Developer Mode/trust may need enabling through Apple's normal prompts.
7. Open the test app, keeping it foreground. Connect the deck through the powered Square setup.

If you do not have access to a Mac/signing, the source cannot be installed by opening it in Safari. A developer must build and sign it, then install through Xcode or a properly provisioned distribution path such as TestFlight.

## Test sequence
- Enable the Elgato driver before opening the test app.
- Confirm device name/key count appears. "started" session alone does NOT prove USB detection or driver activation.
- Confirm keys show #150–#159 (on 15-key model).
- Tap a key: matching sample order appears on iPad.
- Double tap: orange countdown appears on that key.
- Press during countdown: cancelled, no speech.
- Enable speech; double tap and wait: one test announcement. No text is sent.
- Hold/release a ticket key: test reprint log only.
- Hold/release PAUSE: test-only red state; real kiosk is unaffected.
- Unplug/reconnect deck, background/foreground app, restart iPad, and repeat.
- Check battery reports external power and remains charged over an extended session.

If no device appears, check Connect driver activation, eligible iPad, cables/data ports, and hub power. To isolate the Square hub, compare a direct connection where physically possible. Do not assume a powered or illuminated deck has a working data connection.

## Build/verification status
API names were checked against the bundled upstream SDK source. Apple SDK compilation, signing, physical USB, hub compatibility, and runtime behavior remain unverified because this workspace is Windows and has no attached iPad.

## SDK provenance
Includes Elgato's MIT-licensed StreamDeckKit and its example project, adapted for this test.
Upstream: https://github.com/elgatosf/streamdeck-kit-ipad
Snapshot: 23c3770bd51aa016a681d88d108cb0ab712171d5
License: LICENSE. Existing SDK/example sources retain their original notices.
Documentation: https://docs.elgato.com/ipad/getting-started/
