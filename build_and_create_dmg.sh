#!/bin/bash

# Script to build LeetCode Widget and create a DMG file
# Usage: ./build_and_create_dmg.sh [--sign "SIGNING_IDENTITY"]
#
# To sign the app:
#   1. First create a signing identity in Xcode (Settings → Accounts → Manage Certificates)
#   2. Find your identity: security find-identity -v -p codesigning
#   3. Run: ./build_and_create_dmg.sh --sign "Apple Development: Your Name (TEAMID)"

set -e

PROJECT_NAME="LeetCodeWidget"
SCHEME="LeetCodeWidget macOS"
APP_NAME="LeetCodeWidget macOS.app"
DMG_NAME="LeetCodeWidget.dmg"
BUILD_DIR="build"
DMG_DIR="dmg_temp"
SIGNING_IDENTITY=""

# Parse arguments
if [ "$1" == "--sign" ] && [ -n "$2" ]; then
    SIGNING_IDENTITY="$2"
    echo "📝 Will sign with: $SIGNING_IDENTITY"
fi

echo "🚀 Building LeetCode Widget..."

# Clean previous builds
rm -rf "$BUILD_DIR"
rm -rf "$DMG_DIR"
rm -f "$DMG_NAME"

# Create directories
mkdir -p "$BUILD_DIR"
mkdir -p "$DMG_DIR"

# Build both the app and widget extension
echo "📦 Building app and widget extension..."
xcodebuild \
    -project "$PROJECT_NAME.xcodeproj" \
    -scheme "$SCHEME" \
    -configuration Release \
    -derivedDataPath "$BUILD_DIR" \
    clean build \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO

# Also build the widget extension
echo "📦 Building widget extension..."
xcodebuild \
    -project "$PROJECT_NAME.xcodeproj" \
    -scheme "LeetCodeWidget Extension" \
    -configuration Release \
    -derivedDataPath "$BUILD_DIR" \
    build \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO

# Find the built app
APP_PATH=$(find "$BUILD_DIR" -name "$APP_NAME" -type d | head -1)

if [ -z "$APP_PATH" ]; then
    echo "❌ Error: Could not find built app"
    exit 1
fi

echo "✅ App built successfully at: $APP_PATH"

# Find and embed the widget extension
WIDGET_EXTENSION_NAME="LeetCodeWidget Extension.appex"
WIDGET_EXTENSION_PATH=$(find "$BUILD_DIR" -name "$WIDGET_EXTENSION_NAME" -type d | head -1)

if [ -z "$WIDGET_EXTENSION_PATH" ]; then
    echo "⚠️  Warning: Could not find widget extension, widget may not work"
else
    echo "✅ Widget extension found at: $WIDGET_EXTENSION_PATH"
    # Embed the widget extension in the app
    WIDGET_DEST="$APP_PATH/Contents/PlugIns/$WIDGET_EXTENSION_NAME"
    mkdir -p "$APP_PATH/Contents/PlugIns"
    cp -R "$WIDGET_EXTENSION_PATH" "$WIDGET_DEST"
    echo "✅ Widget extension embedded in app"
fi

# Sign the app if identity provided
if [ -n "$SIGNING_IDENTITY" ]; then
    echo "📝 Signing app and widget extension..."
    
    WIDGET_EXT_PATH="$APP_PATH/Contents/PlugIns/LeetCodeWidget Extension.appex"
    
    if [ -d "$WIDGET_EXT_PATH" ]; then
        echo "   Signing widget extension..."
        codesign --force --deep --sign "$SIGNING_IDENTITY" "$WIDGET_EXT_PATH" || {
            echo "⚠️  Warning: Failed to sign widget extension"
        }
    fi
    
    echo "   Signing main app..."
    codesign --force --deep --sign "$SIGNING_IDENTITY" "$APP_PATH" || {
        echo "⚠️  Warning: Failed to sign app"
    }
    
    echo "   Verifying signatures..."
    codesign -dv "$APP_PATH" 2>&1 | head -3
    echo "✅ Signing complete"
fi

# Copy app to DMG directory
echo "📋 Preparing DMG..."
cp -R "$APP_PATH" "$DMG_DIR/"

# Create a symlink to Applications folder (optional, for user convenience)
ln -s /Applications "$DMG_DIR/Applications"

# Create DMG
echo "💿 Creating DMG file..."

# Calculate size needed (add 20MB buffer)
SIZE=$(du -sm "$DMG_DIR" | cut -f1)
SIZE=$((SIZE + 20))

hdiutil create -srcfolder "$DMG_DIR" -volname "LeetCode Widget" -fs HFS+ \
    -fsargs "-c c=64,a=16,e=16" -format UDRW -size ${SIZE}M "$DMG_NAME.temp.dmg"

# Mount the DMG
DEVICE=$(hdiutil attach -readwrite -noverify -noautoopen "$DMG_NAME.temp.dmg" | \
    egrep '^/dev/' | sed 1q | awk '{print $1}')

# Wait a moment for the device to be ready
sleep 2

# Set volume icon and background (optional - you can customize this)
# For now, we'll just set the window position and size

# Unmount
hdiutil detach "$DEVICE"

# Convert to final compressed DMG
hdiutil convert "$DMG_NAME.temp.dmg" -format UDZO -imagekey zlib-level=9 -o "$DMG_NAME"

# Clean up
rm -f "$DMG_NAME.temp.dmg"
rm -rf "$DMG_DIR"

echo "✅ DMG created successfully: $DMG_NAME"
echo ""
if [ -z "$SIGNING_IDENTITY" ]; then
    echo "📝 Note: This DMG contains an unsigned app."
    echo "   On first launch, macOS may show a security warning."
    echo "   To fix this:"
    echo "   1. Right-click the app → Open"
    echo "   2. Click 'Open' in the security dialog"
    echo "   Or: System Settings → Privacy & Security → Allow the app"
    echo ""
    echo "   To sign the app, run:"
    echo "   ./build_and_create_dmg.sh --sign \"YOUR_SIGNING_IDENTITY\""
    echo "   (First create identity in Xcode: Settings → Accounts → Manage Certificates)"
else
    echo "✅ App is signed and ready for distribution"
fi
echo ""
echo "🎉 Done! You can now distribute $DMG_NAME"

