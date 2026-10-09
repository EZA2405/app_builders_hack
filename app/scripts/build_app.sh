#!/bin/zsh
# Build ScreenGuide.app and sign it with the local Apple Development identity.
# A stable signature keeps the Accessibility permission valid across rebuilds.
set -euo pipefail
cd "${0:A:h}/.."

swift build -c release
BIN=.build/release/ScreenGuide
APP=build/ScreenGuide.app

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp "$BIN" "$APP/Contents/MacOS/ScreenGuide"
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleIdentifier</key><string>dev.alexi.screenguide</string>
  <key>CFBundleName</key><string>Gabay</string>
  <key>CFBundleDisplayName</key><string>Gabay</string>
  <key>CFBundleExecutable</key><string>ScreenGuide</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>0.1</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSMinimumSystemVersion</key><string>26.0</string>
  <key>LSUIElement</key><true/>
  <key>NSMicrophoneUsageDescription</key><string>So you can say what you want to do.</string>
  <key>NSSpeechRecognitionUsageDescription</key><string>To turn what you say into words, on this Mac.</string>
</dict>
</plist>
PLIST

IDENTITY=$(security find-identity -v -p codesigning | awk -F'"' '/Apple Development/ {print $2; exit}')
codesign --force --sign "$IDENTITY" "$APP"
codesign -dv "$APP" 2>&1 | grep -E "Identifier|Authority=Apple Development" || true
echo "built $APP"
