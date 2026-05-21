#!/bin/bash
set -e

# -----------------------------------------------
# Startup Delayer – build.sh
# Builds the app bundle using swiftc (no Xcode project needed)
# Requirements: Xcode Command Line Tools (xcode-select --install)
#
# IMPORTANT: The app must live in /Applications for SMAppService
# (Login Item registration) to work. After building, run:
#   cp -r "build/Startup Delayer.app" /Applications/
# -----------------------------------------------

APP_NAME="Startup Delayer"
BINARY_NAME="StartupDelayer"
BUILD_DIR="./build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS/MacOS"
RESOURCES_DIR="$CONTENTS/Resources"
SRC_DIR="./StartupDelayer"

echo "🔨  Building $APP_NAME..."

# Clean previous build
rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

# Gather Swift sources
SOURCES=$(find "$SRC_DIR" -name "*.swift" | tr '\n' ' ')

# Detect architecture
ARCH=$(uname -m)
if [ "$ARCH" = "arm64" ]; then
    TARGET="arm64-apple-macos13.0"
else
    TARGET="x86_64-apple-macos13.0"
fi

SDK=$(xcrun --show-sdk-path)

# Compile
swiftc $SOURCES \
    -o "$MACOS_DIR/$BINARY_NAME" \
    -framework SwiftUI \
    -framework AppKit \
    -framework Foundation \
    -framework ServiceManagement \
    -framework UniformTypeIdentifiers \
    -sdk "$SDK" \
    -target "$TARGET" \
    -Onone \
    -module-name StartupDelayer

# Copy Info.plist
cp "$SRC_DIR/Info.plist" "$CONTENTS/Info.plist"

echo ""
echo "✅  Done: $APP_BUNDLE"
echo ""
echo "   Next steps:"
echo "   1. Copy to /Applications (required for Login Item registration):"
echo "      cp -r \"$APP_BUNDLE\" /Applications/"
echo ""
echo "   2. Open the app and toggle 'Run at Login'"
echo ""
echo "   That's it. The app registers itself — no separate launcher needed."
echo ""
