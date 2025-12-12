#!/bin/bash
set -e

# Configuration (debug or release)
CONFIG="${1:-debug}"

if [ "$CONFIG" != "debug" ] && [ "$CONFIG" != "release" ]; then
    echo "Usage: $0 [debug|release]"
    exit 1
fi

echo "Building $CONFIG configuration..."

# Build the executable
swift build -c $CONFIG

# Create app bundle structure
APP_NAME="Speakeasy.app"
if [ "$CONFIG" = "release" ]; then
    APP_DIR="build/$APP_NAME"
else
    APP_DIR=".build/debug/$APP_NAME"
fi

CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "Creating app bundle structure..."
rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Copy executable
echo "Copying executable..."
cp .build/$CONFIG/Speakeasy "$MACOS_DIR/"

# Copy Info.plist
echo "Copying Info.plist..."
cp Speakeasy/Resources/Info.plist "$CONTENTS_DIR/"

# Set executable permissions
chmod +x "$MACOS_DIR/Speakeasy"

echo ""
echo "✅ App bundle created at: $APP_DIR"
if [ "$CONFIG" = "release" ]; then
    echo ""
    echo "To install:"
    echo "  cp -r $APP_DIR /Applications/"
    echo ""
    echo "Or drag and drop $APP_DIR to your Applications folder"
else
    echo "Launch with: open $APP_DIR"
fi
