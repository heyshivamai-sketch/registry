import assert from 'node:assert/strict';
import { randomBytes } from 'node:crypto';
import { describe, it } from 'node:test';
import {
  confirmEmailVerification,
  deleteAccount,
  startEmailVerification,
} from '../src/accountService.ts';
import { verifyPurchase, revalidatePurchase, type BillingDeps } from '../src/billingService.ts';
import { openDatabase } from '../src/db.ts';
import { EmailDeliveryFailedError, UnconfiguredEmailDelivery, type EmailDelivery } from '../src/emailDelivery.ts';
import { generateGrantKeyPair } from '../src/grantKeys.ts';
import { createLogger } from '../src/log.ts';
import type { AppleTransaction, GooglePlayClient, GoogleProductPurchase } from '../src/types.ts';

const installA = '11111111-1111-4111-8111-111111111111';
const installB = '22222222-2222-4222-8222-222222222222';
const installC = '33333333-3333-4333-8333-333333333333';
const jws = 'eyJhbGciOiJFUzI1NiJ9.eyJzdWIiOiJ0ZXN0In0.signature';

class RecordingEmail implements EmailDelivery {
  readonly configured = true;
  readonly sent: Array<{ to: string; code: string }> = [];
  fail = false;

  async sendVerification(message: { to: string; code: string }): Promise<void> {
    if (this.fail) {
      throw new EmailDeliveryFailedError();
    }
    this.sent.push(message);
  }
}

class FakeGoogle implements GooglePlayClient {
  purchase: GoogleProductPurchase = purchasedGoogle();

  async getProductPurchase(): Promise<GoogleProductPurchase> {
    return this.purchase;
  }

  async acknowledgeProduct(): Promise<void> {}
}

class FakeApple {
  transaction: AppleTransaction = purchasedApple();

  async verifyTransaction(): Promise<AppleTransaction> {
    return this.transaction;
  }

  async verifyNotification(): Promise<never> {
    throw new Error('unused');
  }
}

