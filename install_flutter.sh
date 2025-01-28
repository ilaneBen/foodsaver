#!/bin/bash

# Télécharge et installe Flutter
FLUTTER_VERSION="3.10.6"  # Remplacez par la version Flutter souhaitée
FLUTTER_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"

echo "Downloading Flutter..."
curl -LO $FLUTTER_URL
tar xf flutter_linux_${FLUTTER_VERSION}-stable.tar.xz

# Ajoute Flutter au PATH
export PATH="$PWD/flutter/bin:$PATH"

# Vérifie l'installation de Flutter
flutter doctor

# Vérifie si Flutter est bien dans le PATH
echo "Flutter installed at $(which flutter)"
