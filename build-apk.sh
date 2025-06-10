#!/bin/bash

set -e

echo "🚀 Starting Flutter APK Build Process..."

# Check Flutter installation
echo "📋 Checking Flutter installation..."
flutter doctor -v

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean

# Get dependencies
echo "📦 Getting Flutter dependencies..."
flutter pub get

# Build APK
echo "🔨 Building APK..."
flutter build apk --release

# Check if APK was built successfully
APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
if [ -f "$APK_PATH" ]; then
    echo "✅ APK built successfully!"
    echo "📍 APK location: $APK_PATH"
    
    # Copy APK to output directory with timestamp
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    OUTPUT_DIR="/workspace/output"
    mkdir -p "$OUTPUT_DIR"
    cp "$APK_PATH" "$OUTPUT_DIR/bemyguide_${TIMESTAMP}.apk"
    
    echo "📋 APK copied to: $OUTPUT_DIR/bemyguide_${TIMESTAMP}.apk"
    echo "📊 APK size: $(du -h "$APK_PATH" | cut -f1)"
else
    echo "❌ APK build failed!"
    exit 1
fi

echo "🎉 Build process completed successfully!" 