#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
echo 'Setting up NexaHome for macOS...'
flutter --version
flutter create --project-name smart_home_twin --platforms=macos,android .
dart tool/prepare_platforms.dart
flutter pub get
echo 'Starting macOS app...'
flutter run -d macos
