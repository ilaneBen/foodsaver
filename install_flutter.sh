#!/bin/bash

# Variables
FLUTTER_VERSION="3.14.0"  # Version compatible avec Dart 3.5.3
FLUTTER_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"

# Télécharger Flutter
echo "Downloading Flutter $FLUTTER_VERSION..."
curl -o flutter_linux_${FLUTTER_VERSION}-stable.tar.xz $FLUTTER_URL || { echo "Failed to download Flutter"; exit 1; }

# Extraire Flutter
echo "Extracting Flutter..."
tar -xf flutter_linux_${FLUTTER_VERSION}-stable.tar.xz || { echo "Failed to extract Flutter"; exit 1; }

# Ajouter Flutter au PATH
export PATH="$PWD/flutter/bin:$PATH"

# Vérifier les installations
flutter --version || { echo "Failed to install Flutter"; exit 1; }
dart --version || { echo "Failed to install Dart"; exit 1; }
