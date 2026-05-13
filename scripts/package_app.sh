#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="CleanKey"
PRODUCT_NAME="CleanKey"
CONFIGURATION="${CONFIGURATION:-release}"
VERSION="$(tr -d '[:space:]' < "$ROOT_DIR/version.txt")"
BUILD_DIR="$ROOT_DIR/.build"
APP_OUTPUT_DIR="$BUILD_DIR/app"
APP_PATH="$APP_OUTPUT_DIR/$APP_NAME.app"
ZIP_PATH="$APP_OUTPUT_DIR/$APP_NAME.zip"
DMG_STAGING="$APP_OUTPUT_DIR/dmg"
DMG_PATH="$APP_OUTPUT_DIR/$APP_NAME.dmg"
ICON_PATH="$ROOT_DIR/Packaging/$APP_NAME.icns"

swift build -c "$CONFIGURATION" --product "$PRODUCT_NAME"

if [[ ! -f "$ICON_PATH" ]]; then
  swift "$ROOT_DIR/scripts/generate_app_icon.swift" "$ROOT_DIR"
  iconutil -c icns "$ROOT_DIR/Packaging/$APP_NAME.iconset" -o "$ICON_PATH"
fi

rm -rf "$APP_PATH" "$ZIP_PATH" "$DMG_PATH" "$DMG_STAGING"
mkdir -p "$APP_PATH/Contents/MacOS" "$APP_PATH/Contents/Resources"

cp "$BUILD_DIR/$CONFIGURATION/$PRODUCT_NAME" "$APP_PATH/Contents/MacOS/$APP_NAME"
cp "$ROOT_DIR/Packaging/Info.plist" "$APP_PATH/Contents/Info.plist"
cp "$ICON_PATH" "$APP_PATH/Contents/Resources/$APP_NAME.icns"
chmod +x "$APP_PATH/Contents/MacOS/$APP_NAME"

/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$APP_PATH/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${BUILD_NUMBER:-$VERSION}" "$APP_PATH/Contents/Info.plist"

if [[ -n "${CODESIGN_IDENTITY:-}" ]]; then
  codesign --force --deep --options runtime --timestamp --sign "$CODESIGN_IDENTITY" "$APP_PATH"
else
  codesign --force --deep --sign - "$APP_PATH"
fi
codesign --verify --deep --strict --verbose=2 "$APP_PATH"

ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"

mkdir -p "$DMG_STAGING"
cp -R "$APP_PATH" "$DMG_STAGING/$APP_NAME.app"
ln -s /Applications "$DMG_STAGING/Applications"
hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$DMG_STAGING" \
  -ov \
  -format UDZO \
  "$DMG_PATH"
rm -rf "$DMG_STAGING"

if [[ -n "${CODESIGN_IDENTITY:-}" ]]; then
  codesign --force --timestamp --sign "$CODESIGN_IDENTITY" "$DMG_PATH"
fi

echo "$APP_PATH"
echo "$ZIP_PATH"
echo "$DMG_PATH"
