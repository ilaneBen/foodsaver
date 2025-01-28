#!/bin/bash

# Télécharger et installer Dart 3.5.1
DART_VERSION="3.5.1"
DART_URL="https://storage.googleapis.com/dart-archive/channels/stable/release/${DART_VERSION}/sdk/dartsdk-linux-x64-release.zip"

echo "Downloading Dart $DART_VERSION..."
curl -LO $DART_URL
unzip dartsdk-linux-x64-release.zip -d dart-sdk

# Ajouter Dart au PATH
export PATH="$PWD/dart-sdk/bin:$PATH"

# Vérifier l'installation de Dart
dart --version
