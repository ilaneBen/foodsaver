#!/bin/bash

# Variables
#!/bin/bash

# Variables
FLUTTER_VERSION="3.13.0"  # Version de Flutter compatible avec Dart 3.5.1
FLUTTER_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"

# Télécharger et installer Flutter
echo "Downloading Flutter $FLUTTER_VERSION..."
curl -LO $FLUTTER_URL
tar xf flutter_linux_${FLUTTER_VERSION}-stable.tar.xz

# Ajouter Flutter au PATH
export PATH="$PWD/flutter/bin:$PATH"

# Vérifier les versions de Flutter et Dart
flutter --version || { echo "Failed to install Flutter"; exit 1; }
dart --version || { echo "Failed to install Dart"; exit 1; }

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
