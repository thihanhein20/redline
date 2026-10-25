#!/bin/zsh
# Builds a double-clickable Redline.app into ./build
#   scripts/build-app.sh            → build/Redline.app
#   open build/Redline.app          → run it
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION=$(sed -n 's/.*appVersion = "\(.*\)"/\1/p' Sources/Redline/Support/SystemInfo.swift)
APP=build/Redline.app

swift build -c release
BIN=$(swift build -c release --show-bin-path)

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
# The hook must sit next to the executable; GameLauncher looks for it there.
cp "$BIN/Redline" "$BIN/libRedlineHook.dylib" "$APP/Contents/MacOS/"

# App icon: Resources/AppIcon.png (from scripts/make-icon.swift) → every size macOS needs → AppIcon.icns
ICONSET=$(mktemp -d)/AppIcon.iconset
mkdir -p "$ICONSET"
for px in 16 32 128 256 512; do
    sips -z $px $px Resources/AppIcon.png --out "$ICONSET/icon_${px}x${px}.png" >/dev/null
    sips -z $((px * 2)) $((px * 2)) Resources/AppIcon.png --out "$ICONSET/icon_${px}x${px}@2x.png" >/dev/null
done
iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"

cat > "$APP/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>               <string>Redline</string>
    <key>CFBundleDisplayName</key>        <string>Redline</string>
    <key>CFBundleIdentifier</key>         <string>com.thihanhein20.redline</string>
    <key>CFBundleExecutable</key>         <string>Redline</string>
    <key>CFBundleIconFile</key>           <string>AppIcon</string>
    <key>CFBundlePackageType</key>        <string>APPL</string>
    <key>CFBundleShortVersionString</key> <string>$VERSION</string>
    <key>CFBundleVersion</key>            <string>$VERSION</string>
    <key>LSMinimumSystemVersion</key>     <string>14.0</string>
    <key>LSUIElement</key>                <true/>
    <key>NSHumanReadableCopyright</key>   <string>© $(date +%Y) Han Industries</string>
</dict>
</plist>
EOF

source scripts/signing.sh
# Inside out: the hook library first, then the app around it.
if [[ -n "$SIGN_IDENTITY" ]]; then
    # Developer ID + Hardened Runtime + secure timestamp: what Apple's notarization requires.
    for target in "$APP/Contents/MacOS/libRedlineHook.dylib" "$APP"; do
        codesign --force --options runtime --timestamp --sign "$SIGN_IDENTITY" "$target"
    done
    echo "Signed with $SIGN_IDENTITY"
else
    codesign --force --sign - "$APP/Contents/MacOS/libRedlineHook.dylib"
    codesign --force --sign - "$APP"
    echo "No Developer ID certificate found: ad-hoc signed (fine on this Mac; downloads will get Gatekeeper warnings)"
fi

echo "Built $APP (version $VERSION)"
