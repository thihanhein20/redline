#!/bin/zsh
# Builds Redline.app and packages it as a drag-to-install DMG:
#   scripts/make-dmg.sh   → build/Redline-<version>.dmg
set -euo pipefail
cd "$(dirname "$0")/.."

scripts/build-app.sh

VERSION=$(defaults read "$PWD/build/Redline.app/Contents/Info" CFBundleShortVersionString)
DMG=build/Redline-$VERSION.dmg
STAGING=$(mktemp -d)

# DMG contents: the app plus a shortcut to /Applications to drag it onto.
cp -R build/Redline.app "$STAGING/"
ln -s /Applications "$STAGING/Applications"

rm -f "$DMG"
hdiutil create -volname "Redline $VERSION" -srcfolder "$STAGING" -fs HFS+ -format UDZO -ov "$DMG" >/dev/null
rm -rf "$STAGING"

echo "Built $DMG ($(du -h "$DMG" | cut -f1 | tr -d ' '))"
