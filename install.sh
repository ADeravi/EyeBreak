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
