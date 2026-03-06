#!/usr/bin/env bash
set -e

# "Apple Development: soomtong@gmail.com (4XWP9KHTYS)"

# APP="/Users/$USER/Library/Input Methods/Patal.app"
APP="/Library/Input Methods/Patal.app"
PKG="PatalInputMethod.pkg"

BUILD_DIR=$(xcodebuild -project ../macOS/Patal.xcodeproj -scheme Patal -configuration Release -showBuildSettings 2>/dev/null | awk '/CONFIGURATION_BUILD_DIR =/{print $NF}')

echo "Build package will install into \"$APP\" from pkgbuild"
echo ""

sleep 1
pushd ../macOS

xcodebuild -scheme Patal -configuration Release -quiet
sleep 1

mkdir -p ../dist

# 패키지 빌드 만 진행; 배포용 빌드는 distribute.sh 에서 진행
pkgbuild \
  --root "$BUILD_DIR/Patal.app" \
  --identifier "com.soomtong.inputmethod.Patal" \
  --install-location "$APP" ../dist/"$PKG"
# --version "1.0.0" \
popd

echo ""
echo "Finished package build"
echo ""
ls -l ../dist
