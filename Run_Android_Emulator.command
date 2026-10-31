#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

export PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/flutter/bin:$HOME/development/flutter/bin:/opt/homebrew/share/flutter/bin:$PATH"

fail() {
  local status="${2:-1}"
  echo
  echo "ERROR: $1"
  if [[ -t 0 ]]; then
    read -r -p "Press Return to close this window..." _
  fi
  exit "$status"
}

pause_on_error() {
  local status=$?
  trap - ERR
  fail "A command failed on line ${BASH_LINENO[0]:-unknown} (exit $status)." "$status"
}
trap pause_on_error ERR

FLUTTER="$(command -v flutter || true)"
if [[ -z "$FLUTTER" ]]; then
  fail "Flutter was not found. Install Flutter or add its bin folder to PATH."
fi

SDK="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$HOME/Library/Android/sdk}}"
ADB="$SDK/platform-tools/adb"
if [[ ! -x "$ADB" ]]; then
  fail "Android adb was not found at: $ADB. Install Android SDK Platform-Tools in Android Studio > SDK Manager."
fi

EMULATOR_ID="Pixel_8"
EMULATORS="$("$FLUTTER" emulators)"
if [[ "$EMULATORS" != *"$EMULATOR_ID"* ]]; then
  fail "The '$EMULATOR_ID' emulator is not configured. Create or start an Android Virtual Device in Android Studio > Tools > Device Manager."
fi

EMULATOR="$SDK/emulator/emulator"
if [[ ! -x "$EMULATOR" ]]; then
  fail "Android Emulator was not found at: $EMULATOR"
fi

find_target_serial() {
  local candidate avd_name
  while read -r candidate; do
    [[ -n "$candidate" ]] || continue
    avd_name="$("$ADB" -s "$candidate" emu avd name 2>/dev/null | sed -n '1p')"
    if [[ "$avd_name" == "$EMULATOR_ID" ]]; then
      printf '%s' "$candidate"
      return 0
    fi
  done < <("$ADB" devices | awk '$1 ~ /^emulator-/ && $2 == "device" { print $1 }')
  return 0
}

SERIAL="$(find_target_serial)"
HEADLESS_PID="$(
  ps -axo pid=,command= |
    awk -v avd="$EMULATOR_ID" '$0 ~ /qemu-system/ && $0 ~ ("-avd " avd) && $0 ~ /-no-window/ { print $1; exit }'
)"

if [[ -n "$SERIAL" && -n "$HEADLESS_PID" ]]; then
  echo "Stopping the headless $EMULATOR_ID emulator so it can reopen with a visible window..."
  "$ADB" -s "$SERIAL" emu kill
  for _ in {1..30}; do
    SERIAL="$(find_target_serial)"
    [[ -z "$SERIAL" ]] && break
    sleep 1
  done
  SERIAL=""
fi

if [[ -z "$SERIAL" ]]; then
  echo "Starting the $EMULATOR_ID Android emulator with its visible window..."
  mkdir -p "$ROOT/build"
  "$EMULATOR" -avd "$EMULATOR_ID" -no-snapshot-load -no-boot-anim \
    >"$ROOT/build/android-emulator.log" 2>&1 </dev/null &

  for _ in {1..90}; do
    SERIAL="$(find_target_serial)"
    [[ -n "$SERIAL" ]] && break
    sleep 2
  done
fi
if [[ -z "$SERIAL" ]]; then
  fail "The emulator did not connect to adb within 3 minutes. Check Android Studio > Tools > Device Manager."
fi

echo "Waiting for Android to finish booting on $SERIAL..."
for _ in {1..90}; do
  if [[ "$("$ADB" -s "$SERIAL" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" == "1" ]]; then
    echo
    echo "Emulator is ready. Starting ResiDay on $SERIAL..."
    exec "$FLUTTER" run -d "$SERIAL"
  fi
  sleep 2
done

fail "Android connected, but did not finish booting within 3 minutes."
