import assert from 'node:assert/strict';
import { createPublicKey, randomBytes, verify, type JsonWebKey } from 'node:crypto';
import { readFileSync } from 'node:fs';
import type { AddressInfo } from 'node:net';
import { describe, it } from 'node:test';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { verifyPurchase, revalidatePurchase, handleAppleNotification, handleGoogleNotification, type BillingDeps } from '../src/billingService.ts';
import { openDatabase } from '../src/db.ts';
import { generateGrantKeyPair } from '../src/grantKeys.ts';
import { googleAcknowledgeUrl, googleProductGetUrl } from '../src/googlePlay.ts';
import { createBillingHttpServer } from '../src/httpApp.ts';
import { createLogger, redact } from '../src/log.ts';
import { routeAppleVerifiers } from '../src/appleStore.ts';
import { UnconfiguredEmailDelivery } from '../src/emailDelivery.ts';
import { TransientStoreError, WrongEnvironmentError, type AppleTransaction, type AppleVerifier, type GooglePlayClient, type GoogleProductPurchase } from '../src/types.ts';

const installA = '11111111-1111-4111-8111-111111111111';
const installB = '22222222-2222-4222-8222-222222222222';
const jws = 'eyJhbGciOiJFUzI1NiJ9.eyJzdWIiOiJ0ZXN0In0.signature';

class FakeGoogle implements GooglePlayClient {
  purchase: GoogleProductPurchase = purchasedGoogle();
  error: Error | null = null;
  ackError: Error | null = null;
  gets = 0;
  acks = 0;

  async getProductPurchase(): Promise<GoogleProductPurchase> {
    this.gets += 1;
    if (this.error) {
      throw this.error;
    }
    return this.purchase;
  }

  async acknowledgeProduct(): Promise<void> {
    this.acks += 1;
    if (this.ackError) {
      throw this.ackError;
    }
  }
}

class FakeApple implements AppleVerifier {
  transaction: AppleTransaction = purchasedApple();
  notificationType = 'REFUND';
  notificationId = 'note-1';
  signedDate = Date.parse('2026-09-28T00:00:00.000Z');
  signedTransaction: string | null = null;
  error: Error | null = null;
  calls = 0;
  seen: string[] = [];

  async verifyTransaction(signedTransaction: string): Promise<AppleTransaction> {
    this.calls += 1;
    this.seen.push(signedTransaction);
    if (this.error) {
      throw this.error;
    }
    return this.transaction;
  }

  async verifyNotification() {
    if (this.error) {
      throw this.error;
    }
    return {
      notificationUUID: this.notificationId,
      notificationType: this.notificationType,
      signedDate: this.signedDate,
      bundleId: this.transaction.bundleId,
      environment: this.transaction.environment,
      transaction: this.transaction,
      signedTransaction: this.signedTransaction,
    };
  }
}

function purchasedGoogle(): GoogleProductPurchase {
  return {
    purchaseState: 0,
    consumptionState: 0,
    acknowledgementState: 0,
    purchaseType: 0,
    orderId: 'GPA.1111',
    productId: 'local_pro',
    obfuscatedExternalAccountId: installA,
  };
}

function purchasedApple(): AppleTransaction {
  return {
    productId: 'local_pro',
    bundleId: 'com.example.theRegistry',
    environment: 'Sandbox',
    type: 'Non-Consumable',
    revocationDate: null,
    appAccountToken: installA,
    originalTransactionId: '1000001',
    transactionId: '1000001',
    inAppOwnershipType: 'PURCHASED',
  };
}

function harness(options?: { verifyPerMinute?: number; restorePerMinute?: number; verifyBodyLimit?: number }) {
  const keys = generateGrantKeyPair();
  const google = new FakeGoogle();
  const apple = new FakeApple();
  const lines: string[] = [];
  let current = new Date('2026-09-27T12:00:00.000Z');
  const deps: BillingDeps = {
    db: openDatabase(':memory:'),
    config: {
      androidPackageName: 'com.registry.app',
      iosBundleId: 'com.example.theRegistry',
      productId: 'local_pro',
      revalidateAfterHours: 24,
      grantPrivateJwk: keys.privateJwk,
      tokenKey: randomBytes(32),
      recoveryPepper: 'test-pepper',
      verifyPerMinute: options?.verifyPerMinute ?? 30,
      restorePerMinute: options?.restorePerMinute ?? 10,
      verifyBodyLimit: options?.verifyBodyLimit ?? 16384,
      notificationBodyLimit: 262144,
    },
    google,
    apple,
    googlePushAuth: { async verifyAuthorization(header) { return header === 'Bearer test'; } },
    email: new UnconfiguredEmailDelivery(),
    logger: createLogger((line) => lines.push(line)),
    now: () => new Date(current.getTime()),
  };
  return {
    deps,
    google,
    apple,
    lines,
    keys,
    setTime(iso: string) {
      current = new Date(iso);
    },
  };
}

