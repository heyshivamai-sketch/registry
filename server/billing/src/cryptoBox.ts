import {
  createCipheriv,
  createDecipheriv,
  createHash,
  createPrivateKey,
  randomBytes,
  randomInt,
  sign,
  timingSafeEqual,
  type webcrypto,
} from 'node:crypto';
import type { StoreEnvironment, StorePlatform } from './types.ts';

const recoveryAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

export interface GrantClaims {
  v: 1;
  installationId: string;
  productId: string;
  platform: StorePlatform;
  environment: StoreEnvironment;
  status: 'active' | 'inactive';
  purchaseKey: string;
  verifiedAt: string;
  revalidateAfter: string;
}

export function canonicalGrant(claims: GrantClaims): string {
  return JSON.stringify({
    environment: claims.environment,
    installationId: claims.installationId,
    platform: claims.platform,
    productId: claims.productId,
    purchaseKey: claims.purchaseKey,
    revalidateAfter: claims.revalidateAfter,
    status: claims.status,
    v: claims.v,
    verifiedAt: claims.verifiedAt,
  });
}

export function signGrant(
  privateJwk: webcrypto.JsonWebKey,
  claims: GrantClaims,
): { canonical: string; signature: string } {
  const canonical = canonicalGrant(claims);
  const key = createPrivateKey({ key: privateJwk, format: 'jwk' });
  const signature = sign(null, Buffer.from(canonical, 'utf8'), key).toString('base64');
  return { canonical, signature };
}

export function sha256Hex(value: string): string {
  return createHash('sha256').update(value).digest('hex');
}

export function generateRecoveryCode(): string {
  let raw = '';
  for (let index = 0; index < 16; index += 1) {
    raw += recoveryAlphabet[randomInt(recoveryAlphabet.length)];
  }
  return `${raw.slice(0, 4)}-${raw.slice(4, 8)}-${raw.slice(8, 12)}-${raw.slice(12, 16)}`;
}

export function normalizeRecoveryCode(code: string): string {
  return code.replace(/-/g, '').toUpperCase();
}

export function hashRecoveryCode(pepper: string, code: string): string {
  return sha256Hex(`${pepper}:${normalizeRecoveryCode(code)}`);
}

export function recoveryCodesMatch(leftHex: string, rightHex: string): boolean {
  const left = Buffer.from(leftHex, 'hex');
  const right = Buffer.from(rightHex, 'hex');
  if (left.length === 0 || left.length !== right.length) {
    return false;
  }
  return timingSafeEqual(left, right);
}

export function encryptSecret(key: Buffer, plaintext: string): string {
  if (key.length !== 32) {
    throw new Error('token_key_length');
  }
  const iv = randomBytes(12);
  const cipher = createCipheriv('aes-256-gcm', key, iv);
  const ciphertext = Buffer.concat([cipher.update(plaintext, 'utf8'), cipher.final()]);
  const tag = cipher.getAuthTag();
  return `${iv.toString('base64url')}.${tag.toString('base64url')}.${ciphertext.toString('base64url')}`;
}

export function decryptSecret(key: Buffer, payload: string): string {
  const [ivPart, tagPart, bodyPart] = payload.split('.');
  if (!ivPart || !tagPart || !bodyPart) {
    throw new Error('ciphertext');
  }
  const decipher = createDecipheriv('aes-256-gcm', key, Buffer.from(ivPart, 'base64url'));
  decipher.setAuthTag(Buffer.from(tagPart, 'base64url'));
  return Buffer.concat([
    decipher.update(Buffer.from(bodyPart, 'base64url')),
    decipher.final(),
  ]).toString('utf8');
}
