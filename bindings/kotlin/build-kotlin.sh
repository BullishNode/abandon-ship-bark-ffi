#!/bin/bash
set -e

# Build script for creating Kotlin bindings for both Android and JVM
# This script builds the Rust library for multiple platforms, generates Kotlin bindings,
# and packages everything for distribution via JitPack or Maven.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
ANDROID_MODULE="$SCRIPT_DIR/bark-android"
JVM_MODULE="$SCRIPT_DIR/bark-jvm"

echo "🔨 Building Bark Kotlin bindings (Android + JVM)..."
echo "Project root: $PROJECT_ROOT"
echo "Build dir: $BUILD_DIR"

# Clean previous build
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Clean previous builds in both modules
rm -rf "$ANDROID_MODULE/src/main/jniLibs"
rm -rf "$ANDROID_MODULE/src/main/kotlin/uniffi"
rm -rf "$JVM_MODULE/src/main/kotlin/uniffi"
rm -rf "$JVM_MODULE/src/main/resources"

cd "$PROJECT_ROOT"

# Detect OS and architecture early (needed for NDK and JVM configuration)
OS=$(uname -s)
ARCH=$(uname -m)

# Check for required tools
if ! command -v cargo &> /dev/null; then
    echo "❌ Error: cargo not found. Install Rust from https://rustup.rs"
    exit 1
fi

if ! command -v rustc &> /dev/null; then
    echo "❌ Error: rustc not found. Install Rust from https://rustup.rs"
    exit 1
fi

# Install Android targets
echo "📦 Ensuring Android Rust targets are installed..."
rustup target add aarch64-linux-android
rustup target add armv7-linux-androideabi
rustup target add x86_64-linux-android
rustup target add i686-linux-android

# Detect and configure Android NDK
NDK_PATH=""
if [ -n "$ANDROID_NDK_HOME" ]; then
    NDK_PATH="$ANDROID_NDK_HOME"
elif [ -n "$NDK_HOME" ]; then
    NDK_PATH="$NDK_HOME"
elif [ -n "$ANDROID_HOME" ]; then
    # Try to find NDK in Android SDK directory
    if [ -d "$ANDROID_HOME/ndk" ]; then
        # Use the latest NDK version found
        NDK_PATH=$(ls -d "$ANDROID_HOME/ndk/"* 2>/dev/null | sort -V | tail -n 1)
    fi
fi

if [ -z "$NDK_PATH" ] || [ ! -d "$NDK_PATH" ]; then
    echo "❌ Error: Android NDK not found!"
    echo ""
    echo "Please set one of the following environment variables:"
    echo "  - ANDROID_NDK_HOME (preferred)"
    echo "  - NDK_HOME"
    echo "  - ANDROID_HOME (will auto-detect NDK in \$ANDROID_HOME/ndk/)"
    echo ""
    echo "Example:"
    echo "  export ANDROID_NDK_HOME=/path/to/android-ndk"
    echo ""
    exit 1
fi

echo "✓ Found Android NDK: $NDK_PATH"

# Determine host platform tag for NDK toolchain
HOST_TAG=""
case "$OS" in
    Linux)
        HOST_TAG="linux-x86_64"
        ;;
    Darwin)
        if [ "$ARCH" = "arm64" ]; then
            HOST_TAG="darwin-x86_64"  # NDK uses x86_64 binaries on Apple Silicon with Rosetta
        else
            HOST_TAG="darwin-x86_64"
        fi
        ;;
    *)
        echo "❌ Error: Unsupported host OS: $OS"
        exit 1
        ;;
esac

# Set up Android NDK toolchain environment variables
NDK_TOOLCHAIN="$NDK_PATH/toolchains/llvm/prebuilt/$HOST_TAG"

if [ ! -d "$NDK_TOOLCHAIN" ]; then
    echo "❌ Error: NDK toolchain not found at: $NDK_TOOLCHAIN"
    echo "   Your NDK might be corrupted or incompatible."
    exit 1