function googleBody(overrides: Record<string, unknown> = {}) {
  return {
    platform: 'google',
    environment: 'sandbox',
    installationId: installA,
    productId: 'local_pro',
    purchaseToken: 'purchase-token-sandbox',
    ...overrides,
  };
}

function appleBody(overrides: Record<string, unknown> = {}) {
  return {
    platform: 'apple',
    environment: 'sandbox',
    installationId: installA,
    productId: 'local_pro',
    signedTransaction: jws,
    ...overrides,
  };
}

function rows(deps: BillingDeps) {
  return deps.db.prepare('SELECT status, installation_id, environment, acknowledged FROM purchases').all() as Array<{
    status: string;
    installation_id: string;
    environment: string;
    acknowledged: number;
  }>;
}

describe('purchase verification', () => {
  it('grants a sandbox purchase once and acknowledges without consuming', async () => {
    const { deps, google, lines } = harness();
    const first = await verifyPurchase(deps, googleBody(), { restore: false, ip: '10.0.0.1' });
    const second = await verifyPurchase(deps, googleBody(), { restore: false, ip: '10.0.0.1' });
    assert.equal(first.status, 200);
    assert.equal(first.body.result, 'granted');
    assert.equal(typeof first.body.recoveryCode, 'string');
    assert.equal(second.body.recoveryCode, undefined);
    assert.equal(rows(deps).length, 1);
    assert.equal(rows(deps)[0]?.status, 'active');
    assert.equal(rows(deps)[0]?.acknowledged, 1);
    assert.equal(google.acks, 2);
    assert.equal('consumeProduct' in google, false);
    assert.equal(lines.join('\n').includes('purchase-token-sandbox'), false);
    const canonical = String(first.body.canonical);
    assert.equal(
      canonical,
      '{"environment":"sandbox","installationId":"11111111-1111-4111-8111-111111111111","platform":"google","productId":"local_pro","purchaseKey":"GPA.1111","revalidateAfter":"2026-09-28T12:00:00.000Z","status":"active","v":1,"verifiedAt":"2026-09-27T12:00:00.000Z"}',
    );
    const signature = Buffer.from(String(first.body.signature), 'base64');
    const valid = verify(
      null,
      Buffer.from(canonical),
      createPublicKey({ key: deps.config.grantPrivateJwk! as JsonWebKey, format: 'jwk' }),
      signature,
    );
    assert.equal(valid, true);
    assert.equal(canonical.includes('purchase-token-sandbox'), false);
  });

  it('rejects a client premium flag, the wrong application, and a bare transaction id', async () => {
    const { deps, google, apple } = harness();
    const premium = await verifyPurchase(deps, { premium: true }, { restore: false, ip: '10.0.0.2' });
    const wrongApp = await verifyPurchase(
      deps,
      googleBody({ packageName: 'com.other.app' }),
      { restore: false, ip: '10.0.0.2' },
    );
    const bare = await verifyPurchase(
      deps,
      appleBody({ signedTransaction: '1000001' }),
      { restore: false, ip: '10.0.0.2' },
    );
    assert.equal(premium.body.error, 'invalid_request');
    assert.equal(wrongApp.body.error, 'wrong_application');
    assert.equal(bare.body.error, 'invalid_request');
    assert.equal(google.gets, 0);
    assert.equal(apple.calls, 0);
    assert.equal(rows(deps).length, 0);
  });

  it('rejects the wrong product, environment, and a consumed purchase without writing', async () => {
    const { deps, google } = harness();
    const wrongProduct = await verifyPurchase(
      deps,
      googleBody({ productId: 'other' }),
      { restore: false, ip: '10.0.0.3' },
    );
    google.purchase = { ...purchasedGoogle(), productId: 'other' };
    const storeProduct = await verifyPurchase(deps, googleBody(), { restore: false, ip: '10.0.0.3' });
    google.purchase = { ...purchasedGoogle(), purchaseType: undefined };
    const wrongEnvironment = await verifyPurchase(deps, googleBody(), { restore: false, ip: '10.0.0.3' });
    google.purchase = { ...purchasedGoogle(), consumptionState: 1 };
    const consumed = await verifyPurchase(deps, googleBody(), { restore: false, ip: '10.0.0.3' });
    assert.equal(wrongProduct.body.error, 'wrong_product');
    assert.equal(storeProduct.body.error, 'wrong_product');
    assert.equal(wrongEnvironment.body.error, 'wrong_environment');
    assert.equal(consumed.body.error, 'consumed');
    assert.equal(rows(deps).length, 0);
  });

  it('keeps pending, cancelled, and binding mismatches from granting another installation', async () => {
    const { deps, google } = harness();
    google.purchase = { ...purchasedGoogle(), purchaseState: 2 };
    const pending = await verifyPurchase(deps, googleBody(), { restore: false, ip: '10.0.0.4' });
    assert.equal(pending.body.result, 'pending');
    assert.equal(google.acks, 0);
    google.purchase = { ...purchasedGoogle(), purchaseState: 1, acknowledgementState: 1 };
    const cancelled = await verifyPurchase(deps, googleBody(), { restore: false, ip: '10.0.0.4' });
    assert.equal(cancelled.body.result, 'inactive');
    google.purchase = purchasedGoogle();
    await verifyPurchase(deps, googleBody(), { restore: false, ip: '10.0.0.4' });
    const stolen = await verifyPurchase(
      deps,
      googleBody({ installationId: installB }),
      { restore: false, ip: '10.0.0.4' },
    );
    assert.equal(stolen.status, 409);
    assert.equal(stolen.body.result, 'binding_mismatch');
    assert.deepEqual(
      rows(deps)
        .filter((row) => row.status === 'active')
        .map((row) => ({ ...row, acknowledged: Number(row.acknowledged) })),
      [{ status: 'active', installation_id: installA, environment: 'sandbox', acknowledged: 1 }],
    );
  });

  it('restores only with the restore code and does not change rows when the store is down', async () => {
    const { deps, google } = harness();
    const granted = await verifyPurchase(deps, googleBody(), { restore: false, ip: '10.0.0.5' });
    const code = String(granted.body.recoveryCode);
    const missing = await verifyPurchase(
      deps,
      googleBody({ installationId: installB }),
      { restore: true, ip: '10.0.0.5' },
    );
    assert.equal(missing.status, 409);
    const moved = await verifyPurchase(
      deps,
      googleBody({ installationId: installB, recoveryCode: code }),
      { restore: true, ip: '10.0.0.5' },
    );
    assert.equal(moved.body.result, 'granted');
    assert.equal(rows(deps)[0]?.installation_id, installB);
    const old = await revalidatePurchase(
      deps,
      {
        platform: 'google',
        environment: 'sandbox',
        installationId: installA,
        productId: 'local_pro',
        purchaseKey: 'GPA.1111',
      },
      '10.0.0.5',
    );
    assert.equal(old.body.result, 'inactive');
    assert.equal(rows(deps)[0]?.installation_id, installB);
    google.error = new TransientStoreError();
    const before = rows(deps);
    const failed = await revalidatePurchase(
      deps,
      {
        platform: 'google',
        environment: 'sandbox',
        installationId: installB,
        productId: 'local_pro',
        purchaseKey: 'GPA.1111',
      },
      '10.0.0.6',
    );
    assert.equal(failed.status, 503);
    assert.deepEqual(rows(deps), before);
  });

  it('retries acknowledgement and ignores stale or duplicate refund notifications', async () => {
    const { deps, google } = harness();
    google.ackError = new TransientStoreError();
    const granted = await verifyPurchase(deps, googleBody(), { restore: false, ip: '10.0.0.7' });
    assert.equal(granted.body.acknowledgementPending, true);
    assert.equal(rows(deps)[0]?.acknowledged, 0);
    google.ackError = null;
    await verifyPurchase(deps, googleBody(), { restore: false, ip: '10.0.0.7' });
    assert.equal(rows(deps)[0]?.acknowledged, 1);

    const stale = await handleGoogleNotification(
      deps,
      'Bearer test',
      pubsub('m-old', {
        packageName: 'com.registry.app',
        eventTimeMillis: String(Date.parse('2026-09-26T00:00:00.000Z')),
        voidedPurchaseNotification: { purchaseToken: 'purchase-token-sandbox', productType: 2 },
      }),
    );
    assert.equal(stale.body.result, 'granted');
    assert.equal(rows(deps)[0]?.status, 'active');

    const refund = await handleGoogleNotification(
      deps,
      'Bearer test',
      pubsub('m-new', {
        packageName: 'com.registry.app',
        eventTimeMillis: String(Date.parse('2026-09-28T00:00:00.000Z')),
        voidedPurchaseNotification: { purchaseToken: 'purchase-token-sandbox', productType: 2 },
      }),
    );
    assert.equal(refund.body.result, 'inactive');
    assert.equal(rows(deps)[0]?.status, 'revoked');
    const duplicate = await handleGoogleNotification(
      deps,
      'Bearer test',
      pubsub('m-new', {
        packageName: 'com.registry.app',
        eventTimeMillis: String(Date.parse('2026-09-28T00:00:00.000Z')),
        voidedPurchaseNotification: { purchaseToken: 'purchase-token-sandbox', productType: 2 },
      }),
    );
    assert.equal(duplicate.body.result, 'duplicate');
    assert.equal(rows(deps)[0]?.status, 'revoked');
    const unauthenticated = await handleGoogleNotification(deps, undefined, pubsub('m-x', {}));
    assert.equal(unauthenticated.status, 401);
    assert.equal(rows(deps)[0]?.status, 'revoked');
  });

  it('verifies Apple non-consumables and revokes from a signed notification', async () => {
    const { deps, apple } = harness();
    const granted = await verifyPurchase(deps, appleBody(), { restore: false, ip: '10.0.0.8' });
    assert.equal(granted.body.result, 'granted');
    apple.transaction = { ...purchasedApple(), bundleId: 'com.other.app' };
    const wrongBundle = await verifyPurchase(
      deps,
      appleBody({ installationId: installB }),
      { restore: false, ip: '10.0.0.8' },
    );
    assert.equal(wrongBundle.body.error, 'wrong_application');
    apple.transaction = { ...purchasedApple(), environment: 'Production' };
    const wrongEnvironment = await verifyPurchase(deps, appleBody(), { restore: false, ip: '10.0.0.8' });
    assert.equal(wrongEnvironment.body.error, 'wrong_environment');
    assert.equal(rows(deps).length, 1);

    apple.transaction = { ...purchasedApple(), revocationDate: Date.parse('2026-09-28T00:00:00.000Z') };
    apple.notificationType = 'REFUND';
    apple.signedDate = Date.parse('2026-09-28T00:00:00.000Z');
    const refund = await handleAppleNotification(deps, { signedPayload: jws });
    assert.equal(refund.body.result, 'inactive');
    assert.equal(rows(deps)[0]?.status, 'revoked');
    const duplicate = await handleAppleNotification(deps, { signedPayload: jws });
    assert.equal(duplicate.body.result, 'duplicate');

    apple.signedDate = Date.parse('2026-09-26T00:00:00.000Z');
    apple.notificationId = 'note-old';
    apple.transaction = purchasedApple();
    apple.notificationType = 'REFUND_REVERSED';
    const stale = await handleAppleNotification(deps, { signedPayload: jws });
    assert.equal(rows(deps)[0]?.status, 'revoked');
    assert.notEqual(stale.body.result, 'granted');
  });

  it('rejects a replayed restore code, a second use, and a code after refund', async () => {
    const { deps, google } = harness();
    const installC = '33333333-3333-4333-8333-333333333333';
    const granted = await verifyPurchase(deps, googleBody(), { restore: false, ip: '10.1.0.1' });
    const firstCode = String(granted.body.recoveryCode);
    const moved = await verifyPurchase(
      deps,
      googleBody({ installationId: installB, recoveryCode: firstCode }),
      { restore: true, ip: '10.1.0.1' },
    );
    assert.equal(moved.body.result, 'granted');
    const secondCode = String(moved.body.recoveryCode);
    assert.notEqual(secondCode, firstCode);
    google.purchase = { ...purchasedGoogle(), obfuscatedExternalAccountId: installB };
    const replay = await verifyPurchase(
      deps,
      googleBody({ installationId: installC, recoveryCode: firstCode }),
      { restore: true, ip: '10.1.0.2' },
    );
    assert.equal(replay.status, 409);
    assert.equal(rows(deps)[0]?.installation_id, installB);
    const reused = await verifyPurchase(
      deps,
      googleBody({ installationId: installC, recoveryCode: secondCode }),
      { restore: true, ip: '10.1.0.2' },
    );
    assert.equal(reused.body.result, 'granted');
    const again = await verifyPurchase(
      deps,
      googleBody({ installationId: installA, recoveryCode: secondCode }),
      { restore: true, ip: '10.1.0.3' },
    );
    assert.equal(again.status, 409);
    assert.equal(rows(deps)[0]?.installation_id, installC);
    google.purchase = {
      ...purchasedGoogle(),
      purchaseState: 1,
      obfuscatedExternalAccountId: installC,
    };
    const latest = String(reused.body.recoveryCode);
    const afterRefund = await verifyPurchase(
      deps,
      googleBody({ installationId: installA, recoveryCode: latest }),
      { restore: true, ip: '10.1.0.4' },
    );
    assert.equal(afterRefund.status, 409);
    assert.equal(afterRefund.body.result, 'binding_mismatch');
    assert.equal(rows(deps)[0]?.status, 'revoked');
    assert.equal(rows(deps)[0]?.installation_id, installC);
    const bearer = await verifyPurchase(
      deps,
      googleBody({ installationId: installA, purchaseToken: 'purchase-token-sandbox' }),
      { restore: false, ip: '10.1.0.5' },
    );
    assert.notEqual(bearer.body.result, 'granted');
  });

  it('does not refresh an active grant when the store rejects it, and a full refund revokes it', async () => {
    const { deps, google } = harness();
    await verifyPurchase(deps, googleBody(), { restore: false, ip: '10.1.1.1' });
    google.purchase = { ...purchasedGoogle(), productId: 'other' };
    const rejected = await revalidatePurchase(
      deps,
      {
        platform: 'google',
        environment: 'sandbox',
        installationId: installA,
        productId: 'local_pro',
        purchaseKey: 'GPA.1111',
      },
      '10.1.1.1',
    );
    assert.equal(rejected.status, 400);
    assert.equal(rejected.body.canonical, undefined);
    assert.equal(rows(deps)[0]?.status, 'active');
    google.purchase = { ...purchasedGoogle(), refundableQuantity: 0 };
    const refunded = await revalidatePurchase(
      deps,
      {
        platform: 'google',
        environment: 'sandbox',
        installationId: installA,
        productId: 'local_pro',
        purchaseKey: 'GPA.1111',
      },
      '10.1.1.1',
    );
    assert.equal(refunded.body.result, 'inactive');
    assert.equal(rows(deps)[0]?.status, 'revoked');
  });

  it('keeps the Apple transaction for a later revocation check', async () => {
    const { deps, apple } = harness();
    await verifyPurchase(deps, appleBody(), { restore: false, ip: '10.1.2.1' });
    apple.signedTransaction = 'txn.payload.sig';
    apple.notificationType = 'REFUND';
    apple.transaction = { ...purchasedApple(), revocationDate: Date.parse('2026-09-28T00:00:00.000Z') };
    const refund = await handleAppleNotification(deps, { signedPayload: jws });
    assert.equal(refund.body.result, 'inactive');
    apple.seen = [];
    const checked = await revalidatePurchase(
      deps,
      {
        platform: 'apple',
        environment: 'sandbox',
        installationId: installA,
        productId: 'local_pro',
        purchaseKey: '1000001',
      },
      '10.1.2.1',
    );
    assert.equal(checked.body.result, 'inactive');
    assert.deepEqual(apple.seen, ['txn.payload.sig']);
  });

  it('does not grant a family-shared Apple transaction or a rewarded Play purchase', async () => {
    const { deps, google, apple } = harness();
    apple.transaction = { ...purchasedApple(), inAppOwnershipType: 'FAMILY_SHARED' };
    const shared = await verifyPurchase(deps, appleBody(), { restore: false, ip: '10.1.3.1' });
    assert.equal(shared.body.error, 'wrong_ownership');
    apple.transaction = { ...purchasedApple(), inAppOwnershipType: undefined };
    const missing = await verifyPurchase(deps, appleBody(), { restore: false, ip: '10.1.3.1' });
    assert.equal(missing.body.error, 'wrong_ownership');
    google.purchase = { ...purchasedGoogle(), purchaseType: 2 };
    const rewarded = await verifyPurchase(deps, googleBody(), { restore: false, ip: '10.1.3.1' });
    assert.equal(rewarded.body.error, 'invalid_purchase');
    assert.equal(rows(deps).length, 0);
  });

  it('retries a Play notification when the store lookup fails and leaves the row', async () => {
    const { deps, google } = harness();
    await verifyPurchase(deps, googleBody(), { restore: false, ip: '10.1.4.1' });
    google.error = new Error('google_rejected');
    const before = rows(deps);
    const failed = await handleGoogleNotification(
      deps,
      'Bearer test',
      pubsub('m-fail', {
        packageName: 'com.registry.app',
        eventTimeMillis: String(Date.parse('2026-09-28T00:00:00.000Z')),
        voidedPurchaseNotification: { purchaseToken: 'purchase-token-sandbox', productType: 2 },
      }),
    );
    assert.equal(failed.status, 503);
    assert.deepEqual(rows(deps), before);
  });

  it('keeps sandbox and production purchases apart', async () => {
    const { deps, google } = harness();
    await verifyPurchase(deps, googleBody(), { restore: false, ip: '10.0.0.9' });
    google.purchase = { ...purchasedGoogle(), purchaseType: undefined, orderId: 'GPA.2222' };
    const production = await verifyPurchase(
      deps,
      googleBody({ environment: 'production', purchaseToken: 'production-token' }),
      { restore: false, ip: '10.0.0.9' },
    );
    assert.equal(production.body.result, 'granted');
    const stored = rows(deps).map((row) => row.environment).sort();
    assert.deepEqual(stored, ['production', 'sandbox']);
  });
});

