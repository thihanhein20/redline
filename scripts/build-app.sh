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
mkdir -p "$APP/Contents/MacOS"
# The hook must sit next to the executable; GameLauncher looks for it there.
cp "$BIN/Redline" "$BIN/libRedlineHook.dylib" "$APP/Contents/MacOS/"

cat > "$APP/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>               <string>Redline</string>
    <key>CFBundleDisplayName</key>        <string>Redline</string>
    <key>CFBundleIdentifier</key>         <string>com.thihanhein20.redline</string>
    <key>CFBundleExecutable</key>         <string>Redline</string>
    <key>CFBundlePackageType</key>        <string>APPL</string>
    <key>CFBundleShortVersionString</key> <string>$VERSION</string>
    <key>CFBundleVersion</key>            <string>$VERSION</string>
    <key>LSMinimumSystemVersion</key>     <string>14.0</string>
    <key>LSUIElement</key>                <true/>
    <key>NSHumanReadableCopyright</key>   <string>© $(date +%Y) Thihan Hein</string>
</dict>
</plist>
EOF

# Ad-hoc signature: runs on this Mac. Public releases need a Developer ID signature + notarization.
codesign --force --sign - "$APP/Contents/MacOS/libRedlineHook.dylib"
codesign --force --sign - "$APP"

echo "Built $APP (version $VERSION)"
