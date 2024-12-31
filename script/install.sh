#!/usr/bin/env bash
set -e

APP="/Users/$USER/Library/Input Methods/Patal.app"
echo "Installing Patal to $APP"

sleep 1

rm -rf "$APP"
sleep 1
pushd ../macOS

xcodebuild | xcbeautify
sleep 1

mv ./build/Release/Patal.app "$APP"
popd

echo ""
echo "Killing Patal process..."

sleep 1
killall Patal || true
