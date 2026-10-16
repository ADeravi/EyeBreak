#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

BUNDLE="EyeBreak.app"
BIN="EyeBreak"
VER="1.1"
MIN_OS="13.0"

rm -rf "$BUNDLE" stage
mkdir -p "$BUNDLE/Contents/MacOS" "$BUNDLE/Contents/Resources"

# --- Universal binary (Apple Silicon + Intel) ---
swiftc -O -target arm64-apple-macosx$MIN_OS -framework Cocoa -framework UserNotifications -o /tmp/eb_arm64 main.swift
swiftc -O -target x86_64-apple-macosx$MIN_OS -framework Cocoa -framework UserNotifications -o /tmp/eb_x86_64 main.swift
lipo -create /tmp/eb_arm64 /tmp/eb_x86_64 -output "$BUNDLE/Contents/MacOS/$BIN"
rm -f /tmp/eb_arm64 /tmp/eb_x86_64

# --- App icon ---
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
  <key>CFBundleVersion</key><string>1.1</string>
  <key>CFBundleShortVersionString</key><string>1.1</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>LSUIElement</key><true/>
  <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
PLIST

codesign --force --deep --sign - "$BUNDLE"

# --- Installer script (shared with other Macs) ---
cat > install.sh <<'INSTALL'
#!/bin/bash
# Installs Eye Break to /Applications and clears Gatekeeper quarantine.
set -e
APP="EyeBreak.app"
if [ -e "/Applications/$APP" ]; then
  echo "Removing existing copy…"
  rm -rf "/Applications/$APP"
fi
cp -R "$(dirname "$0")/$APP" /Applications/
xattr -dr com.apple.quarantine "/Applications/$APP" 2>/dev/null || true
codesign --force --deep --sign - "/Applications/$APP" 2>/dev/null || true
echo "✅ Installed to /Applications."
echo "   Launch with:  open /Applications/$APP"
INSTALL
chmod +x install.sh

# --- DMG (drag-to-Applications) ---
mkdir -p stage
cp -R "$BUNDLE" stage/
ln -s /Applications stage/Applications
hdiutil create -volname "Eye Break" -srcfolder stage -ov -format UDZO "EyeBreak-$VER.dmg" >/dev/null
rm -rf stage

# --- ZIP ---
ditto -c -k --sequesterRsrc --keepParent "$BUNDLE" "EyeBreak-$VER.zip"

echo "✅ Release complete:"
echo "   - $BUNDLE  (universal)"
echo "   - EyeBreak-$VER.dmg"
echo "   - EyeBreak-$VER.zip"
echo "   - install.sh"
