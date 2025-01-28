#!/bin/bash

# Variables
FLUTTER_VERSION="3.10.6"
DART_VERSION="3.5.1"
FLUTTER_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"
DART_URL="https://storage.googleapis.com/dart-archive/channels/stable/release/${DART_VERSION}/sdk/dartsdk-linux-x64-release.zip"

# Installer Flutter
echo "Downloading Flutter $FLUTTER_VERSION..."
curl -LO $FLUTTER_URL
tar xf flutter_linux_${FLUTTER_VERSION}-stable.tar.xz

# Ajouter Flutter au PATH
export PATH="$PWD/flutter/bin:$PATH"

# Vérifier Flutter
flutter --version || { echo "Failed to install Flutter"; exit 1; }

# Installer Dart
echo "Downloading Dart $DART_VERSION..."
curl -LO $DART_URL
unzip dartsdk-linux-x64-release.zip -d dart-sdk

# Ajouter Dart au PATH
export PATH="$PWD/dart-sdk/bin:$PATH"

# Vérifier Dart
dart --version || { echo "Failed to install Dart"; exit 1; }
