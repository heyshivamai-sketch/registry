#!/usr/bin/env bash
# Builds and verifies the private-QA Android release APK:
# ads off, purchases off, production storage (registry.db), all phone ABIs,
# signed with the QA key from tool/android/create_qa_signing_key.sh.
#
# Output: artifacts/qa/Regiday-android-release-qa.apk and BUILD_INFO.md
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

SIGNING_DIR="${REGIDAY_SIGNING_DIR:-$HOME/.regiday/signing}"
KEYSTORE="$SIGNING_DIR/regiday-qa-release.p12"
ALIAS="regiday-qa"
KEYCHAIN_SERVICE="regiday-android-qa-keystore"
SDK="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
BUILD_TOOLS="$(ls -d "$SDK"/build-tools/* | sort -V | tail -1)"
APKSIGNER="$BUILD_TOOLS/apksigner"
AAPT2="$BUILD_TOOLS/aapt2"
OUT_DIR="$ROOT/artifacts/qa"
OUT_APK="$OUT_DIR/Regiday-android-release-qa.apk"

[[ -f "$KEYSTORE" ]] || { echo "ERROR: $KEYSTORE not found. Run tool/android/create_qa_signing_key.sh." >&2; exit 1; }

REGIDAY_KEYSTORE_PASSWORD="$(security find-generic-password -s "$KEYCHAIN_SERVICE" -a "$ALIAS" -w)"
export REGIDAY_KEYSTORE="$KEYSTORE" REGIDAY_KEY_ALIAS="$ALIAS" REGIDAY_KEYSTORE_PASSWORD

# The documented launch flags: none. ADS_ENABLED and PURCHASES_ENABLED default
# to false and REGISTRY_STORE_ID is not set, so the app opens registry.db.
flutter build apk --release
unset REGIDAY_KEYSTORE_PASSWORD

APK="$ROOT/build/app/outputs/flutter-apk/app-release.apk"
mkdir -p "$OUT_DIR"
cp "$APK" "$OUT_APK"

CERTS="$("$APKSIGNER" verify --verbose --print-certs "$OUT_APK")"
echo "$CERTS"
grep -q "^Verifies$" <<<"$CERTS" || { echo "ERROR: apksigner did not verify the APK." >&2; exit 1; }
if grep -q "CN=Android Debug" <<<"$CERTS"; then
  echo "ERROR: APK is signed with the debug certificate." >&2
  exit 1
fi

BADGING="$("$AAPT2" dump badging "$OUT_APK")"
PERMS="$("$AAPT2" dump permissions "$OUT_APK")"
MANIFEST="$("$AAPT2" dump xmltree --file AndroidManifest.xml "$OUT_APK")"

for banned in AD_ID ACCESS_ADSERVICES_AD_ID ACCESS_ADSERVICES_ATTRIBUTION ACCESS_ADSERVICES_TOPICS; do
  if grep -q "\.$banned'" <<<"$PERMS"; then
    echo "ERROR: ads-off APK declares $banned." >&2
    exit 1
  fi
done
if grep -q "MobileAdsInitProvider\|com.google.android.gms.ads.APPLICATION_ID" <<<"$MANIFEST"; then
  echo "ERROR: ads-off APK starts or configures the Mobile Ads SDK." >&2
  exit 1
fi
if grep -q "application-debuggable" <<<"$BADGING"; then
  echo "ERROR: APK is debuggable." >&2
  exit 1
fi

field() { grep -o "$1='[^']*'" <<<"$BADGING" | head -1 | cut -d"'" -f2; }
PACKAGE="$(field "package: name")"
VERSION_CODE="$(field versionCode)"
VERSION_NAME="$(field versionName)"
LABEL="$(grep '^application-label:' <<<"$BADGING" | cut -d"'" -f2)"
ABIS="$(grep '^native-code:' <<<"$BADGING" | sed "s/native-code: //; s/'//g")"
MIN_SDK="$(grep '^minSdkVersion:' <<<"$BADGING" | cut -d"'" -f2)"
TARGET_SDK="$(grep '^targetSdkVersion:' <<<"$BADGING" | cut -d"'" -f2)"
SHA256="$(shasum -a 256 "$OUT_APK" | cut -d' ' -f1)"
SIZE="$(stat -f %z "$OUT_APK")"
SIGNER_DN="$(grep 'Signer #1 certificate DN' <<<"$CERTS" | cut -d: -f2- | sed 's/^ //')"
SIGNER_SHA256="$(grep 'Signer #1 certificate SHA-256 digest' <<<"$CERTS" | cut -d: -f2 | tr -d ' ')"
SIGNER_SHA1="$(grep 'Signer #1 certificate SHA-1 digest' <<<"$CERTS" | cut -d: -f2 | tr -d ' ')"
SCHEMES="$(grep -E '^Verified using v[0-9.]+ scheme' <<<"$CERTS" | tr '\n' ';' | sed 's/;$//; s/;/; /g')"
PERM_LIST="$(grep "uses-permission" <<<"$PERMS" | sed "s/.*name='//; s/'.*//" | sort | sed 's/^/- `/; s/$/`/')"

cat >"$OUT_DIR/BUILD_INFO.md" <<EOF
# Regiday Android release APK (private QA)

Not a store build. Do not upload or publish.

| Field | Value |
| --- | --- |
| File | \`Regiday-android-release-qa.apk\` |
| Size | $SIZE bytes |
| SHA-256 | \`$SHA256\` |
| Built | $(date -u +"%Y-%m-%d %H:%M UTC") |
| Git | \`$(git rev-parse --abbrev-ref HEAD)\` at \`$(git rev-parse --short HEAD)\` plus uncommitted changes |
| Command | \`tool/android/build_release_qa_apk.sh\` (runs \`flutter build apk --release\`, no \`--dart-define\`) |
| Application id | \`$PACKAGE\` |
| Label | $LABEL |
| Version | $VERSION_NAME ($VERSION_CODE) |
| minSdk / targetSdk | $MIN_SDK / $TARGET_SDK |
| ABIs | $ABIS |
| Debuggable | No |
| Ads | Off (\`ADS_ENABLED\` default false); no \`MobileAdsInitProvider\`, no AdMob App ID |
| Purchases | Off (\`PURCHASES_ENABLED\` default false) |
| Storage | Production \`registry.db\` (no \`REGISTRY_STORE_ID\`) |
| Signing | QA key \`$ALIAS\`, keystore outside the repository |
| Signer DN | $SIGNER_DN |
| Signer SHA-256 | \`$SIGNER_SHA256\` |
| Signer SHA-1 | \`$SIGNER_SHA1\` |
| Schemes | $SCHEMES |

## Declared permissions

$PERM_LIST

## Verify

\`\`\`sh
apksigner verify --verbose --print-certs Regiday-android-release-qa.apk
shasum -a 256 Regiday-android-release-qa.apk
\`\`\`
EOF

echo
echo "APK:        $OUT_APK"
echo "SHA-256:    $SHA256"
echo "Size:       $SIZE bytes"
echo "Package:    $PACKAGE $VERSION_NAME ($VERSION_CODE), label $LABEL"
echo "ABIs:       $ABIS"
echo "Signer:     $SIGNER_DN"
echo "Cert SHA256 $SIGNER_SHA256"
