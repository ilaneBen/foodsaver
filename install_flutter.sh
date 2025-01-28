#!/bin/bash

# Variables
FLUTTER_VERSION="3.14.0"
FLUTTER_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"
FLUTTER_DIR="flutter"

# Télécharger Flutter
echo "Downloading Flutter $FLUTTER_VERSION..."
curl -o flutter_linux_${FLUTTER_VERSION}-stable.tar.xz $FLUTTER_URL || { echo "Failed to download Flutter"; exit 1; }

# Vérifier que le fichier est téléchargé
if [ ! -f "flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" ]; then
  echo "Flutter archive not found. Exiting."
  exit 1
fi

# Extraire Flutter
echo "Extracting Flutter..."
tar -xf flutter_linux_${FLUTTER_VERSION}-stable.tar.xz || { echo "Failed to extract Flutter"; exit 1; }

# Vérifier que le répertoire Flutter est créé
if [ ! -d "$FLUTTER_DIR" ]; then
  echo "Flutter directory not created. Exiting."
  exit 1
fi

# Ajouter Flutter au PATH
export PATH="$PWD/flutter/bin:$PATH"

# Vérifier les installations
flutter --version || { echo "Flutter installation failed"; exit 1; }
dart --version || { echo "Dart installation failed"; exit 1; }
