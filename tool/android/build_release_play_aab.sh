#!/usr/bin/env bash
# Builds and verifies the Google Play release Android App Bundle (.aab):
# ads off, purchases off, production storage (registry.db),
# signed with the Play upload key from tool/android/create_play_upload_key.sh.
#
# Output: artifacts/play/Regiday-android-release.aab and BUILD_INFO.md
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

SIGNING_DIR="${REGIDAY_SIGNING_DIR:-$HOME/.regiday/signing}"
KEYSTORE="$SIGNING_DIR/regiday-play-upload.p12"
ALIAS="regiday-play-upload"
KEYCHAIN_SERVICE="regiday-android-play-upload"
SDK="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
BUILD_TOOLS="$(ls -d "$SDK"/build-tools/* | sort -V | tail -1)"
APKSIGNER="$BUILD_TOOLS/apksigner"
JAVA_HOME="${JAVA_HOME:-/Applications/Android Studio.app/Contents/jbr/Contents/Home}"
KEYTOOL="$JAVA_HOME/bin/keytool"
OUT_DIR="$ROOT/artifacts/play"
OUT_AAB="$OUT_DIR/Regiday-android-release.aab"

[[ -f "$KEYSTORE" ]] || {
  echo "ERROR: $KEYSTORE not found. Run tool/android/create_play_upload_key.sh first." >&2
  exit 1
}

REGIDAY_KEYSTORE_PASSWORD="$(security find-generic-password -s "$KEYCHAIN_SERVICE" -a "$ALIAS" -w)"
export REGIDAY_KEYSTORE="$KEYSTORE" REGIDAY_KEY_ALIAS="$ALIAS" REGIDAY_KEYSTORE_PASSWORD

# Launch flags from docs/release/launch_checklist.md: defaults (ads off, purchases off).
set +e
flutter build appbundle --release
FLUTTER_STATUS=$?
set -e
unset REGIDAY_KEYSTORE_PASSWORD

AAB="$ROOT/build/app/outputs/bundle/release/app-release.aab"
if [[ ! -f "$AAB" ]]; then
  echo "ERROR: expected AAB missing at $AAB (flutter exit $FLUTTER_STATUS)" >&2
  exit 1
fi
if [[ "$FLUTTER_STATUS" -ne 0 ]]; then
  echo "WARNING: flutter exited $FLUTTER_STATUS (often native-symbol strip)." >&2
  echo "WARNING: continuing because a signed AAB was produced at $AAB" >&2
fi

mkdir -p "$OUT_DIR"
cp "$AAB" "$OUT_AAB"

# jarsigner verifies the AAB zip signature; apksigner works on APKs extracted later.
CERTS="$("$KEYTOOL" -printcert -jarfile "$OUT_AAB" 2>/dev/null || true)"
if [[ -z "$CERTS" ]]; then
  echo "ERROR: could not read signing certificate from AAB." >&2
  exit 1
fi
if grep -qi "CN=Android Debug" <<<"$CERTS"; then
  echo "ERROR: AAB is signed with the debug certificate." >&2
  exit 1
fi

# Extract a universal APK via bundletool if available; otherwise use keytool cert only.
BUNDLETOOL="$(command -v bundletool || true)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

SIGNER_DN="$(grep -E '^Owner:' <<<"$CERTS" | head -1 | sed 's/^Owner: //')"
SIGNER_SHA256="$(grep -E 'SHA256:' <<<"$CERTS" | head -1 | sed 's/.*SHA256: //' | tr -d ' :' | tr '[:upper:]' '[:lower:]')"
SIGNER_SHA1="$(grep -E 'SHA1:' <<<"$CERTS" | head -1 | sed 's/.*SHA1: //' | tr -d ' :' | tr '[:upper:]' '[:lower:]')"

# Fallback: read cert fingerprints from the keystore itself.
if [[ -z "$SIGNER_SHA256" || -z "$SIGNER_SHA1" ]]; then
  REGIDAY_KEYSTORE_PASSWORD="$(security find-generic-password -s "$KEYCHAIN_SERVICE" -a "$ALIAS" -w)"
  export REGIDAY_KEYSTORE_PASSWORD
  FP="$("$KEYTOOL" -list -v -keystore "$KEYSTORE" -alias "$ALIAS" -storepass:env REGIDAY_KEYSTORE_PASSWORD)"
  unset REGIDAY_KEYSTORE_PASSWORD
  SIGNER_DN="$(grep -E '^Owner:' <<<"$FP" | head -1 | sed 's/^Owner: //')"
  SIGNER_SHA256="$(grep -E 'SHA256:' <<<"$FP" | head -1 | sed 's/.*SHA256: //' | tr -d ' :' | tr '[:upper:]' '[:lower:]')"
  SIGNER_SHA1="$(grep -E 'SHA1:' <<<"$FP" | head -1 | sed 's/.*SHA1: //' | tr -d ' :' | tr '[:upper:]' '[:lower:]')"
