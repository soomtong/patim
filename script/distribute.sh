#!/usr/bin/env bash
set -e

# "Apple Development: soomtong@gmail.com (4XWP9KHTYS)"

TITLE="팥알 입력기"
VERSION="1.0"
APPID="com.soomtong.inputmethod.Patal"
BUILD="PatalInputMethod"
PKG="$BUILD.pkg"
DIST="../dist"
COMPONENT="$DIST/$PKG"
APP="$DIST/PatalInputMethod_$VERSION.pkg"

if [[ ! -f "$COMPONENT" ]]; then
  echo "Error: $COMPONENT file does not exist."
  exit 1
fi

echo "Bundle package for distribution from productbuild after App packaging"
echo ""

sleep 1

pushd ../dist

cat > Distribution.xml <<EOF
<?xml version="1.0" encoding="utf-8"?>
<installer-gui-script minSpecVersion="1">
  <title>$TITLE</title>
  <pkg-ref id="$APPID"/>
  <options customize="never" require-scripts="false" hostArchitectures="x86_64,arm64"/>
  <volume-check>
    <allowed-os-versions>
      <os-version min="11.0"/>
    </allowed-os-versions>
  </volume-check>
  <choices-outline>
      <line choice="default">
          <line choice="$APPID"/>
      </line>
  </choices-outline>
  <choice id="default"/>
  <choice id="$APPID" visible="false">
      <pkg-ref id="$APPID"/>
      <description>한글 입력기</description>
  </choice>
  <pkg-ref id="$APPID" version="$VERSION" onConclusion="RequireLogout">$PKG</pkg-ref>
</installer-gui-script>
EOF

rm -rf $BUILD\_*.pkg

productbuild --distribution ./Distribution.xml --package-path . "$APP"

popd

echo ""
echo "Finished distribution package build"
echo ""
ls -l ../dist