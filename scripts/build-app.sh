#!/bin/bash
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "HalfLight requires macOS 13 or later to build and run." >&2
    exit 1
fi
if ! xcrun --find swift >/dev/null 2>&1; then
    echo "Install Xcode Command Line Tools first: xcode-select --install" >&2
    exit 1
fi

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"
BUILD_ARGS=(-c release)
if [[ "${1:-}" == "--universal" ]]; then
    BUILD_ARGS+=(--arch arm64 --arch x86_64)
elif [[ $# -gt 0 ]]; then
    echo "Usage: $0 [--universal]" >&2
    exit 1
fi
swift build "${BUILD_ARGS[@]}"
BIN_DIR="$(swift build "${BUILD_ARGS[@]}" --show-bin-path)"
APP_DIR="$PROJECT_DIR/dist/HalfLight.app"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
cp "$BIN_DIR/HalfLight" "$APP_DIR/Contents/MacOS/HalfLight"
cp "$PROJECT_DIR/Info.plist" "$APP_DIR/Contents/Info.plist"
swift "$PROJECT_DIR/scripts/make-icon.swift" "$PROJECT_DIR/dist"
iconutil -c icns "$PROJECT_DIR/dist/AppIcon.iconset" -o "$APP_DIR/Contents/Resources/AppIcon.icns"
plutil -lint "$APP_DIR/Contents/Info.plist"
codesign --force --sign - "$APP_DIR"
codesign --verify --strict "$APP_DIR"
if [[ "${1:-}" == "--universal" ]]; then
    lipo "$APP_DIR/Contents/MacOS/HalfLight" -verify_arch arm64 x86_64
fi
ditto -c -k --sequesterRsrc --keepParent "$APP_DIR" "$PROJECT_DIR/dist/HalfLight-macOS.zip"
INSTALLER_DIR="$(mktemp -d "$PROJECT_DIR/dist/installer.XXXXXX")"
trap 'rm -rf "$INSTALLER_DIR"' EXIT
ditto "$APP_DIR" "$INSTALLER_DIR/HalfLight.app"
ln -s /Applications "$INSTALLER_DIR/Applications"
hdiutil create -ov -volname HalfLight -srcfolder "$INSTALLER_DIR" -format UDZO "$PROJECT_DIR/dist/HalfLight.dmg"
echo "Built: $APP_DIR"
echo "Installer: $PROJECT_DIR/dist/HalfLight.dmg"
echo "Launch: open \"$APP_DIR\""
