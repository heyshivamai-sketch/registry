import { generateKeyPairSync, type webcrypto } from 'node:crypto';

export interface GrantKeyPair {
  privateJwk: webcrypto.JsonWebKey;
  publicKeyB64: string;
}

export function generateGrantKeyPair(): GrantKeyPair {
  const { privateKey, publicKey } = generateKeyPairSync('ed25519');
  const privateJwk = privateKey.export({ format: 'jwk' }) as webcrypto.JsonWebKey;
  const publicJwk = publicKey.export({ format: 'jwk' }) as { x?: string };
  if (!publicJwk.x) {
    throw new Error('missing_public_key');
  }
  return {
    privateJwk,
    publicKeyB64: Buffer.from(publicJwk.x, 'base64url').toString('base64'),
  };
}