fi

echo "✓ Using NDK toolchain: $NDK_TOOLCHAIN"

# Configure environment for Android targets (API level 21 matches minSdk 24)
export CC_aarch64_linux_android="$NDK_TOOLCHAIN/bin/aarch64-linux-android21-clang"
export AR_aarch64_linux_android="$NDK_TOOLCHAIN/bin/llvm-ar"
export CARGO_TARGET_AARCH64_LINUX_ANDROID_LINKER="$NDK_TOOLCHAIN/bin/aarch64-linux-android21-clang"

export CC_armv7_linux_androideabi="$NDK_TOOLCHAIN/bin/armv7a-linux-androideabi21-clang"
export AR_armv7_linux_androideabi="$NDK_TOOLCHAIN/bin/llvm-ar"
export CARGO_TARGET_ARMV7_LINUX_ANDROIDEABI_LINKER="$NDK_TOOLCHAIN/bin/armv7a-linux-androideabi21-clang"

export CC_x86_64_linux_android="$NDK_TOOLCHAIN/bin/x86_64-linux-android21-clang"
export AR_x86_64_linux_android="$NDK_TOOLCHAIN/bin/llvm-ar"
export CARGO_TARGET_X86_64_LINUX_ANDROID_LINKER="$NDK_TOOLCHAIN/bin/x86_64-linux-android21-clang"

export CC_i686_linux_android="$NDK_TOOLCHAIN/bin/i686-linux-android21-clang"
export AR_i686_linux_android="$NDK_TOOLCHAIN/bin/llvm-ar"
export CARGO_TARGET_I686_LINUX_ANDROID_LINKER="$NDK_TOOLCHAIN/bin/i686-linux-android21-clang"

echo "✓ Android NDK toolchain configured"
echo ""

# Build for Android platforms
echo ""
echo "🤖 Building for Android platforms..."
echo "=================================="

echo "📱 Building for Android arm64-v8a..."
cargo build --release --target aarch64-linux-android

echo "📱 Building for Android armeabi-v7a..."
cargo build --release --target armv7-linux-androideabi

echo "💻 Building for Android x86_64..."
cargo build --release --target x86_64-linux-android

echo "💻 Building for Android x86..."
cargo build --release --target i686-linux-android

# Build for JVM platforms (host platform only for now)
echo ""
echo "☕ Building for JVM platform..."
echo "=============================="

case "$OS" in
    Linux)
        echo "💻 Building for Linux x86_64..."
        cargo build --release --target x86_64-unknown-linux-gnu
        JVM_LIB_EXT="so"
        JVM_TARGET="x86_64-unknown-linux-gnu"
        ;;
    Darwin)
        echo "💻 Building for macOS..."
        if [ "$ARCH" = "arm64" ]; then
            cargo build --release --target aarch64-apple-darwin
            JVM_TARGET="aarch64-apple-darwin"
        else
            cargo build --release --target x86_64-apple-darwin
            JVM_TARGET="x86_64-apple-darwin"
        fi
        JVM_LIB_EXT="dylib"
        ;;
    *)
        echo "⚠️  Warning: Unknown OS $OS. Skipping JVM build."
        echo "   Supported: Linux, Darwin (macOS)"
        JVM_TARGET=""
        ;;
esac

# Generate Kotlin bindings using uniffi-bindgen (once, shared by both modules)
echo ""
echo "🦀 Generating Kotlin bindings..."
mkdir -p "$BUILD_DIR/kotlin"
cargo run --bin uniffi-bindgen -- generate \
    --library "$PROJECT_ROOT/target/aarch64-linux-android/release/libbark_ffi.so" \
    --language kotlin \
    --out-dir "$BUILD_DIR/kotlin" \
    --no-format

# Copy Kotlin source to Android module
echo ""
echo "📱 Setting up Android module..."
echo "📝 Copying Kotlin source files to bark-android..."
mkdir -p "$ANDROID_MODULE/src/main/kotlin"
cp -r "$BUILD_DIR/kotlin/uniffi" "$ANDROID_MODULE/src/main/kotlin/"

