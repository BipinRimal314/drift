# Drift mobile

Drift shows the percentage of the current local hour on Android and iOS.
Time shift changes the secondary clock. It does not change the hour percentage.
Wake times use the 24-hour HH:mm format. The app saves them on the device.

Run these commands in this directory.

```sh
npm install
npm test
npm run typecheck
npm run android
npm run ios
```

The native commands generate the Android and iOS projects before building them.
iOS requires macOS and Xcode. Android requires the Android SDK and Java.
Use `npm start` to start the development server for an installed app.

Open **Clock outside Drift** to compare the home screen widget and floating clock.
Android can use both. iOS has a home screen widget and does not permit a floating clock over other apps.
The widget shows the local hour. Time shift applies only to the clock inside Drift.

On Android, tap **Add home screen widget** and confirm the launcher prompt.
For the floating clock, allow Drift to appear over other apps.
Return to Drift and tap **Start floating clock**.
Drag the percentage to move it. Tap the percentage to open Drift.
Tap the close control or the notification's **Stop** action to stop it.
Android can hide the floating clock on protected screens, including some Settings screens.
The floating clock does not restart automatically after a process stop or device restart.

On iOS, add Drift through the home screen widget picker.
The widget requires iOS 17 or later and supports small and medium sizes.
Both platforms control widget update timing. Updates can be delayed.
Android shows the last update time and provides a manual refresh control.

For this workspace path, use the iOS build script. It builds from a temporary path without spaces.
Pass the identifier of a booted simulator.

```sh
npm run build:ios -- SIMULATOR_ID
xcrun simctl install booted /private/tmp/drift-ios-build/Build/Products/Release-iphonesimulator/Drift.app
```

The simulator build uses iOS 17 as its minimum version for all native targets.
It does not produce a signed App Store archive.

Run the native checks with these commands.

```sh
node plugins/check-widget.cjs
swiftc native/ios-widget/DriftClock.swift native/ios-widget/check.swift -o /private/tmp/drift-widget-check
/private/tmp/drift-widget-check
cd android
JAVA_HOME=/opt/homebrew/opt/openjdk@21 ./gradlew :drift-tools:testReleaseUnitTest
```

The Android phone checks are `qa/android.py` and `qa/outside-android.py`.
Pass the connected phone identifier with `--serial`.
The first check restores saved wake times, text size, and rotation.
The demonstration leaves the widget and floating clock enabled.
The demonstration uses Samsung's Calculator and permission screen.
Generate the iOS test project with `xcodegen generate` in `qa`.
Run its `DriftQA` scheme against a simulator with Drift installed.
The widget placement check uses `qa/widget-ios.py` after you add the widget.
It requires the `idb` client and a connected simulator companion.
The check saves a screenshot and an accessibility record of the native widget.

The clock updates each second while the app is active.
It reads the current device time when the app resumes.
The app follows the device font size and has scrollable content.
It has no flashing or animated transitions.
It uses the Space Grotesk and JetBrains Mono fonts from the macOS app.
