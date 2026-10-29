#!/bin/zsh
# Compila CmdBoard y genera CmdBoard.app (sin firma; solo uso local).
set -e
cd "$(dirname "$0")"
swift build -c release
APP=CmdBoard.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp .build/release/CmdBoard "$APP/Contents/MacOS/CmdBoard"
cp Resources/AppIcon.icns Resources/logo.png "$APP/Contents/Resources/"
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleName</key><string>CmdBoard</string>
<key>CFBundleIdentifier</key><string>local.mossa.cmdboard</string>
<key>CFBundleExecutable</key><string>CmdBoard</string>
<key>CFBundleIconFile</key><string>AppIcon</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleVersion</key><string>1</string>
<key>LSMinimumSystemVersion</key><string>14.0</string>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
echo "Listo: $PWD/$APP"
