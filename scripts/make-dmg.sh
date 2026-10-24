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

source scripts/signing.sh
[[ -n "$SIGN_IDENTITY" ]] || exit 0
codesign --force --timestamp --sign "$SIGN_IDENTITY" "$DMG"

if ! xcrun notarytool history --keychain-profile "$NOTARY_PROFILE" >/dev/null 2>&1; then
    echo "Signed, but NOT notarized: no '$NOTARY_PROFILE' credentials in the keychain (see scripts/signing.sh)."
    exit 0
fi
echo "Sending to Apple for notarization (usually 1–5 minutes)…"
RESULT=$(xcrun notarytool submit "$DMG" --keychain-profile "$NOTARY_PROFILE" --wait 2>&1 || true)
echo "$RESULT"
if ! grep -q "status: Accepted" <<< "$RESULT"; then
    ID=$(grep -m1 -o 'id: [0-9a-f-]*' <<< "$RESULT" | cut -d' ' -f2)
    echo "Notarization failed. Details: xcrun notarytool log $ID --keychain-profile $NOTARY_PROFILE"
    exit 1
fi
# Attach Apple's approval to the DMG, so it opens without warnings even offline.
xcrun stapler staple "$DMG"
spctl --assess --type open --context context:primary-signature -v "$DMG"
echo "Notarized and stapled: $DMG"
