#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

BUNDLE="EyeBreak.app"
BIN_NAME="EyeBreak"

rm -rf "$BUNDLE"
mkdir -p "$BUNDLE/Contents/MacOS" "$BUNDLE/Contents/Resources"

swiftc -O \
  -framework Cocoa \
  -framework ServiceManagement \
  -framework UserNotifications \
  -o "$BUNDLE/Contents/MacOS/$BIN_NAME" \
  main.swift

# --- Generate app icon ---
swiftc -O -framework AppKit -o makeicon makeicon.swift
./makeicon

mkdir -p EyeBreak.iconset
sips -z 16   16   icon_1024.png --out EyeBreak.iconset/icon_16x16.png       >/dev/null
sips -z 32   32   icon_1024.png --out EyeBreak.iconset/icon_16x16@2x.png    >/dev/null
sips -z 32   32   icon_1024.png --out EyeBreak.iconset/icon_32x32.png       >/dev/null
sips -z 64   64   icon_1024.png --out EyeBreak.iconset/icon_32x32@2x.png    >/dev/null
sips -z 128  128  icon_1024.png --out EyeBreak.iconset/icon_128x128.png     >/dev/null
sips -z 256  256  icon_1024.png --out EyeBreak.iconset/icon_128x128@2x.png  >/dev/null
sips -z 256  256  icon_1024.png --out EyeBreak.iconset/icon_256x256.png     >/dev/null
sips -z 512  512  icon_1024.png --out EyeBreak.iconset/icon_256x256@2x.png  >/dev/null
sips -z 512  512  icon_1024.png --out EyeBreak.iconset/icon_512x512.png     >/dev/null
sips -z 1024 1024 icon_1024.png --out EyeBreak.iconset/icon_512x512@2x.png  >/dev/null

iconutil -c icns EyeBreak.iconset -o "$BUNDLE/Contents/Resources/AppIcon.icns"
rm -rf EyeBreak.iconset makeicon icon_1024.png

# --- Info.plist ---
cat > "$BUNDLE/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>Eye Break</string>
  <key>CFBundleDisplayName</key><string>Eye Break</string>
  <key>CFBundleIdentifier</key><string>com.ad.eyebreak</string>
  <key>CFBundleExecutable</key><string>EyeBreak</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundleVersion</key><string>1.2</string>
  <key>CFBundleShortVersionString</key><string>1.2</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>LSUIElement</key><true/>
  <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
PLIST

codesign --force --deep --sign - "$BUNDLE"

echo "✅ Built $BUNDLE"
