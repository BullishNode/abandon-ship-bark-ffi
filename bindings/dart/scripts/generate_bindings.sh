#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Bark FFI Dart Bindings Generator - FOR MAINTAINERS ONLY
# ============================================================================
# ⚠️  THIS SCRIPT IS FOR PACKAGE MAINTAINERS/DEVELOPERS ONLY ⚠️
#
# This script is used by bark maintainers to generate and prepare the Dart
# bindings BEFORE publishing to pub.dev or committing to git.
#
# END USERS of the bark_ffi Dart package DO NOT need to run this script!
# When users install the package, the native library is automatically built
# by Dart's Native Assets system from the pre-generated native/ directory.
#
# What this script does:
# 1. Builds the bark-ffi Rust crate from the workspace
# 2. Generates Dart bindings using uniffi-bindgen
# 3. Copies bark-ffi source to native/ for pub.dev distribution
#
# When to run this script:
# - After modifying bark-ffi Rust code or UDL
# - Before publishing a new version to pub.dev
# - Before committing changes to the Dart bindings
# ============================================================================

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DART_PKG_DIR="$SCRIPT_DIR/.."
BARK_FFI_DIR="$DART_PKG_DIR/../.."
NATIVE_DIR="$DART_PKG_DIR/native"

OS=$(uname -s)
echo "🚀 Bark FFI Dart Bindings Generator"
echo "===================================="
echo "Running on: $OS"
echo ""

# Navigate to Dart package directory
cd "$DART_PKG_DIR"

echo "📦 Checking Dart version..."
dart --version
echo ""

echo "📥 Getting Dart dependencies..."
dart pub get
echo ""

# Determine library name based on OS
if [[ "$OS" == "Darwin" ]]; then
    LIBNAME=libbark_ffi.dylib
elif [[ "$OS" == "Linux" ]]; then
    LIBNAME=libbark_ffi.so
else
    echo "❌ Unsupported OS: $OS"
    echo "Supported: Darwin (macOS), Linux"
    exit 1
fi

# Navigate to bark workspace root to build
cd "$BARK_FFI_DIR"
echo "🔨 Building bark-ffi from workspace..."
cargo build --package bark-ffi --profile dev
echo "✅ Rust build complete"
echo ""

# Generate Dart bindings using uniffi-bindgen
echo "🎯 Generating Dart bindings..."
cargo run --package bark-ffi --bin uniffi-bindgen -- generate \
    --profile dev \
    --library \
    --language dart \
    --out-dir "$DART_PKG_DIR/lib/src/generated/" \
    "$BARK_FFI_DIR/target/debug/$LIBNAME"

echo "✅ Dart bindings generated in lib/src/generated/"
echo ""

echo "📋 Preparing native/ directory for pub.dev..."
echo "------------------------------------------------"

# Copy bark-ffi to native/ so it can be included in the published package
echo "📁 Copying bark-ffi source to native/..."
mkdir -p "$NATIVE_DIR"
rsync -a --delete "$BARK_FFI_DIR/" "$NATIVE_DIR/" \
    --include='src/***' \
    --include='build.rs' \
    --include='Cargo.toml' \
    --include='Cargo.lock' \
    --include='LICENSE' \
    --include='rust-toolchain.toml' \
    --include='uniffi-bindgen.rs' \
    --include='uniffi.toml' \
    --exclude='*'

echo "✅ Source files copied"
echo ""

echo "════════════════════════════════════════════════════════════════════════════════"
echo "✨ SUCCESS! Bindings generated and native/ prepared for publishing to pub.dev."
echo "════════════════════════════════════════════════════════════════════════════════"