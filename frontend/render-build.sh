#!/usr/bin/env bash
set -e

if [ ! -d "$HOME/flutter" ]; then
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 "$HOME/flutter"
fi

export PATH="$PATH:$HOME/flutter/bin"

flutter config --enable-web
flutter pub get
flutter build web -t lib/main_admin.dart --release