describe('http limits', () => {
  it('rate limits, rejects oversized bodies, and redacts logs', async () => {
    const { deps, google, lines } = harness({ verifyPerMinute: 1, verifyBodyLimit: 500 });
    const server = createBillingHttpServer(deps);
    await new Promise<void>((resolve) => server.listen(0, '127.0.0.1', () => resolve()));
    try {
      const port = (server.address() as AddressInfo).port;
      const url = `http://127.0.0.1:${port}/v1/purchases/verify`;
      const first = await fetch(url, { method: 'POST', body: JSON.stringify(googleBody()) });
      const second = await fetch(url, { method: 'POST', body: JSON.stringify(googleBody()) });
      const oversized = await fetch(url, { method: 'POST', body: 'x'.repeat(800) });
      assert.equal(first.status, 200);
      assert.equal(second.status, 429);
      assert.equal(oversized.status, 413);
      assert.equal(google.gets, 1);
      assert.equal(lines.join('\n').includes('purchase-token-sandbox'), false);
      assert.equal(
        JSON.stringify(redact({ purchaseToken: 'purchase-token-sandbox' })).includes(
          'purchase-token-sandbox',
        ),
        false,
      );
    } finally {
      await new Promise<void>((resolve, reject) => {
        server.close((error) => (error ? reject(error) : resolve()));
      });
    }
  });

  it('does not call consume and routes Apple environments', async () => {
    const source = readFileSync(
      join(dirname(fileURLToPath(import.meta.url)), '../src/googlePlay.ts'),
      'utf8',
    );
    assert.equal(source.includes(':consume'), false);
    assert.equal(googleAcknowledgeUrl('com.registry.app', 'local_pro', 'tok').endsWith(':acknowledge'), true);
    assert.equal(googleProductGetUrl('com.registry.app', 'local_pro', 'a/b').includes('a%2Fb'), true);
    const sandbox: AppleVerifier = {
      async verifyTransaction() {
        throw new WrongEnvironmentError();
      },
      async verifyNotification() {
        throw new WrongEnvironmentError();
      },
    };
    const production: AppleVerifier = {
      async verifyTransaction() {
        return purchasedApple();
      },
      async verifyNotification() {
        throw new Error('unused');
      },
    };
    const routed = routeAppleVerifiers(sandbox, production);
    const transaction = await routed.verifyTransaction(jws);
    assert.equal(transaction.productId, 'local_pro');
  });
});

function pubsub(messageId: string, payload: unknown) {
  return {
    message: {
      messageId,
      data: Buffer.from(JSON.stringify(payload)).toString('base64'),
    },
  };
}
