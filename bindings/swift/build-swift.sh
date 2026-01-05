#!/bin/bash
set -e

# Build script for creating Swift bindings and XCFramework
# This script builds the Rust library for iOS and macOS, generates Swift bindings,
# and packages everything into an XCFramework suitable for distribution.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
XCFRAMEWORK_DIR="$BUILD_DIR/xcframework"

echo "🔨 Building Bark Swift bindings..."
echo "Project root: $PROJECT_ROOT"
echo "Build dir: $BUILD_DIR"

# Clean previous build
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
mkdir -p "$XCFRAMEWORK_DIR"

cd "$PROJECT_ROOT"

# Install targets if needed
echo "📦 Ensuring Rust targets are installed..."
rustup target add aarch64-apple-ios
rustup target add x86_64-apple-ios
rustup target add aarch64-apple-ios-sim
rustup target add aarch64-apple-darwin
rustup target add x86_64-apple-darwin

# Build for iOS device (arm64)
echo "🍎 Building for iOS device (arm64)..."
cargo build --release --target aarch64-apple-ios

# Build for iOS simulator (arm64 + x86_64)
echo "📱 Building for iOS simulator (arm64)..."
cargo build --release --target aarch64-apple-ios-sim

echo "📱 Building for iOS simulator (x86_64)..."
cargo build --release --target x86_64-apple-ios

# Build for macOS (arm64 + x86_64)
echo "💻 Building for macOS (arm64)..."
cargo build --release --target aarch64-apple-darwin

echo "💻 Building for macOS (x86_64)..."
cargo build --release --target x86_64-apple-darwin

# Create universal binaries
echo "🔗 Creating universal binaries..."

# iOS simulator universal binary
mkdir -p "$BUILD_DIR/ios-simulator"
lipo -create \
    "$PROJECT_ROOT/target/aarch64-apple-ios-sim/release/libbark_ffi.a" \
    "$PROJECT_ROOT/target/x86_64-apple-ios/release/libbark_ffi.a" \
    -output "$BUILD_DIR/ios-simulator/libbark_ffi.a"

# macOS universal binary
mkdir -p "$BUILD_DIR/macos"
lipo -create \
    "$PROJECT_ROOT/target/aarch64-apple-darwin/release/libbark_ffi.dylib" \
    "$PROJECT_ROOT/target/x86_64-apple-darwin/release/libbark_ffi.dylib" \
    -output "$BUILD_DIR/macos/libbark_ffi.dylib"

# Create framework structure for each platform
echo "📦 Creating framework structures..."

# iOS device framework
IOS_DEVICE_FRAMEWORK="$BUILD_DIR/ios-device/BarkFFI.framework"
mkdir -p "$IOS_DEVICE_FRAMEWORK"
cp "$PROJECT_ROOT/target/aarch64-apple-ios/release/libbark_ffi.a" "$IOS_DEVICE_FRAMEWORK/BarkFFI"
cp "$SCRIPT_DIR/resources/Info-iOS.plist" "$IOS_DEVICE_FRAMEWORK/Info.plist"

# iOS simulator framework
IOS_SIM_FRAMEWORK="$BUILD_DIR/ios-simulator-framework/BarkFFI.framework"
mkdir -p "$IOS_SIM_FRAMEWORK"
cp "$BUILD_DIR/ios-simulator/libbark_ffi.a" "$IOS_SIM_FRAMEWORK/BarkFFI"
cp "$SCRIPT_DIR/resources/Info-iOSSimulator.plist" "$IOS_SIM_FRAMEWORK/Info.plist"

# macOS framework (versioned bundle layout)
MACOS_FRAMEWORK="$BUILD_DIR/macos-framework/BarkFFI.framework"
mkdir -p "$MACOS_FRAMEWORK/Versions/A/Resources"
cp "$BUILD_DIR/macos/libbark_ffi.dylib" "$MACOS_FRAMEWORK/Versions/A/BarkFFI"
cp "$SCRIPT_DIR/resources/Info-macOS.plist" "$MACOS_FRAMEWORK/Versions/A/Resources/Info.plist"

