#!/bin/bash
# Build Claude Island for local testing (no developer-id signing required)
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/build"
RELEASE_DIR="$PROJECT_DIR/releases"

echo "=== Building Agent Island (Local Test) ==="
echo ""

# Clean previous builds and remove all extended attributes
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
mkdir -p "$RELEASE_DIR"

# Clean extended attributes from release directory
xattr -cr "$RELEASE_DIR" 2>/dev/null || true

cd "$PROJECT_DIR"

# Build for local testing (Release configuration but without developer-id)
echo "Building Release version..."
xcodebuild -project ClaudeIsland.xcodeproj \
    -scheme ClaudeIsland \
    -configuration Release \
    -destination "generic/platform=macOS" \
    -derivedDataPath "$BUILD_DIR/DerivedData" \
    CODE_SIGN_STYLE=Automatic \
    CODE_SIGN_IDENTITY="-" \
    CODE_SIGNING_REQUIRED=NO \
    | tee "$BUILD_DIR/build.log" || {
        echo "Build failed, check $BUILD_DIR/build.log"
        exit 1
    }

# Find the built app
APP_PATH=$(find "$BUILD_DIR/DerivedData" -name "Claude Island.app" -type d | head -1)

if [ -z "$APP_PATH" ]; then
    echo "ERROR: Could not find built app"
    exit 1
fi

echo ""
echo "App built at: $APP_PATH"

# Re-sign Sparkle framework with ad-hoc signature to match app signature
echo "Re-signing Sparkle framework..."
SPARKLE_PATH="$APP_PATH/Contents/Frameworks/Sparkle.framework"
if [ -d "$SPARKLE_PATH" ]; then
    # Remove existing signature
    codesign --remove-signature "$SPARKLE_PATH" 2>/dev/null || true
    # Re-sign with ad-hoc (-)
    codesign --force --deep --sign - "$SPARKLE_PATH"
    echo "Sparkle framework re-signed"
fi

# Also re-sign the app itself to ensure consistency
echo "Re-signing app..."
codesign --remove-signature "$APP_PATH" 2>/dev/null || true
codesign --force --deep --sign - "$APP_PATH"

# Copy sound files to app bundle
SOUNDS_DEST="$APP_PATH/Contents/Resources/Sounds"
mkdir -p "$SOUNDS_DEST"
cp -R "$PROJECT_DIR/ClaudeIsland/Resources/Sounds/"*.mp3 "$SOUNDS_DEST/"
echo "Copied sound files to $SOUNDS_DEST"

# Clean extended attributes from app
xattr -cr "$APP_PATH"

# Get version
VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP_PATH/Contents/Info.plist")
BUILD=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$APP_PATH/Contents/Info.plist")

echo "Version: $VERSION (build $BUILD)"
echo ""

# Create a temporary directory for DMG contents
DMG_TEMP="$BUILD_DIR/dmg-temp"
rm -rf "$DMG_TEMP"
mkdir -p "$DMG_TEMP"

# Copy app to temp directory with correct name
cp -R "$APP_PATH" "$DMG_TEMP/Agent Island.app"

# Clean extended attributes from copied app
xattr -cr "$DMG_TEMP/Agent Island.app"

# Create Applications folder symlink
ln -s /Applications "$DMG_TEMP/Applications"

# Create DMG with standard layout
echo "Creating DMG..."
DMG_PATH="$RELEASE_DIR/AgentIsland-$VERSION-local.dmg"

# Remove existing DMG if present
if [ -f "$DMG_PATH" ]; then
    rm -f "$DMG_PATH"
fi

# Calculate size needed (app size + 20MB margin)
APP_SIZE=$(du -sm "$DMG_TEMP" | cut -f1)
DMG_SIZE=$((APP_SIZE + 20))

# Create temporary DMG
TEMP_DMG="$BUILD_DIR/temp.dmg"
hdiutil create -srcfolder "$DMG_TEMP" -volname "Agent Island" -fs HFS+ \
    -format UDRW -size ${DMG_SIZE}m "$TEMP_DMG"

# Clean extended attributes from temp DMG
xattr -cr "$TEMP_DMG"

# Mount the DMG
MOUNT_POINT="/Volumes/Agent Island"
echo "Mounting DMG for layout..."
hdiutil attach "$TEMP_DMG" -nobrowse

# Wait for mount
sleep 2

# Use AppleScript to set icon positions
echo "Setting DMG layout..."
osascript <<EOF
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
        
        -- Position items
        set position of item "Agent Island.app" of container window to {120, 170}
        set position of item "Applications" of container window to {365, 170}
        
        close
        open
        update without registering applications
        delay 2
    end tell
end tell
EOF

# Unmount
hdiutil detach "$MOUNT_POINT" -force

# Convert to compressed read-only DMG
echo "Compressing DMG..."
hdiutil convert "$TEMP_DMG" -format UDZO -o "$DMG_PATH"

# Note: For local unsigned builds, quarantine attribute causes "damaged" error
# Remove it for local builds. For distribution, add:
# xattr -w com.apple.quarantine "0082;<timestamp>;Developer;" "$DMG_PATH"
echo "Removing quarantine for local build..."
xattr -cr "$DMG_PATH"

# Clean up
rm -f "$TEMP_DMG"
rm -rf "$DMG_TEMP"

echo ""
echo "=== Build Complete ==="
echo ""
echo "DMG location: $DMG_PATH"
echo ""
echo "To install:"
echo "1. Double-click the DMG to mount it"
echo "2. Drag 'Agent Island.app' to the Applications folder"
echo "3. Launch from Applications"
echo ""
echo "Note: Since this is a local build, you may see a Gatekeeper warning."
echo "To open anyway: Right-click the app → Open → Open"
