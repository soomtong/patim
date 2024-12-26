#!/usr/bin/env bash
set -e

# "Apple Development: soomtong@gmail.com (4XWP9KHTYS)"

# APP="/Users/$USER/Library/Input Methods/Patal.app"
APP="/Library/Input Methods/Patal.app"
PKG="PatalInputMethod.pkg"

echo "Build package into \"$APP\" from pkgbuild after App build"
echo ""

sleep 1
pushd ../macOS

xcodebuild -quiet
sleep 1

# 패키지 빌드 만 진행
# Sok 입력기처럼 스크립트도 구성하여 입력기 환경을 초기화 하는 작업이 필요함 추가로 진행하자
pkgbuild \
  --root ./build/Release/Patal.app \
  --identifier "com.soomtong.inputmethod.Patal" \
  --install-location "$APP" ../"$PKG"
# --version "1.0.0" \
popd
