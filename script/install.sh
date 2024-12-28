#!/usr/bin/env bash
set -e

APP="/Users/$USER/Library/Input Methods/Patal.app"
echo "Patal process is killing"
echo ""

killall Patal || true

sleep 1

rm -rf "$APP"
sleep 1
pushd ../macOS

xcodebuild
sleep 1

mv ./build/Release/Patal.app "$APP"
popd
