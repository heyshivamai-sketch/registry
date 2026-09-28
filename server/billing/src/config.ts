import type { webcrypto } from 'node:crypto';
import type { BillingConfig } from './billingService.ts';

export function loadConfig(env: NodeJS.ProcessEnv): BillingConfig & {
  port: number;
  databasePath: string;
  googleServiceAccountJson: string | null;
  appleIssuerId: string | null;
  appleKeyId: string | null;
  applePrivateKey: string | null;
  appleRootCaDir: string | null;
  appleAppAppleId: number | null;
  googlePubsubAudience: string;
  googlePubsubEmail: string;
} {
  return {
    port: numberFrom(env.PORT, 8080),
    databasePath: env.DATABASE_PATH?.trim() || './data/billing.sqlite',
    androidPackageName: env.ANDROID_PACKAGE_NAME?.trim() || 'com.registry.app',
    iosBundleId: env.IOS_BUNDLE_ID?.trim() || 'com.example.theRegistry',
    productId: env.LOCAL_PRO_PRODUCT_ID?.trim() || 'local_pro',
    revalidateAfterHours: numberFrom(env.REVALIDATE_AFTER_HOURS, 24),
    grantPrivateJwk: parseJwk(env.BILLING_GRANT_PRIVATE_JWK),
    tokenKey: parseTokenKey(env.BILLING_TOKEN_KEY_B64),
    recoveryPepper: placeholder(env.RECOVERY_CODE_PEPPER) ? '' : (env.RECOVERY_CODE_PEPPER ?? ''),
    verifyPerMinute: numberFrom(env.RATE_LIMIT_VERIFY_PER_MINUTE, 30),
    restorePerMinute: numberFrom(env.RATE_LIMIT_RESTORE_PER_MINUTE, 10),
    verifyBodyLimit: numberFrom(env.BODY_LIMIT_VERIFY_BYTES, 16384),
    notificationBodyLimit: numberFrom(env.BODY_LIMIT_NOTIFICATION_BYTES, 262144),
    googleServiceAccountJson: placeholder(env.GOOGLE_SERVICE_ACCOUNT_JSON)
      ? null
      : (env.GOOGLE_SERVICE_ACCOUNT_JSON ?? null),
    appleIssuerId: placeholder(env.APPLE_ISSUER_ID) ? null : (env.APPLE_ISSUER_ID ?? null),
    appleKeyId: placeholder(env.APPLE_KEY_ID) ? null : (env.APPLE_KEY_ID ?? null),
    applePrivateKey: placeholder(env.APPLE_PRIVATE_KEY) ? null : (env.APPLE_PRIVATE_KEY ?? null),
    appleRootCaDir: placeholder(env.APPLE_ROOT_CA_DIR) ? null : (env.APPLE_ROOT_CA_DIR ?? null),
    appleAppAppleId: placeholder(env.APPLE_APP_APPLE_ID) ? null : numberOrNull(env.APPLE_APP_APPLE_ID),
    googlePubsubAudience: placeholder(env.GOOGLE_PUBSUB_AUDIENCE)
      ? ''
      : (env.GOOGLE_PUBSUB_AUDIENCE ?? ''),
    googlePubsubEmail: placeholder(env.GOOGLE_PUBSUB_SERVICE_ACCOUNT_EMAIL)
      ? ''
      : (env.GOOGLE_PUBSUB_SERVICE_ACCOUNT_EMAIL ?? ''),
  };
}

function parseJwk(value: string | undefined): webcrypto.JsonWebKey | null {
  if (placeholder(value)) {
    return null;
  }
  try {
    return JSON.parse(value ?? '') as webcrypto.JsonWebKey;
  } catch {
    return null;
  }
}

function parseTokenKey(value: string | undefined): Buffer | null {
  if (placeholder(value)) {
    return null;
  }
  const key = Buffer.from(value ?? '', 'base64');
  return key.length === 32 ? key : null;
}

function placeholder(value: string | undefined): boolean {
  if (!value || value.trim().length === 0) {
    return true;
  }
  return value.startsWith('replace-with') || value === '0';
}

function numberFrom(value: string | undefined, fallback: number): number {
  if (!value || placeholder(value)) {
    return fallback;
  }
  const parsed = Number(value);
  return Number.isFinite(parsed) && parsed > 0 ? parsed : fallback;
}

function numberOrNull(value: string | undefined): number | null {
  if (!value || placeholder(value)) {
    return null;
  }
  const parsed = Number(value);
  return Number.isFinite(parsed) && parsed > 0 ? parsed : null;
}
