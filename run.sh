#!/bin/bash
set -e

cd "$(dirname "$0")"

APP_NAME="Speakeasy"
PKG_PATH="Speakeasy"
RESOURCES="$PKG_PATH/Speakeasy/Resources"
ENTITLEMENTS="$RESOURCES/Speakeasy.entitlements"
MAS_ENTITLEMENTS="$RESOURCES/Speakeasy-MAS.entitlements"
BUILD_DIR="build"

# Default signing identity (override with CODESIGN_IDENTITY env var)
CODESIGN_IDENTITY="${CODESIGN_IDENTITY:-Developer ID Application: Miguel Pereira Torcato David (F6RMP8HFLW)}"
MAS_APP_IDENTITY="${MAS_APP_IDENTITY:-3rd Party Mac Developer Application: Miguel Pereira Torcato David (F6RMP8HFLW)}"
MAS_INSTALLER_IDENTITY="${MAS_INSTALLER_IDENTITY:-3rd Party Mac Developer Installer: Miguel Pereira Torcato David (F6RMP8HFLW)}"
NOTARY_PROFILE="${NOTARY_PROFILE:-notarytool-profile}"

usage() {
    cat <<EOF
Usage: $0 [command] [options]

Commands:
  (no args)          Build and run via swift run
  build [debug|release]  Build .app bundle
  sign               Code sign the release .app
  dmg <version>      Create signed + notarized DMG
  mas <version>      Create MAS .pkg
  release <version>  Full pipeline: build → sign → dmg → notarize

Environment variables:
  CODESIGN_IDENTITY       Developer ID signing identity
  MAS_APP_IDENTITY        MAS app signing identity
  MAS_INSTALLER_IDENTITY  MAS installer signing identity
  NOTARY_PROFILE          Notarytool keychain profile name
EOF
}

# Build .app bundle
cmd_build() {
    local config="${1:-debug}"

    if [ "$config" != "debug" ] && [ "$config" != "release" ]; then
        echo "Usage: $0 build [debug|release]"
        exit 1
    fi

    echo "Building $config configuration..."
    swift build -c "$config" --package-path "$PKG_PATH"

    if [ "$config" = "release" ]; then
        local app_name="$APP_NAME.app"
    else
        local app_name="$APP_NAME-build.app"
    fi

    local app_dir="$BUILD_DIR/$config/$app_name"
    local contents="$app_dir/Contents"

    echo "Creating app bundle..."
    rm -rf "$app_dir"
    mkdir -p "$contents/MacOS"
    mkdir -p "$contents/Resources"

    cp "$PKG_PATH/.build/$config/$APP_NAME" "$contents/MacOS/"
    cp "$RESOURCES/Info.plist" "$contents/"
    chmod +x "$contents/MacOS/$APP_NAME"

    echo "App bundle created: $app_dir"
}

# Code sign the release .app
cmd_sign() {
    local app_dir="$BUILD_DIR/release/$APP_NAME.app"

    if [ ! -d "$app_dir" ]; then
        echo "Error: $app_dir not found. Run '$0 build release' first."
        exit 1
    fi

    echo "Signing $app_dir..."
    codesign --force --options runtime \
        --entitlements "$ENTITLEMENTS" \
        --sign "$CODESIGN_IDENTITY" \
        "$app_dir"

    echo "Verifying signature..."
    codesign --verify --deep --strict "$app_dir"
    echo "Signature valid."
}

# Create DMG, sign, notarize, staple
cmd_dmg() {
    local version="$1"
    if [ -z "$version" ]; then
        echo "Usage: $0 dmg <version>"
        exit 1
    fi

    local app_dir="$BUILD_DIR/release/$APP_NAME.app"
    local dmg="$BUILD_DIR/release/$APP_NAME-$version.dmg"

    if [ ! -d "$app_dir" ]; then
        echo "Error: $app_dir not found. Run '$0 build release' first."
        exit 1
    fi

    echo "Creating DMG..."
    rm -f "$dmg"

    if command -v create-dmg &>/dev/null; then
        create-dmg \
            --volname "$APP_NAME" \
            --window-size 600 400 \
            --icon "$APP_NAME.app" 150 200 \
            --app-drop-link 450 200 \
            "$dmg" \
            "$app_dir"
    else
        hdiutil create -volname "$APP_NAME" \
            -srcfolder "$app_dir" \
            -ov -format UDZO \
            "$dmg"
    fi

    echo "Signing DMG..."
    codesign --force --sign "$CODESIGN_IDENTITY" "$dmg"

    echo "Notarizing..."
    xcrun notarytool submit "$dmg" \
        --keychain-profile "$NOTARY_PROFILE" \
        --wait

    echo "Stapling..."
    xcrun stapler staple "$dmg"

    echo "DMG ready: $dmg"
}

# Create MAS .pkg
cmd_mas() {
    local version="$1"
    if [ -z "$version" ]; then
        echo "Usage: $0 mas <version>"
        exit 1
    fi

    local app_dir="$BUILD_DIR/release/$APP_NAME.app"
    local pkg="$BUILD_DIR/release/$APP_NAME-$version.pkg"

    if [ ! -d "$app_dir" ]; then
        echo "Error: $app_dir not found. Run '$0 build release' first."
        exit 1
    fi

    echo "Signing for MAS..."
    codesign --force --options runtime \
        --entitlements "$MAS_ENTITLEMENTS" \
        --sign "$MAS_APP_IDENTITY" \
        "$app_dir"

    echo "Creating .pkg..."
    productbuild --component "$app_dir" /Applications \
        --sign "$MAS_INSTALLER_IDENTITY" \
        "$pkg"

    echo "MAS package ready: $pkg"
}

# Full release pipeline
cmd_release() {
    local version="$1"
    if [ -z "$version" ]; then
        echo "Usage: $0 release <version>"
        exit 1
    fi

    cmd_build release
    cmd_sign
    cmd_dmg "$version"

    echo ""
    echo "Release $version complete!"
    echo "  DMG: $BUILD_DIR/release/$APP_NAME-$version.dmg"
}

# Main
case "${1:-}" in
    "")
        echo "Building and running $APP_NAME..."
        swift run --package-path "$PKG_PATH"
        ;;
    build)
        cmd_build "${2:-debug}"
        ;;
    sign)
        cmd_sign
        ;;
    dmg)
        cmd_dmg "$2"
        ;;
    mas)
        cmd_mas "$2"
        ;;
    release)
        cmd_release "$2"
        ;;
    -h|--help|help)
        usage
        ;;
    *)
        echo "Unknown command: $1"
        usage
        exit 1
        ;;
esac
