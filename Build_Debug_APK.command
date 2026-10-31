#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

export PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/flutter/bin:$HOME/development/flutter/bin:/opt/homebrew/share/flutter/bin:$PATH"

pause_on_error() {
  status=$?
  trap - ERR
  echo
  echo "APK build failed (exit $status)."
  if [[ -t 0 ]]; then
    read -r -p "Press Return to close this window..." _
  fi
  exit "$status"
}
trap pause_on_error ERR

FLUTTER="$(command -v flutter || true)"
if [[ -z "$FLUTTER" ]]; then
  echo "Flutter was not found. Install Flutter or add its bin folder to PATH."
  if [[ -t 0 ]]; then
    read -r -p "Press Return to close this window..." _
  fi
  exit 1
fi

echo "Resolving Flutter dependencies..."
"$FLUTTER" pub get

echo
echo "Building a debug APK (suitable for App Check debug testing)..."
"$FLUTTER" build apk --debug

APK="$ROOT/build/app/outputs/flutter-apk/app-debug.apk"
if [[ ! -f "$APK" ]]; then
  echo "Flutter reported success, but the APK was not found at: $APK"
  exit 1
fi

echo
echo "Debug APK created:"
echo "$APK"
echo
echo "To install and launch it on the running emulator:"
echo "  flutter install -d emulator-5554"
echo "  flutter run -d emulator-5554"
open -R "$APK"
