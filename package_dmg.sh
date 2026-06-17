#!/bin/bash
set -e

# Configuration
APP_NAME="ClipFlow"
BUILD_DIR="build/DerivedData/Build/Products/Debug"
APP_PATH="${BUILD_DIR}/${APP_NAME}.app"
DMG_DIR="build/dmg-temp"
DMG_PATH="build/${APP_NAME}.dmg"

echo "Packaging ${APP_NAME} into DMG..."

# Verify the app exists
if [ ! -d "$APP_PATH" ]; then
    echo "Error: ${APP_PATH} does not exist. Please run xcodebuild first."
    exit 1
fi

# Clean up old DMG and temp directory
rm -f "$DMG_PATH"
rm -rf "$DMG_DIR"
mkdir -p "$DMG_DIR"

# Copy the app to the temp directory
cp -R "$APP_PATH" "$DMG_DIR/"

# Create a symlink to Applications directory
ln -s /Applications "$DMG_DIR/Applications"

# Create the DMG using hdiutil
hdiutil create -volname "${APP_NAME}" -srcfolder "$DMG_DIR" -ov -format UDZO "$DMG_PATH"

# Clean up temp directory
rm -rf "$DMG_DIR"

echo "DMG successfully created at ${DMG_PATH}"
