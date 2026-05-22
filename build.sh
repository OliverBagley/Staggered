#!/bin/bash
set -e

# -----------------------------------------------
# Staggered – build.sh
# Builds the .app bundle using swiftc directly.
# Requirements: Xcode Command Line Tools
#   xcode-select --install
#
# The app can live anywhere — it writes its own
# LaunchAgent plist to ~/Library/LaunchAgents/
# when you toggle "Run at Login" in the GUI.
# -----------------------------------------------

APP_NAME="Staggered"
BINARY_NAME="Staggered"
ICON_FILE="Staggered.icns"
BUILD_DIR="./build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS/MacOS"
RESOURCES_DIR="$CONTENTS/Resources"
SRC_DIR="./Staggered"
ICONSET="$SRC_DIR/AppIcon.iconset"

echo "🔨  Building $APP_NAME..."

rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

if [ -d "$ICONSET" ]; then
    if command -v iconutil >/dev/null 2>&1; then
        iconutil -c icns "$ICONSET" -o "$RESOURCES_DIR/$ICON_FILE"
        echo "📦  Built app icon: $ICON_FILE"
    else
        echo "⚠️  iconutil is not available on this system; the icon will not be built."
    fi
fi

SOURCES=$(find "$SRC_DIR" -name "*.swift" | tr '\n' ' ')

ARCH=$(uname -m)
if [ "$ARCH" = "arm64" ]; then
    TARGET="arm64-apple-macos13.0"
else
    TARGET="x86_64-apple-macos13.0"
fi
SDK=$(xcrun --show-sdk-path)

swiftc $SOURCES \
    -o "$MACOS_DIR/$BINARY_NAME" \
    -framework SwiftUI \
    -framework AppKit \
    -framework Foundation \
    -framework UniformTypeIdentifiers \
    -sdk "$SDK" \
    -target "$TARGET" \
    -module-name Staggered

cp "$SRC_DIR/Info.plist" "$CONTENTS/Info.plist"

echo ""
echo "✅  Done: $APP_BUNDLE"
echo ""
echo "   Move the app somewhere permanent before enabling login item,"
echo "   e.g. ~/Applications/ or /Applications/ — the LaunchAgent plist"
echo "   stores the absolute executable path, so don't move it afterwards."
echo ""
echo "   open \"$APP_BUNDLE\""
echo ""
