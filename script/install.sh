#!/usr/bin/env bash
set -e

APP="/Users/$USER/Library/Input Methods/Patal.app"
BUILD_DIR=$(xcodebuild -project ../macOS/Patal.xcodeproj -scheme Patal -configuration Release -showBuildSettings 2>/dev/null | awk '/CONFIGURATION_BUILD_DIR =/{print $NF}')

echo "Installing Patal to $APP"

sleep 1

rm -rf "$APP"
sleep 1
pushd ../macOS

xcodebuild -scheme Patal -configuration Release | xcbeautify
sleep 1

mv "$BUILD_DIR/Patal.app" "$APP"
popd

echo ""
echo "Killing Patal process..."

sleep 1
killall Patal || true
