#!/bin/sh
set -eu

simulator_id=${1:?Pass the simulator identifier from xcrun simctl list devices.}
cd "$(dirname "$0")/.."
npx expo prebuild --platform ios --no-install

build_dir=/private/tmp/drift-mobile-build
mkdir -p "$build_dir"
rsync -a --exclude=/android/ --exclude=/qa/ --exclude=/ios/Pods/ --exclude=/.expo/ ./ "$build_dir/"
cd "$build_dir/ios"
pod install
NODE_ENV=production xcodebuild -workspace Drift.xcworkspace -scheme Drift -configuration Release \
  -destination "platform=iOS Simulator,id=$simulator_id" -derivedDataPath /private/tmp/drift-ios-build \
  CODE_SIGNING_ALLOWED=NO IPHONEOS_DEPLOYMENT_TARGET=17.0 build
