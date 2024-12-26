#!/usr/bin/env bash
# set -x

APP="/Users/$USER/Library/Input Methods/Patal.app"
echo "Patal process is killing"
echo ""

pkill Patal
sleep 1

rm -rf "$APP"
sleep 1
pushd ../macOS

xcodebuild -verbose
sleep 1

mv ./build/Release/Patal.app "$APP"
popd
