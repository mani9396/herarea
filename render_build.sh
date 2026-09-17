#!/bin/bash
# Exit on error
set -e

# Target application from argument
APP_NAME=$1

if [ -z "$APP_NAME" ]; then
    echo "Error: Target application folder must be provided."
    echo "Usage: ./render_build.sh <app_folder>"
    exit 1
fi

echo "Installing Flutter SDK..."
if [ ! -d "$HOME/flutter" ]; then
    git clone https://github.com/flutter/flutter.git -b stable "$HOME/flutter"
fi

export PATH="$HOME/flutter/bin:$PATH"

# Disable analytics for faster build
flutter config --no-analytics

echo "Building $APP_NAME..."
cd "$APP_NAME"

# Clean state
flutter clean

# Get dependencies
flutter pub get

# Build web release
flutter build web --release --base-href=/

echo "Build complete! Publishing directory: $APP_NAME/build/web"
