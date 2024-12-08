#!/usr/bin/env bash
set -x

APP=~/Library/Input\ Methods/Patal.app

# echo "process kill Patal"
pkill Patal

sleep 1

rm -rf "$APP"

sleep 1

xcodebuild

sleep 1

mv build/Release/Patal.app "$APP"