# Create jniLibs directory structure and copy native libraries for Android
echo "📦 Copying native libraries to Android jniLibs..."

mkdir -p "$ANDROID_MODULE/src/main/jniLibs/arm64-v8a"
cp "$PROJECT_ROOT/target/aarch64-linux-android/release/libbark_ffi.so" \
   "$ANDROID_MODULE/src/main/jniLibs/arm64-v8a/"

mkdir -p "$ANDROID_MODULE/src/main/jniLibs/armeabi-v7a"
cp "$PROJECT_ROOT/target/armv7-linux-androideabi/release/libbark_ffi.so" \
   "$ANDROID_MODULE/src/main/jniLibs/armeabi-v7a/"

mkdir -p "$ANDROID_MODULE/src/main/jniLibs/x86_64"
cp "$PROJECT_ROOT/target/x86_64-linux-android/release/libbark_ffi.so" \
   "$ANDROID_MODULE/src/main/jniLibs/x86_64/"

mkdir -p "$ANDROID_MODULE/src/main/jniLibs/x86"
cp "$PROJECT_ROOT/target/i686-linux-android/release/libbark_ffi.so" \
   "$ANDROID_MODULE/src/main/jniLibs/x86/"

# Copy Kotlin source and native library to JVM module
if [ -n "$JVM_TARGET" ]; then
    echo ""
    echo "☕ Setting up JVM module..."
    echo "📝 Copying Kotlin source files to bark-jvm..."
    mkdir -p "$JVM_MODULE/src/main/kotlin"
    cp -r "$BUILD_DIR/kotlin/uniffi" "$JVM_MODULE/src/main/kotlin/"

    echo "📦 Copying native library to JVM resources..."
    mkdir -p "$JVM_MODULE/src/main/resources"
    cp "$PROJECT_ROOT/target/$JVM_TARGET/release/libbark_ffi.$JVM_LIB_EXT" \
       "$JVM_MODULE/src/main/resources/"
fi

# Build both modules using Gradle
echo ""
echo "📦 Building with Gradle..."
echo "========================="
cd "$SCRIPT_DIR"

# Initialize Gradle wrapper if it doesn't exist
if [ ! -f "gradlew" ]; then
    echo "🔧 Initializing Gradle wrapper..."
    gradle wrapper --gradle-version 8.7
fi

echo "🤖 Building Android AAR..."
./gradlew :bark-android:assembleRelease

if [ -n "$JVM_TARGET" ]; then
    echo "☕ Building JVM JAR..."
    ./gradlew :bark-jvm:jar
fi

echo ""
echo "✅ Build complete!"
echo "================="
echo ""
echo "📦 Artifacts:"
echo "   Android AAR: $ANDROID_MODULE/build/outputs/aar/bark-android-release.aar"
if [ -n "$JVM_TARGET" ]; then
    echo "   JVM JAR:     $JVM_MODULE/build/libs/bark-jvm-*.jar"
fi
echo ""
echo "📝 Kotlin sources:"
echo "   Android: $ANDROID_MODULE/src/main/kotlin/uniffi/bark/"
if [ -n "$JVM_TARGET" ]; then
    echo "   JVM:     $JVM_MODULE/src/main/kotlin/uniffi/bark/"
fi
echo ""
echo "Next steps:"
echo "1. Run tests:"
echo "   Android: ./gradlew :bark-android:connectedAndroidTest (requires emulator)"
echo "   JVM:     ./gradlew :bark-jvm:test"
echo ""
echo "2. Test with example app:"
echo "   cd example && ./gradlew installDebug"
echo ""
echo "3. Check code style:"
echo "   ./gradlew ktlintCheck"
echo ""
echo "4. Publish to JitPack:"
echo "   git tag kotlin-v0.1.0-beta.4"
echo "   git push origin kotlin-v0.1.0-beta.4"
echo ""