# Create symlinks for versioned framework structure
ln -s A "$MACOS_FRAMEWORK/Versions/Current"
ln -s Versions/Current/BarkFFI "$MACOS_FRAMEWORK/BarkFFI"
ln -s Versions/Current/Headers "$MACOS_FRAMEWORK/Headers"
ln -s Versions/Current/Modules "$MACOS_FRAMEWORK/Modules"
ln -s Versions/Current/Resources "$MACOS_FRAMEWORK/Resources"

# Generate Swift bindings using uniffi-bindgen-swift
echo "🦀 Generating Swift bindings..."

# Generate headers and modulemaps for iOS device
echo "📱 Generating iOS device bindings..."
cargo run --bin uniffi-bindgen-swift -- \
    "$PROJECT_ROOT/target/aarch64-apple-ios/release/libbark_ffi.a" \
    "$IOS_DEVICE_FRAMEWORK/Headers" \
    --headers

cargo run --bin uniffi-bindgen-swift -- \
    "$PROJECT_ROOT/target/aarch64-apple-ios/release/libbark_ffi.a" \
    "$IOS_DEVICE_FRAMEWORK/Modules" \
    --xcframework \
    --modulemap \
    --module-name barkFFI \
    --modulemap-filename module.modulemap

# Generate headers and modulemaps for iOS simulator
echo "📱 Generating iOS simulator bindings..."
cargo run --bin uniffi-bindgen-swift -- \
    "$PROJECT_ROOT/target/aarch64-apple-ios-sim/release/libbark_ffi.a" \
    "$IOS_SIM_FRAMEWORK/Headers" \
    --headers

cargo run --bin uniffi-bindgen-swift -- \
    "$PROJECT_ROOT/target/aarch64-apple-ios-sim/release/libbark_ffi.a" \
    "$IOS_SIM_FRAMEWORK/Modules" \
    --xcframework \
    --modulemap \
    --module-name barkFFI \
    --modulemap-filename module.modulemap

# Generate headers and modulemaps for macOS
echo "💻 Generating macOS bindings..."
cargo run --bin uniffi-bindgen-swift -- \
    "$PROJECT_ROOT/target/aarch64-apple-darwin/release/libbark_ffi.dylib" \
    "$MACOS_FRAMEWORK/Versions/A/Headers" \
    --headers

cargo run --bin uniffi-bindgen-swift -- \
    "$PROJECT_ROOT/target/aarch64-apple-darwin/release/libbark_ffi.dylib" \
    "$MACOS_FRAMEWORK/Versions/A/Modules" \
    --xcframework \
    --modulemap \
    --module-name barkFFI \
    --modulemap-filename module.modulemap

# Generate Swift source files (only need once)
echo "📝 Generating Swift source files..."
SOURCES_DIR="$SCRIPT_DIR/Sources/Bark"
mkdir -p "$SOURCES_DIR"
cargo run --bin uniffi-bindgen-swift -- \
    "$PROJECT_ROOT/target/aarch64-apple-darwin/release/libbark_ffi.dylib" \
    "$SOURCES_DIR" \
    --swift-sources

# Create XCFramework
echo "📦 Creating XCFramework..."
xcodebuild -create-xcframework \
    -framework "$IOS_DEVICE_FRAMEWORK" \
    -framework "$IOS_SIM_FRAMEWORK" \
    -framework "$MACOS_FRAMEWORK" \
    -output "$XCFRAMEWORK_DIR/BarkFFI.xcframework"

# Note: Package.swift must be at repository root for SPM to work
echo "ℹ️  Note: Ensure Package.swift is at repository root (not in bindings/swift/)"

# Create zip for distribution
echo "📦 Creating distribution zip..."
cd "$XCFRAMEWORK_DIR"
zip -r BarkFFI.xcframework.zip BarkFFI.xcframework
CHECKSUM=$(swift package compute-checksum BarkFFI.xcframework.zip)

echo ""
echo "✅ Build complete!"
echo ""
echo "📦 XCFramework: $XCFRAMEWORK_DIR/BarkFFI.xcframework.zip"
echo "📝 Swift sources: $SOURCES_DIR"
echo ""
echo "📊 Checksum for Package.swift:"
echo "   $CHECKSUM"
echo ""
echo "Update Package.swift with this checksum!"
