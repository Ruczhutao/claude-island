#!/bin/bash
# Build Agent Island for GitHub Release (local ad-hoc signing)
# Users need to right-click open or clear quarantine manually

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/build"
RELEASE_DIR="$PROJECT_DIR/releases"

echo "=== Building Agent Island for GitHub Release ==="
echo ""

# Clean previous builds
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
mkdir -p "$RELEASE_DIR"

cd "$PROJECT_DIR"

# Build Release version
echo "Building..."
xcodebuild -project ClaudeIsland.xcodeproj \
    -scheme ClaudeIsland \
    -configuration Release \
    -destination "generic/platform=macOS" \
    -derivedDataPath "$BUILD_DIR/DerivedData" \
    CODE_SIGN_STYLE=Automatic \
    CODE_SIGN_IDENTITY="-" \
    CODE_SIGNING_REQUIRED=NO \
    | tee "$BUILD_DIR/build.log" || {
        echo "Build failed"
        exit 1
    }

# Find the built app
APP_PATH=$(find "$BUILD_DIR/DerivedData" -name "Claude Island.app" -type d | head -1)

if [ -z "$APP_PATH" ]; then
    echo "ERROR: Could not find built app"
    exit 1
fi

echo "✓ Built: $APP_PATH"

# Re-sign
echo "Signing..."
SPARKLE_PATH="$APP_PATH/Contents/Frameworks/Sparkle.framework"
if [ -d "$SPARKLE_PATH" ]; then
    codesign --remove-signature "$SPARKLE_PATH" 2>/dev/null || true
    codesign --force --deep --sign - "$SPARKLE_PATH"
fi

codesign --remove-signature "$APP_PATH" 2>/dev/null || true
codesign --force --deep --sign - "$APP_PATH"

# Copy resources
mkdir -p "$APP_PATH/Contents/Resources/Sounds"
cp -R "$PROJECT_DIR/ClaudeIsland/Resources/Sounds/"*.mp3 "$APP_PATH/Contents/Resources/Sounds/"
xattr -cr "$APP_PATH"

# Get version
VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP_PATH/Contents/Info.plist")
echo "✓ Version: $VERSION"

# Create DMG
DMG_TEMP="$BUILD_DIR/dmg-temp"
rm -rf "$DMG_TEMP"
mkdir -p "$DMG_TEMP"
cp -R "$APP_PATH" "$DMG_TEMP/Agent Island.app"
xattr -cr "$DMG_TEMP/Agent Island.app"
ln -s /Applications "$DMG_TEMP/Applications"

DMG_PATH="$RELEASE_DIR/AgentIsland-$VERSION.dmg"
rm -f "$DMG_PATH"

TEMP_DMG="$BUILD_DIR/temp.dmg"
hdiutil create -srcfolder "$DMG_TEMP" -volname "Agent Island" -fs HFS+ \
    -format UDRW -size $(($(du -sm "$DMG_TEMP" | cut -f1) + 20))m "$TEMP_DMG"

# Mount and layout
hdiutil attach "$TEMP_DMG" -nobrowse 2>/dev/null
sleep 2

osascript <<EOF 2>/dev/null || true
tell application "Finder"
    tell disk "Agent Island"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set bounds of container window to {400, 100, 885, 430}
        set viewOptions to icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 100
        set position of item "Agent Island.app" of container window to {120, 170}
        set position of item "Applications" of container window to {365, 170}
        close
        open
        update without registering applications
        delay 2
    end tell
end tell
EOF

hdiutil detach "/Volumes/Agent Island" -force 2>/dev/null || true
sleep 1

# Convert
hdiutil convert "$TEMP_DMG" -format UDZO -o "$DMG_PATH"

# For GitHub Release: DO NOT add quarantine attribute
# Users will need to right-click open

# Clean up
rm -f "$TEMP_DMG"
rm -rf "$DMG_TEMP"

# Calculate checksum
cd "$RELEASE_DIR"
shasum -a 256 "AgentIsland-$VERSION.dmg" > "AgentIsland-$VERSION.dmg.sha256"

echo ""
echo "=== Build Complete ==="
echo ""
echo "File: $RELEASE_DIR/AgentIsland-$VERSION.dmg"
echo "Size: $(du -h "$DMG_PATH" | cut -f1)"
echo "SHA256: $(cat "$DMG_PATH.sha256" | cut -d' ' -f1)"
echo ""
echo "Upload to GitHub Releases:"
echo "1. Go to https://github.com/YOURNAME/claude-island/releases"
echo "2. Create new release v$VERSION"
echo "3. Upload AgentIsland-$VERSION.dmg"
echo "4. Copy release notes from scripts/release-notes-template.md"
