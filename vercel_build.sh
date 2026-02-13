#!/bin/bash
# Vercel build script for Flutter web
set -e

if ! command -v flutter &> /dev/null; then
  echo "Installing Flutter..."
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable
  export PATH="$PATH:$(pwd)/flutter/bin"
fi

flutter clean
flutter pub get
flutter build web --release \
  --dart-define=API_URL=$API_URL
