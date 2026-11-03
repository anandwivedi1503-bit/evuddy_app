#!/usr/bin/env bash
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

if ! dpkg -s libgtk-3-dev >/dev/null 2>&1; then
  sudo DEBIAN_FRONTEND=noninteractive apt-get update -qq
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    curl git unzip xz-utils zip libglu1-mesa clang cmake ninja-build pkg-config \
    libgtk-3-dev liblzma-dev
fi

FLUTTER_ROOT=/opt/flutter
if [ ! -x "${FLUTTER_ROOT}/bin/flutter" ]; then
  sudo mkdir -p /opt
  sudo git clone https://github.com/flutter/flutter.git -b stable --depth 1 "${FLUTTER_ROOT}"
  sudo chown -R "$(whoami):$(whoami)" "${FLUTTER_ROOT}"
fi

sudo ln -sf "${FLUTTER_ROOT}/bin/flutter" /usr/local/bin/flutter
sudo ln -sf "${FLUTTER_ROOT}/bin/dart" /usr/local/bin/dart

flutter config --enable-web >/dev/null
flutter precache --web
flutter pub get
