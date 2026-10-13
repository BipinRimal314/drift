# Drift mobile handoff

Updated 13 October 2026. Source commit `8a66cb5`.

## Current state

The macOS app remains in `Drift`. The Android and iOS app is in `mobile`.
The mobile app shows local hour percentage, named phases, remaining minutes, ordinary time, and a saved time shift.
Time shift changes the secondary clock only. It does not change hour progress.

**Clock outside Drift** compares the two visibility choices.
Android has a native home screen widget and a movable floating clock.
iOS has a native WidgetKit home screen widget in small and medium sizes.
Users can use both Android choices together.

The final Android build is installed on the user's Samsung Galaxy A33, running Android 16.
Its device identifier is `RZCTA1P9XSW`.
The widget and floating clock remain enabled for comparison.
The phone's original text size, rotation, and saved wake times were restored after the clock checks.

The iOS app and widget run on the `QA 17Pro` simulator, using iOS 26.5.
Its identifier is `BF77AEEB-B7CD-4D90-93A6-0539727FB8D7`.
The native widget is installed on its home screen.
No remote push or store publication occurred.

## Verification

All checks below passed.

- `npm test` runs six clock tests covering quarter boundaries, midnight, fractional time zones, shift offsets, and storage validation.
- `npm run typecheck` checks the TypeScript source.
- `node plugins/check-widget.cjs` checks iOS sources, embedding, dependencies, and repeated project generation.
- The Swift widget check verifies local hour boundaries and timeline dates.
- `:drift-tools:testReleaseUnitTest` verifies the Android clock model.
- Android release builds pass and include the notification permission.
- `qa/android.py` checks the real phone's clock, explanation, invalid times, saved settings, restart, background return, large text, and landscape.
- `qa/outside-android.py` checks widget placement, manual refresh, display permission, service start, drag, use over Calculator, close, and restart.
- Four iOS interaction tests pass in `/private/tmp/drift-ios-final.xcresult`.
- `qa/widget-ios.py` confirms a visible native iOS widget and saves its accessibility record and screenshot.

Two independent reviewers approved structure and correctness.
The final correction reviews approved the lifecycle gate, notification permission, state refresh, and phone setting restoration.
The Android widget layout was then made compact and verified again on the phone.

The simulator widget picker exposes incomplete accessibility data to XCTest.
Widget placement was completed through the simulator companion's accessibility bridge.
The passing XCTest suite checks the app's comparison screen. The separate widget check proves home screen presence.

## Local artifacts

The ignored `release-artifacts` directory contains the Android preview APK and screenshots.

- `drift-android-preview.apk` is the tested Android build.
- `android-widget-and-floating.png` shows both Android choices together.
- `android-floating-over-calculator.png` shows the floating clock over another app.
- `ios-widget.png` shows the native iOS widget on its home screen.

The APK uses the generated project's development signing key. It is not a Play Store release.
Its SHA-256 is `9356f19ff36947c295ea132a557d9efe53d8fdcb50fd19f65b53a076d23d33fe`.
The iOS simulator app is at `/private/tmp/drift-ios-build/Build/Products/Release-iphonesimulator/Drift.app`.

## Android status icon

Android has a third choice: **Status icon**.
It shows the hour percentage as digits beside the other status bar icons.
The notification gives the percentage, phase, and remaining minutes, with a **Stop status icon** action.
It needs notification permission only. It does not need display-over-apps permission.
Updates are silent. They pause when the screen is off and resume when it turns on.
A swipe on Android 14 or later stops the service. The icon does not restart after a process stop or device restart.

Android groups Drift's notifications when the floating clock is also on. The status bar digits still show.

Verified on the Samsung A33:
- `qa/notification-android.py` passes: silent bitmap icon, background update over Calculator, notification Stop, app Stop, restart.
- `qa/outside-android.py` passes after the services were changed to call `startForeground` first.
- `npm test`, `npm run typecheck`, `assembleRelease`, and `:drift-tools:testReleaseUnitTest` pass.

Two review rounds approved it. Round 1 fixed an early-stop crash path in both services and the swipe behavior.
Two suggestions were declined: a shared base class for two services, and a shared QA helper module.

Optional cleanups from round 2, none blocking:
1. Pass `DriftNotificationService.canShow` directly in `startNotification`; `ensureChannel` there is redundant.
2. Import `android.util.Log` and `androidx.lifecycle` types instead of full names.
3. Use named arguments for the four message strings passed to `startTool`.
4. Move the repeated Android 13 permission request in `OutsideClock.tsx` into one function.

The phone is left with the widget, floating clock, and status icon enabled.

## Build and behavior limits

Use `mobile/scripts/build-ios.sh` for this workspace path.
It stages the project without spaces because React Native's prebuilt dependency installer rejects this path.
It also sets iOS 17 for simulator build targets to avoid obsolete dependency deployment targets in the installed SDK.
Generated Android and iOS projects are ignored. Native module and widget sources are committed.

Android overlay permission is optional. The app works without it.
The floating clock has a visible close control and a notification Stop action.
It stops clock updates when the screen turns off and recomputes from device time when the screen turns on.
It does not restart automatically after a process stop or device restart.
Protected screens can hide overlays. This occurred on Android Settings during testing.

Both operating systems can delay widget updates.
Android shows its last update time and has a manual refresh control.
The iOS widget provides scheduled percentage entries, but Apple controls delivery.
The system status bar clock is unchanged. iOS does not permit a floating display over other apps.

The dependency audit lists 32 affected package entries from four underlying build tool advisories.
The first correctness reviewer found none of those packages in the Android release JavaScript bundle.
Forced audit fixes propose incompatible framework changes and were not applied.

Real iPhone hardware, TalkBack operation, VoiceOver operation, and store signing were not tested.
The source includes screen reader labels and text alternatives to phase colors.

## Research and next steps

`RESEARCH.md` has primary guidance, evidence limits, eight proposed features, and five existing tool comparisons.
The current research does not establish clinical benefit for Drift's percentage clock.

1. Record which visibility choice users prefer and whether either creates pressure or distraction.
2. If the user selects the next feature, build one named visual timer with pause, extend, and a saved current task.
3. Add optional sensory controls and transition cues after native notification and background checks.
4. Test on real iPhone hardware before preparing a store release.
5. Review the framework's build tool advisories before a production release.

Model the Domain kept the app clock calculations in one pure module and one native helper per platform.
Boundary Discipline kept validation at stored data, wake time input, and Android permission boundaries.
Prove It Works required actual phone, simulator, and widget rendering checks before this handoff.
