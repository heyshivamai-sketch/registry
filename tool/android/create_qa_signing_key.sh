#!/usr/bin/env bash
# Creates the private-QA Android release key once. Never overwrites.
#
# Keystore: $REGIDAY_SIGNING_DIR/regiday-qa-release.p12 (default ~/.regiday/signing)
# Password: macOS login Keychain, service "regiday-android-qa-keystore".
# Nothing secret is printed or written inside the repository.
set -euo pipefail

SIGNING_DIR="${REGIDAY_SIGNING_DIR:-$HOME/.regiday/signing}"
KEYSTORE="$SIGNING_DIR/regiday-qa-release.p12"
ALIAS="regiday-qa"
KEYCHAIN_SERVICE="regiday-android-qa-keystore"
KEYCHAIN_ACCOUNT="$ALIAS"

JAVA_HOME="${JAVA_HOME:-/Applications/Android Studio.app/Contents/jbr/Contents/Home}"
KEYTOOL="$JAVA_HOME/bin/keytool"

has_password() {
  security find-generic-password -s "$KEYCHAIN_SERVICE" -a "$KEYCHAIN_ACCOUNT" >/dev/null 2>&1
}

if [[ -e "$KEYSTORE" ]]; then
  if has_password; then
    echo "Keystore already exists: $KEYSTORE (not changed)."
    exit 0
  fi
  echo "ERROR: $KEYSTORE exists but its Keychain password is missing." >&2
  echo "Restore the password to Keychain service $KEYCHAIN_SERVICE; the keystore was not touched." >&2
  exit 1
fi

if has_password; then
  echo "ERROR: Keychain has $KEYCHAIN_SERVICE but $KEYSTORE is missing." >&2
  echo "Restore the keystore from backup instead of creating a new key." >&2
  exit 1
fi

mkdir -p "$SIGNING_DIR"
chmod 700 "$SIGNING_DIR"

REGIDAY_KEYSTORE_PASSWORD="$(openssl rand -base64 48 | tr -dc 'A-Za-z0-9' | cut -c1-40)"
export REGIDAY_KEYSTORE_PASSWORD

"$KEYTOOL" -genkeypair \
  -keystore "$KEYSTORE" \
  -storetype PKCS12 \
  -alias "$ALIAS" \
  -keyalg RSA -keysize 4096 -sigalg SHA256withRSA \
  -validity 10000 \
  -dname "CN=Regiday QA, OU=Private QA builds, O=Regiday candidate" \
  -storepass:env REGIDAY_KEYSTORE_PASSWORD \
  -keypass:env REGIDAY_KEYSTORE_PASSWORD \
  -noprompt >/dev/null

chmod 600 "$KEYSTORE"

security add-generic-password \
  -s "$KEYCHAIN_SERVICE" \
  -a "$KEYCHAIN_ACCOUNT" \
  -l "Regiday Android QA keystore" \
  -j "Password for $KEYSTORE (alias $ALIAS)" \
  -w "$REGIDAY_KEYSTORE_PASSWORD"
unset REGIDAY_KEYSTORE_PASSWORD

echo "Created $KEYSTORE (alias $ALIAS). Password stored in Keychain service $KEYCHAIN_SERVICE."