function purchasedGoogle(orderId = 'GPA.1111'): GoogleProductPurchase {
  return {
    purchaseState: 0,
    consumptionState: 0,
    acknowledgementState: 0,
    purchaseType: 0,
    orderId,
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

function harness(email: EmailDelivery = new RecordingEmail()) {
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
      verifyPerMinute: 30,
      restorePerMinute: 10,
      verifyBodyLimit: 16384,
      notificationBodyLimit: 262144,
    },
    google,
    apple,
    googlePushAuth: { async verifyAuthorization() { return false; } },
    email,
    logger: createLogger((line) => lines.push(line)),
    now: () => new Date(current.getTime()),
  };
  return { deps, google, apple, lines, email };
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

async function signIn(deps: BillingDeps, emailAddress = 'owner@example.com') {
  const started = await startEmailVerification(deps, { email: emailAddress }, '10.2.0.1');
  assert.equal(started.body.result, 'verification_pending');
  const email = deps.email as RecordingEmail;
  const code = email.sent.at(-1)?.code;
  assert.equal(typeof code, 'string');
  const confirmed = confirmEmailVerification(deps, { email: emailAddress, code }, '10.2.0.1');
  assert.equal(confirmed.body.result, 'signed_in');
  return {
    token: String(confirmed.body.sessionToken),
    authorization: `Bearer ${String(confirmed.body.sessionToken)}`,
  };
}

function purchaseAccount(deps: BillingDeps) {
  return deps.db.prepare('SELECT installation_id, account_id, status, platform FROM purchases').all() as Array<{
    installation_id: string;
    account_id: string | null;
    status: string;
    platform: string;
  }>;
}

describe('verified account recovery', () => {
  it('does not pretend an email was sent when delivery is not configured', async () => {
    const { deps, lines } = harness(new UnconfiguredEmailDelivery());
    const started = await startEmailVerification(deps, { email: 'owner@example.com' }, '10.2.0.2');
    assert.equal(started.status, 503);
    assert.equal(started.body.error, 'email_not_configured');
    assert.equal(started.body.code, undefined);
    const challenges = deps.db.prepare('SELECT id FROM email_challenges').all();
    assert.equal(challenges.length, 0);
    assert.equal(lines.join('\n').includes('owner@example.com'), false);
  });

  it('drops a challenge when delivery fails and does not report a send', async () => {
    const email = new RecordingEmail();
    email.fail = true;
    const { deps } = harness(email);
    const started = await startEmailVerification(deps, { email: 'owner@example.com' }, '10.2.0.3');
    assert.equal(started.status, 503);
    assert.equal(started.body.error, 'email_delivery_failed');
    assert.equal(started.body.result, undefined);
    assert.equal(deps.db.prepare('SELECT id FROM email_challenges').all().length, 0);
    assert.equal(email.sent.length, 0);
  });

  it('verifies an email without granting Local Pro', async () => {
    const { deps, lines } = harness();
    const session = await signIn(deps);
    assert.equal(purchaseAccount(deps).length, 0);
    assert.equal(lines.join('\n').includes(session.token), false);
    const email = deps.email as RecordingEmail;
    assert.equal(lines.join('\n').includes(email.sent[0]!.code), false);
    const again = confirmEmailVerification(
      deps,
      { email: 'owner@example.com', code: email.sent[0]!.code },
      '10.2.0.4',
    );
    assert.equal(again.status, 401);
    assert.equal(again.body.error, 'invalid_code');
  });

  it('binds a new purchase only after the email is verified', async () => {
    const { deps, google } = harness();
    const unsigned = await verifyPurchase(deps, googleBody(), { restore: false, ip: '10.2.1.1' });
    assert.equal(unsigned.body.result, 'granted');
    assert.equal(unsigned.body.accountLink, undefined);
    assert.equal(purchaseAccount(deps)[0]?.account_id, null);
    const code = String(unsigned.body.recoveryCode);

    const session = await signIn(deps, 'second@example.com');
    google.purchase = { ...purchasedGoogle('GPA.2222'), obfuscatedExternalAccountId: installB };
    const bound = await verifyPurchase(
      deps,
      googleBody({
        installationId: installB,
        purchaseToken: 'second-token',
        accountId: 'client-chosen',
        premium: true,
        sessionToken: 'body-token',
      }),
      { restore: false, ip: '10.2.1.2', authorization: session.authorization },
    );
    assert.equal(bound.body.result, 'granted');
    assert.equal(bound.body.accountLink, 'bound');
    const rows = purchaseAccount(deps);
    const linked = rows.find((row) => row.installation_id === installB);
    assert.equal(typeof linked?.account_id, 'string');
    assert.notEqual(linked?.account_id, 'client-chosen');
    const original = rows.find((row) => row.installation_id === installA);
    assert.equal(original?.account_id, null);

    google.purchase = purchasedGoogle();
    const sameDevice = await verifyPurchase(
      deps,
      googleBody(),
      { restore: true, ip: '10.2.1.3', authorization: session.authorization },
    );
    assert.equal(sameDevice.body.accountLink, 'unchanged');
    assert.equal(purchaseAccount(deps).find((row) => row.installation_id === installA)?.account_id, null);
    const linkedLater = await verifyPurchase(
      deps,
      googleBody({ recoveryCode: code }),
      { restore: true, ip: '10.2.1.4', authorization: session.authorization },
    );
    assert.equal(linkedLater.body.accountLink, 'linked');
    assert.equal(typeof purchaseAccount(deps).find((row) => row.installation_id === installA)?.account_id, 'string');
  });

  it('moves an account purchase only after the store entitlement is verified', async () => {
    const { deps } = harness();
    const session = await signIn(deps);
    const granted = await verifyPurchase(deps, googleBody(), {
      restore: false,
      ip: '10.2.2.1',
      authorization: session.authorization,
    });
    assert.equal(granted.body.accountLink, 'bound');
    const accountId = purchaseAccount(deps)[0]?.account_id;

    const moved = await verifyPurchase(
      deps,
      googleBody({ installationId: installB }),
      { restore: true, ip: '10.2.2.2', authorization: session.authorization },
    );
    assert.equal(moved.body.result, 'granted');
    assert.equal(purchaseAccount(deps)[0]?.installation_id, installB);
    assert.equal(purchaseAccount(deps)[0]?.account_id, accountId);

    const repeated = await verifyPurchase(
      deps,
      googleBody({ installationId: installB }),
      { restore: true, ip: '10.2.2.3', authorization: session.authorization },
    );
    assert.equal(repeated.body.result, 'granted');
    assert.equal(repeated.body.recoveryCode, undefined);
    assert.equal(purchaseAccount(deps)[0]?.installation_id, installB);

    const old = await revalidatePurchase(
      deps,
      {
        platform: 'google',
        environment: 'sandbox',
        installationId: installA,
        productId: 'local_pro',
        purchaseKey: 'GPA.1111',
      },
      '10.2.2.4',
    );
    assert.equal(old.body.result, 'inactive');
  });

  it('refuses takeover by another verified email, a transaction id, or a client flag', async () => {
    const { deps, google } = harness();
    const owner = await signIn(deps, 'owner@example.com');
    await verifyPurchase(deps, googleBody(), {
      restore: false,
      ip: '10.2.3.1',
      authorization: owner.authorization,
    });
    const accountId = purchaseAccount(deps)[0]?.account_id;
    const attacker = await signIn(deps, 'attacker@example.com');

    const stolen = await verifyPurchase(
      deps,
      googleBody({ installationId: installC, premium: true, accountId: attacker.token }),
      { restore: true, ip: '10.2.3.2', authorization: attacker.authorization },
    );
    assert.equal(stolen.status, 409);
    assert.equal(stolen.body.result, 'account_sign_in_required');
    assert.equal(stolen.body.email, undefined);
    assert.equal(stolen.body.accountId, undefined);
    assert.equal(stolen.body.canonical, undefined);
    assert.equal(purchaseAccount(deps)[0]?.installation_id, installA);
    assert.equal(purchaseAccount(deps)[0]?.account_id, accountId);

    const bare = await verifyPurchase(
      deps,
      { platform: 'apple', environment: 'sandbox', installationId: installC, productId: 'local_pro', transactionId: '1000001', premium: true },
      { restore: true, ip: '10.2.3.3', authorization: attacker.authorization },
    );
    assert.equal(bare.status, 400);
    assert.equal(purchaseAccount(deps).length, 1);
    assert.equal(google.purchase.orderId, 'GPA.1111');

    const emailOnly = confirmEmailVerification(deps, { email: 'nobody@example.com', code: '00000000' }, '10.2.3.4');
    assert.notEqual(emailOnly.body.result, 'granted');
    assert.equal(purchaseAccount(deps)[0]?.status, 'active');
  });

  it('leaves an installation-only purchase unchanged unless the restore code is presented', async () => {
    const { deps } = harness();
    const granted = await verifyPurchase(deps, googleBody(), { restore: false, ip: '10.2.4.1' });
    const code = String(granted.body.recoveryCode);
    const session = await signIn(deps);

    const blocked = await verifyPurchase(
      deps,
      googleBody({ installationId: installB }),
      { restore: true, ip: '10.2.4.2', authorization: session.authorization },
    );
    assert.equal(blocked.status, 409);
    assert.equal(blocked.body.result, 'recovery_code_required');
    assert.equal(purchaseAccount(deps)[0]?.installation_id, installA);
    assert.equal(purchaseAccount(deps)[0]?.account_id, null);

    const linked = await verifyPurchase(
      deps,
      googleBody({ installationId: installB, recoveryCode: code }),
      { restore: true, ip: '10.2.4.3', authorization: session.authorization },
    );
    assert.equal(linked.body.result, 'granted');
    assert.equal(linked.body.accountLink, 'linked');
    assert.equal(purchaseAccount(deps)[0]?.installation_id, installB);
    assert.equal(typeof purchaseAccount(deps)[0]?.account_id, 'string');
  });

  it('moves an account-bound purchase only for that account session', async () => {
    const { deps, lines } = harness();
    const owner = await signIn(deps, 'owner@example.com');
    const granted = await verifyPurchase(deps, googleBody(), {
      restore: false,
      ip: '10.2.5.1',
      authorization: owner.authorization,
    });
    const code = String(granted.body.recoveryCode);
    const accountId = purchaseAccount(deps)[0]?.account_id;
    assert.equal(typeof accountId, 'string');

    const anonymous = await verifyPurchase(
      deps,
      googleBody({ installationId: installB, recoveryCode: code }),
      { restore: true, ip: '10.2.5.2' },
    );
    assert.equal(anonymous.status, 409);
    assert.equal(anonymous.body.result, 'account_sign_in_required');
    assert.equal(anonymous.body.email, undefined);
    assert.equal(anonymous.body.accountId, undefined);
    assert.equal(anonymous.body.canonical, undefined);
    assert.equal(JSON.stringify(anonymous.body).includes(accountId!), false);
    assert.equal(JSON.stringify(anonymous.body).includes('owner@example.com'), false);
    assert.equal(purchaseAccount(deps)[0]?.installation_id, installA);
    assert.equal(purchaseAccount(deps)[0]?.account_id, accountId);

    const attacker = await signIn(deps, 'attacker@example.com');
    const takeover = await verifyPurchase(
      deps,
      googleBody({ installationId: installC, recoveryCode: code }),
      { restore: true, ip: '10.2.5.3', authorization: attacker.authorization },
    );
    assert.equal(takeover.status, 409);
    assert.equal(takeover.body.result, 'account_sign_in_required');
    assert.equal(takeover.body.email, undefined);
    assert.equal(takeover.body.accountId, undefined);
    assert.equal(JSON.stringify(takeover.body).includes(accountId!), false);
    assert.equal(purchaseAccount(deps)[0]?.installation_id, installA);
    assert.equal(purchaseAccount(deps)[0]?.account_id, accountId);

    const moved = await verifyPurchase(
      deps,
      googleBody({ installationId: installB, recoveryCode: code }),
      { restore: true, ip: '10.2.5.4', authorization: owner.authorization },
    );
    assert.equal(moved.body.result, 'granted');
    assert.equal(purchaseAccount(deps)[0]?.installation_id, installB);
    assert.equal(purchaseAccount(deps)[0]?.account_id, accountId);
    const rotated = String(moved.body.recoveryCode);
    assert.notEqual(rotated, code);

    const replayed = await verifyPurchase(
      deps,
      googleBody({ installationId: installB, recoveryCode: rotated }),
      { restore: true, ip: '10.2.5.5', authorization: owner.authorization },
    );
    assert.equal(replayed.body.result, 'granted');
    assert.equal(replayed.body.recoveryCode, undefined);
    assert.equal(purchaseAccount(deps)[0]?.installation_id, installB);
    assert.equal(purchaseAccount(deps)[0]?.account_id, accountId);

    const oldCode = await verifyPurchase(
      deps,
      googleBody({ installationId: installC, recoveryCode: code }),
      { restore: true, ip: '10.2.5.6' },
    );
    const newCode = await verifyPurchase(
      deps,
      googleBody({ installationId: installC, recoveryCode: rotated }),
      { restore: true, ip: '10.2.5.7' },
    );
    assert.equal(oldCode.body.result, 'account_sign_in_required');
    assert.equal(newCode.body.result, 'account_sign_in_required');
    assert.equal(purchaseAccount(deps)[0]?.installation_id, installB);
    assert.equal(purchaseAccount(deps)[0]?.account_id, accountId);
    const logged = lines.join('\n');
    assert.equal(logged.includes(code), false);
    assert.equal(logged.includes(rotated), false);
    assert.equal(logged.includes('owner@example.com'), false);
    assert.equal(logged.includes(accountId!), false);
  });

  it('does not move an Apple purchase when a Google entitlement is restored', async () => {
    const { deps, google } = harness();
    const session = await signIn(deps);
    await verifyPurchase(deps, appleBody(), {
      restore: false,
      ip: '10.2.6.1',
      authorization: session.authorization,
    });
    google.purchase = purchasedGoogle('GPA.9000');
    const googleGrant = await verifyPurchase(
      deps,
      googleBody({ purchaseToken: 'google-token' }),
      { restore: false, ip: '10.2.6.2', authorization: session.authorization },
    );
    assert.equal(googleGrant.body.result, 'granted');
    const rows = purchaseAccount(deps);
    assert.deepEqual(rows.map((row) => row.platform).sort(), ['apple', 'google']);
    const appleMoved = await verifyPurchase(
      deps,
      googleBody({ installationId: installB, purchaseToken: 'google-token' }),
      { restore: true, ip: '10.2.6.3', authorization: session.authorization },
    );
    assert.equal(appleMoved.body.result, 'granted');
    const after = purchaseAccount(deps);
    assert.equal(after.find((row) => row.platform === 'apple')?.installation_id, installA);
    assert.equal(after.find((row) => row.platform === 'google')?.installation_id, installB);
  });

  it('revokes a refund and does not grant it again from the account', async () => {
    const { deps, google } = harness();
    const session = await signIn(deps);
    const granted = await verifyPurchase(deps, googleBody(), {
      restore: false,
      ip: '10.2.7.1',
      authorization: session.authorization,
    });
    const code = String(granted.body.recoveryCode);
    google.purchase = { ...purchasedGoogle(), purchaseState: 1, acknowledgementState: 1 };
    const revoked = await verifyPurchase(
      deps,
      googleBody({ installationId: installB }),
      { restore: true, ip: '10.2.7.2', authorization: session.authorization },
    );
    assert.equal(revoked.body.result, 'inactive');
    assert.notEqual(revoked.body.status, 'active');
    assert.equal(purchaseAccount(deps)[0]?.status, 'revoked');
    google.purchase = purchasedGoogle();
    const again = await verifyPurchase(
      deps,
      googleBody({ installationId: installB }),
      { restore: true, ip: '10.2.7.3', authorization: session.authorization },
    );
    assert.notEqual(again.body.result, 'granted');
    assert.equal(purchaseAccount(deps)[0]?.status, 'revoked');
    const withCode = await verifyPurchase(
      deps,
      googleBody({ installationId: installC, recoveryCode: code }),
      { restore: true, ip: '10.2.7.4' },
    );
    assert.notEqual(withCode.body.result, 'granted');
    assert.equal(withCode.body.email, undefined);
    assert.equal(withCode.body.accountId, undefined);
    assert.equal(purchaseAccount(deps)[0]?.status, 'revoked');
    assert.equal(purchaseAccount(deps)[0]?.installation_id, installA);
  });

  it('unlinks purchases on account deletion and does not inherit them on a new sign-in', async () => {
    const { deps } = harness();
    const session = await signIn(deps, 'owner@example.com');
    const granted = await verifyPurchase(deps, googleBody(), {
      restore: false,
      ip: '10.2.8.1',
      authorization: session.authorization,
    });
    const code = String(granted.body.recoveryCode);
    const originalAccountId = purchaseAccount(deps)[0]?.account_id;
    const deleted = deleteAccount(deps, session.authorization, '10.2.8.2');
    assert.equal(deleted.body.result, 'deleted');
    assert.equal(deleted.body.canonical, undefined);
    const row = purchaseAccount(deps)[0];
    assert.equal(row?.status, 'active');
    assert.equal(row?.installation_id, installA);
    assert.equal(row?.account_id, null);
    const stale = await verifyPurchase(
      deps,
      googleBody({ installationId: installB }),
      { restore: true, ip: '10.2.8.3', authorization: session.authorization },
    );
    assert.equal(stale.status, 409);
    assert.equal(purchaseAccount(deps)[0]?.installation_id, installA);

    const again = await signIn(deps, 'owner@example.com');
    const notInherited = await verifyPurchase(
      deps,
      googleBody({ installationId: installB }),
      { restore: true, ip: '10.2.8.4', authorization: again.authorization },
    );
    assert.equal(notInherited.body.result, 'recovery_code_required');
    assert.equal(purchaseAccount(deps)[0]?.account_id, null);
    assert.equal(purchaseAccount(deps)[0]?.installation_id, installA);

    const relinked = await verifyPurchase(
      deps,
      googleBody({ installationId: installB, recoveryCode: code }),
      { restore: true, ip: '10.2.8.5', authorization: again.authorization },
    );
    const newAccount = deps.db
      .prepare(`SELECT id FROM accounts WHERE email = ? AND deleted_at IS NULL`)
      .get('owner@example.com') as { id: string };
    assert.equal(relinked.body.result, 'granted');
    assert.equal(relinked.body.accountLink, 'linked');
    assert.equal(purchaseAccount(deps)[0]?.installation_id, installB);
    assert.equal(purchaseAccount(deps)[0]?.account_id, newAccount.id);
    assert.notEqual(newAccount.id, originalAccountId);
  });
});