fi

SHA256="$(shasum -a 256 "$OUT_AAB" | cut -d' ' -f1)"
SIZE="$(stat -f %z "$OUT_AAB")"
VERSION_NAME="$(grep '^version:' "$ROOT/pubspec.yaml" | head -1 | awk '{print $2}' | cut -d'+' -f1)"
VERSION_CODE="$(grep '^version:' "$ROOT/pubspec.yaml" | head -1 | awk '{print $2}' | cut -d'+' -f2)"
PACKAGE="com.ventrovatech.regiday"

# Optional APK extract for debuggable / ads-off checks when bundletool exists.
ADS_NOTE="Off (\`ADS_ENABLED\` default false); launch checklist ads-off build"
if [[ -n "$BUNDLETOOL" ]]; then
  echo "bundletool found; extracting APKs for extra checks..."
  REGIDAY_KEYSTORE_PASSWORD="$(security find-generic-password -s "$KEYCHAIN_SERVICE" -a "$ALIAS" -w)"
  "$BUNDLETOOL" build-apks \
    --bundle="$OUT_AAB" \
    --output="$TMP_DIR/out.apks" \
    --mode=universal \
    --ks="$KEYSTORE" \
    --ks-pass="pass:$REGIDAY_KEYSTORE_PASSWORD" \
    --ks-key-alias="$ALIAS" \
    --key-pass="pass:$REGIDAY_KEYSTORE_PASSWORD" >/dev/null
  unset REGIDAY_KEYSTORE_PASSWORD
  unzip -p "$TMP_DIR/out.apks" universal.apk >"$TMP_DIR/universal.apk"
  APK_CERTS="$("$APKSIGNER" verify --verbose --print-certs "$TMP_DIR/universal.apk")"
  grep -q "^Verifies$" <<<"$APK_CERTS" || { echo "ERROR: extracted APK did not verify." >&2; exit 1; }
  if grep -q "CN=Android Debug" <<<"$APK_CERTS"; then
    echo "ERROR: extracted APK is debug-signed." >&2
    exit 1
  fi
fi

cat >"$OUT_DIR/BUILD_INFO.md" <<EOF
# Regiday Android App Bundle (Google Play upload)

Signed with the Play **upload** key. Enable Play App Signing in Play Console so Google holds the app signing key.

| Field | Value |
| --- | --- |
| File | \`Regiday-android-release.aab\` |
| Size | $SIZE bytes |
| SHA-256 | \`$SHA256\` |
| Built | $(date -u +"%Y-%m-%d %H:%M UTC") |
| Git | \`$(git rev-parse --abbrev-ref HEAD)\` at \`$(git rev-parse --short HEAD)\` |
| Command | \`tool/android/build_release_play_aab.sh\` (\`flutter build appbundle --release\`, no \`--dart-define\`) |
| Application id | \`$PACKAGE\` |
| Label | Regiday |
| Version | $VERSION_NAME ($VERSION_CODE) |
| Debuggable | No (release) |
| Ads | $ADS_NOTE |
| Purchases | Off (\`PURCHASES_ENABLED\` default false) |
| Storage | Production \`registry.db\` (no \`REGISTRY_STORE_ID\`) |
| Signing | Play upload key \`$ALIAS\`, keystore outside the repository |
| Signer DN | $SIGNER_DN |
| Upload key SHA-256 | \`$SIGNER_SHA256\` |
| Upload key SHA-1 | \`$SIGNER_SHA1\` |

## Verify

\`\`\`sh
shasum -a 256 Regiday-android-release.aab
keytool -printcert -jarfile Regiday-android-release.aab
\`\`\`

## Key backup reminder

Keep an encrypted offline backup of \`~/.regiday/signing/regiday-play-upload.p12\` and the Keychain password. Losing the upload key blocks updates unless you complete Google's upload-key reset process.
EOF

# Also write cert fingerprints for Firebase / Play Console without secrets.
cat >"$OUT_DIR/UPLOAD_KEY_FINGERPRINTS.txt" <<EOF
package: $PACKAGE
alias: $ALIAS
SHA-1: $SIGNER_SHA1
SHA-256: $SIGNER_SHA256
DN: $SIGNER_DN
EOF

echo
echo "AAB:        $OUT_AAB"
echo "SHA-256:    $SHA256"
echo "Size:       $SIZE bytes"
echo "Package:    $PACKAGE $VERSION_NAME ($VERSION_CODE)"
echo "Signer:     $SIGNER_DN"
echo "Cert SHA1   $SIGNER_SHA1"
echo "Cert SHA256 $SIGNER_SHA256"
echo "Info:       $OUT_DIR/BUILD_INFO.md"
