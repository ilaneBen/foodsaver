#!/bin/bash
FLUTTER_VERSION="3.10.6"  # Remplacez par la version Flutter souhaitée
FLUTTER_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"

echo "Downloading Flutter..."
curl -LO $FLUTTER_URL
tar xf flutter_linux_${FLUTTER_VERSION}-stable.tar.xz

export PATH="$PATH:$PWD/flutter/bin"
flutter doctor
