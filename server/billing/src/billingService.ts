import type { DatabaseSync } from 'node:sqlite';
import type { webcrypto } from 'node:crypto';
import { readAccountSession, type AccountSession } from './accountService.ts';
import {
  canonicalGrant,
  decryptSecret,
  encryptSecret,
  generateRecoveryCode,
  hashRecoveryCode,
  normalizeRecoveryCode,
  recoveryCodesMatch,
  sha256Hex,
  signGrant,
  type GrantClaims,
} from './cryptoBox.ts';
import type { EmailDelivery } from './emailDelivery.ts';
import { decideApple, decideGoogle, type StoreFacts } from './decisions.ts';
import { allowRate, findPurchase, type PurchaseRow } from './db.ts';
import type { Logger } from './log.ts';
import {
  NotConfiguredError,
  TransientStoreError,
  WrongEnvironmentError,
  type AppleVerifier,
  type GooglePlayClient,
  type GooglePushAuth,
  type ServiceResult,
  type StoreEnvironment,
  type StorePlatform,
} from './types.ts';

const installationIdPattern =
  /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const jwsPattern = /^[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+$/;

export interface BillingConfig {
  androidPackageName: string;
  iosBundleId: string;
  productId: string;
  revalidateAfterHours: number;
  grantPrivateJwk: webcrypto.JsonWebKey | null;
  tokenKey: Buffer | null;
  recoveryPepper: string;
  verifyPerMinute: number;
  restorePerMinute: number;
  verifyBodyLimit: number;
  notificationBodyLimit: number;
}

export interface BillingDeps {
  db: DatabaseSync;
  config: BillingConfig;
  google: GooglePlayClient;
  apple: AppleVerifier;
  googlePushAuth: GooglePushAuth;
  email: EmailDelivery;
  logger: Logger;
  now: () => Date;
  recoveryCode?: () => string;
  emailCode?: () => string;
  sessionToken?: () => string;
}

interface VerifyValue {
  platform: StorePlatform;
  environment: StoreEnvironment;
  installationId: string;
  productId: string;
  purchaseToken?: string;
  signedTransaction?: string;
  recoveryCode?: string;
}

export async function verifyPurchase(
  deps: BillingDeps,
  body: unknown,
  options: { restore: boolean; ip: string; authorization?: string },
): Promise<ServiceResult> {
  const ready = configurationResult(deps);
  if (ready) {
    return ready;
  }
  const limit = options.restore ? deps.config.restorePerMinute : deps.config.verifyPerMinute;
  const bucket = `${options.restore ? 'restore' : 'verify'}:${options.ip}`;
  if (!allowRate(deps.db, bucket, deps.now().getTime(), limit)) {
    deps.logger.info('rate_limited', { bucket: options.restore ? 'restore' : 'verify' });
    return result(429, { error: 'rate_limited' });
  }
  const parsed = parseVerify(body, deps.config);
  if (!parsed.ok) {
    return result(parsed.status, { error: parsed.error });
  }
  try {
    const facts = await loadFacts(deps, parsed.value);
    return applyFacts(deps, {
      platform: parsed.value.platform,
      facts,
      installationId: parsed.value.installationId,
      packageOrBundle:
        parsed.value.platform === 'google'
          ? deps.config.androidPackageName
          : deps.config.iosBundleId,
      tokenHash: sha256Hex(parsed.value.purchaseToken ?? parsed.value.signedTransaction ?? ''),
      secret: parsed.value.purchaseToken ?? parsed.value.signedTransaction ?? '',
      mode: options.restore ? 'restore' : 'verify',
      recoveryCode: parsed.value.recoveryCode,
      session: readAccountSession(deps, options.authorization),
      eventTime: deps.now().toISOString(),
    });
  } catch (error) {
    return mapStoreError(deps, error);
  }
}

export async function revalidatePurchase(
  deps: BillingDeps,
  body: unknown,
  ip: string,
): Promise<ServiceResult> {
  const ready = configurationResult(deps);
  if (ready) {
    return ready;
  }
  if (!allowRate(deps.db, `verify:${ip}`, deps.now().getTime(), deps.config.verifyPerMinute)) {
    return result(429, { error: 'rate_limited' });
  }
  const parsed = parseRevalidate(body, deps.config);
  if (!parsed.ok) {
    return result(parsed.status, { error: parsed.error });
  }
  const row = findPurchase(
    deps.db,
    parsed.value.platform,
    parsed.value.environment,
    parsed.value.purchaseKey,
  );
  if (!row || row.installation_id !== parsed.value.installationId) {
    return signInactive(deps, {
      installationId: parsed.value.installationId,
      platform: parsed.value.platform,
      environment: parsed.value.environment,
      purchaseKey: parsed.value.purchaseKey,
    });
  }
  if (!row.token_ciphertext || !deps.config.tokenKey) {
    return signFromRow(deps, row);
  }
  try {
    const secret = decryptSecret(deps.config.tokenKey, row.token_ciphertext);
    const facts = await loadFacts(deps, {
      platform: parsed.value.platform,
      environment: parsed.value.environment,
      installationId: parsed.value.installationId,
      productId: deps.config.productId,
      purchaseToken: parsed.value.platform === 'google' ? secret : undefined,
      signedTransaction: parsed.value.platform === 'apple' ? secret : undefined,
    });
    if (facts.outcome === 'reject') {
      deps.logger.info('revalidate_rejected', { error: facts.error });
      if (!terminalStoreRejection(facts.error)) {
        return result(400, { error: facts.error ?? 'invalid_purchase' });
      }
      return applyFacts(deps, {
        platform: parsed.value.platform,
        facts: { ...facts, outcome: 'revoke', storeState: 'revoked', accountMatches: true },
        installationId: row.installation_id,
        packageOrBundle: row.package_or_bundle,
        tokenHash: row.token_hash,
        secret,
        mode: 'verify',
        eventTime: deps.now().toISOString(),
      });
    }
    return await applyFacts(deps, {
      platform: parsed.value.platform,
      facts,
      installationId: parsed.value.installationId,
      packageOrBundle: row.package_or_bundle,
      tokenHash: row.token_hash,
      secret,
      mode: 'verify',
      eventTime: deps.now().toISOString(),
    });
  } catch (error) {
    if (error instanceof TransientStoreError || error instanceof NotConfiguredError) {
      deps.logger.error('revalidate_unchanged', { error: error.code });
      return mapStoreError(deps, error);
    }
    deps.logger.error('revalidate_unchanged', { error: 'store' });
    return signFromRow(deps, row);
  }
}

export async function handleGoogleNotification(
  deps: BillingDeps,
  authorization: string | undefined,
  body: unknown,
): Promise<ServiceResult> {
  const authorized = await deps.googlePushAuth.verifyAuthorization(authorization);
  if (!authorized) {
    deps.logger.error('google_notification_rejected');
    return result(401, { error: 'unauthorized' });
  }
  const decoded = decodeGoogleMessage(body);
  if (!decoded.ok) {
    return result(400, { error: decoded.error });
  }
  const note = decoded.value;
  if (note.packageName !== deps.config.androidPackageName) {
    return result(200, { result: 'ignored' });
  }
  if (note.sku && note.sku !== deps.config.productId) {
    return result(200, { result: 'ignored' });
  }
  if (note.productType === 1) {
    return result(200, { result: 'ignored' });
  }
  if (!note.purchaseToken) {
    return result(200, { result: 'ignored' });
  }
  const eventTime = millisToIso(note.eventTimeMillis) ?? deps.now().toISOString();
  try {
    const purchase = await deps.google.getProductPurchase({
      packageName: deps.config.androidPackageName,
      productId: deps.config.productId,
      token: note.purchaseToken,
    });
    let facts = decideGoogle({
      expectedProduct: deps.config.productId,
      requestedEnvironment: googleEnvironmentFromPurchase(purchase.purchaseType),
      installationId: purchase.obfuscatedExternalAccountId ?? '',
      token: note.purchaseToken,
      purchase,
    });
    if (facts.outcome === 'reject' && facts.error !== 'wrong_environment') {
      deps.logger.info('google_notification_rejected_purchase', { error: facts.error });
      return result(200, { result: 'ignored' });
    }
    if (note.voided || note.notificationType === 2) {
      facts = { ...facts, outcome: 'revoke', storeState: 'revoked', needsAcknowledge: false };
    }
    const installationId = purchase.obfuscatedExternalAccountId ?? '';
    const existing = findPurchase(deps.db, 'google', facts.environment, facts.purchaseKey);
    if (!installationId && !existing) {
      return result(200, { result: 'ignored' });
    }
    facts = { ...facts, accountMatches: true };
    return await applyFacts(deps, {
      platform: 'google',
      facts,
      installationId: installationId || existing?.installation_id || '',
      packageOrBundle: deps.config.androidPackageName,
      tokenHash: sha256Hex(note.purchaseToken),
      secret: note.purchaseToken,
      mode: 'notification',
      eventTime,
      eventId: note.eventId,
      eventType: note.voided ? 'voided' : `one_time_${note.notificationType ?? 0}`,
    });
  } catch (error) {
    if (error instanceof TransientStoreError || error instanceof NotConfiguredError) {
      return mapStoreError(deps, error);
    }
    deps.logger.error('google_notification_failed');
    return result(503, { error: 'transient' });
  }
}

export async function handleAppleNotification(
  deps: BillingDeps,
  body: unknown,
): Promise<ServiceResult> {
  if (!body || typeof body !== 'object' || !('signedPayload' in body)) {
    return result(400, { error: 'invalid_request' });
  }
  const signedPayload = (body as { signedPayload?: unknown }).signedPayload;
  if (typeof signedPayload !== 'string' || !jwsPattern.test(signedPayload)) {
    return result(400, { error: 'invalid_request' });
  }
  try {
    const note = await deps.apple.verifyNotification(signedPayload);
    if (!note.notificationUUID) {
      return result(400, { error: 'invalid_purchase' });
    }
    if (note.notificationType === 'TEST') {
      return recordOnly(deps, {
        eventId: `apple:${note.notificationUUID}`,
        platform: 'apple',
        environment: 'sandbox',
        eventType: 'TEST',
        eventTime: deps.now().toISOString(),
      });
    }
    if (
      note.notificationType === 'REFUND_DECLINED' ||
      note.notificationType === 'CONSUMPTION_REQUEST'
    ) {
      return recordOnly(deps, {
        eventId: `apple:${note.notificationUUID}`,
        platform: 'apple',
        environment: appleEnv(note.environment) ?? 'production',
        eventType: note.notificationType,
        eventTime: millisToIso(note.signedDate) ?? deps.now().toISOString(),
      });
    }
    const transaction = note.transaction;
    if (!transaction) {
      return result(200, { result: 'ignored' });
    }
    const environment = appleEnv(transaction.environment);
    if (!environment) {
      return result(200, { result: 'ignored' });
    }
    const installationId = transaction.appAccountToken ?? '';
    let facts = decideApple({
      expectedBundle: deps.config.iosBundleId,
      expectedProduct: deps.config.productId,
      requestedEnvironment: environment,
      installationId,
      transaction,
    });
    if (facts.outcome === 'reject') {
      return result(200, { result: 'ignored' });
    }
    if (note.notificationType === 'REFUND' || note.notificationType === 'REVOKE') {
      facts = { ...facts, outcome: 'revoke', storeState: 'revoked' };
    }
    if (note.notificationType === 'REFUND_REVERSED' && transaction.revocationDate == null) {
      facts = { ...facts, outcome: 'grant', storeState: 'purchased' };
    }
    const existing = findPurchase(deps.db, 'apple', facts.environment, facts.purchaseKey);
    if (!facts.accountMatches && !existing) {
      return result(200, { result: 'ignored' });
    }
    const signedTransaction = note.signedTransaction ?? '';
    try {
      return await applyFacts(deps, {
        platform: 'apple',
        facts: { ...facts, accountMatches: true },
        installationId: installationId || existing?.installation_id || '',
        packageOrBundle: deps.config.iosBundleId,
        tokenHash: signedTransaction
          ? sha256Hex(signedTransaction)
          : (existing?.token_hash ?? sha256Hex(signedPayload)),
        secret: signedTransaction,
        mode: 'notification',
        eventTime: millisToIso(note.signedDate) ?? deps.now().toISOString(),
        eventId: `apple:${note.notificationUUID}`,
        eventType: note.notificationType,
      });
    } catch (error) {
      if (error instanceof NotConfiguredError || error instanceof TransientStoreError) {
        return mapStoreError(deps, error);
      }
      deps.logger.error('apple_notification_failed');
      return result(503, { error: 'transient' });
    }
  } catch (error) {
    if (error instanceof NotConfiguredError || error instanceof TransientStoreError) {
      return mapStoreError(deps, error);
    }
    deps.logger.error('apple_notification_rejected');
    return result(401, { error: 'invalid_purchase' });
  }
}

async function loadFacts(deps: BillingDeps, value: VerifyValue): Promise<StoreFacts> {
  if (value.platform === 'google') {
    const purchase = await deps.google.getProductPurchase({
      packageName: deps.config.androidPackageName,
      productId: deps.config.productId,
      token: value.purchaseToken ?? '',
    });
    return decideGoogle({
      expectedProduct: deps.config.productId,
      requestedEnvironment: value.environment,
      installationId: value.installationId,
      token: value.purchaseToken ?? '',
      purchase,
    });
  }
  const transaction = await deps.apple.verifyTransaction(value.signedTransaction ?? '');
  return decideApple({
    expectedBundle: deps.config.iosBundleId,
    expectedProduct: deps.config.productId,
    requestedEnvironment: value.environment,
    installationId: value.installationId,
    transaction,
  });
}

async function applyFacts(
  deps: BillingDeps,
  input: {
    platform: StorePlatform;
    facts: StoreFacts;
    installationId: string;
    packageOrBundle: string;
    tokenHash: string;
    secret: string;
    mode: 'verify' | 'restore' | 'notification';
    recoveryCode?: string;
    session?: AccountSession | null;
    eventTime: string;
    eventId?: string;
    eventType?: string;
  },
): Promise<ServiceResult> {
  if (input.facts.outcome === 'reject') {
    deps.logger.info('purchase_rejected', { error: input.facts.error });
    return result(400, { error: input.facts.error ?? 'invalid_purchase' });
  }
  const now = deps.now().toISOString();
  if (!input.facts.accountMatches) {
    const row = findPurchase(
      deps.db,
      input.platform,
      input.facts.environment,
      input.facts.purchaseKey,
    );
    if (input.facts.outcome === 'revoke' && row) {
      const revokedWrite = writePurchase(deps, {
        row,
        platform: input.platform,
        facts: input.facts,
        installationId: row.installation_id,
        packageOrBundle: input.packageOrBundle,
        tokenHash: input.tokenHash,
        secret: input.secret,
        status: 'revoked',
        recoveryHash: row.recovery_code_hash,
        accountId: row.account_id,
        eventTime: input.eventTime,
        eventId: input.eventId,
        eventType: input.eventType,
        acknowledged: row.acknowledged,
        now,
      });
      if (revokedWrite === 'duplicate') {
        return result(200, { result: 'duplicate' });
      }
      const callerOwns =
        row.installation_id === input.installationId ||
        (input.session != null && row.account_id === input.session.accountId);
      if (callerOwns) {
        return signInactive(deps, {
          installationId: input.installationId,
          platform: input.platform,
          environment: input.facts.environment,
          purchaseKey: input.facts.purchaseKey,
        });
      }
      deps.logger.info('binding_mismatch');
      return result(409, { result: 'binding_mismatch' });
    }
    if (
      row &&
      row.status === 'active' &&
      input.facts.outcome === 'grant' &&
      row.installation_id === input.installationId
    ) {
      return refreshHeldPurchase(deps, input, row, now);
    }
    const sessionOwns =
      input.session != null &&
      row != null &&
      row.status === 'active' &&
      input.facts.outcome === 'grant' &&
      row.account_id === input.session.accountId;
    if (sessionOwns && row) {
      if (row.last_event_at && row.last_event_at > input.eventTime) {
        return result(409, { result: 'binding_mismatch' });
      }
      return moveInstallation(deps, input, row, now, {
        accountId: row.account_id,
        expectAccountId: row.account_id,
      });
    }
    if (
      row &&
      row.status === 'active' &&
      input.facts.outcome === 'grant' &&
      row.account_id != null
    ) {
      deps.logger.info('account_sign_in_required');
      return result(409, { result: 'account_sign_in_required' });
    }
    const presentedHash =
      input.mode === 'restore' && input.facts.outcome === 'grant' && input.recoveryCode
        ? hashRecoveryCode(deps.config.recoveryPepper, input.recoveryCode)
        : null;
    if (presentedHash && row && row.status === 'active' && row.account_id == null) {
      if (row.last_event_at && row.last_event_at > input.eventTime) {
        return result(409, { result: 'binding_mismatch' });
      }
      return moveInstallation(deps, input, row, now, {
        accountId: input.session?.accountId ?? null,
        expectRecoveryHash: presentedHash,
        accountLink: input.session ? 'linked' : undefined,
      });
    }
    if (
      row &&
      row.status === 'active' &&
      input.facts.outcome === 'grant' &&
      row.account_id == null &&
      input.session != null
    ) {
      deps.logger.info('recovery_code_required');
      return result(409, { result: 'recovery_code_required' });
    }
    deps.logger.info('binding_mismatch');
    return result(409, { result: 'binding_mismatch' });
  }

  const existing = findPurchase(
    deps.db,
    input.platform,
    input.facts.environment,
    input.facts.purchaseKey,
  );
  if (existing?.last_event_at && existing.last_event_at > input.eventTime) {
    if (input.eventId) {
      insertEvent(deps, input, 0, now);
    }
    deps.logger.info('stale_event');
    return signFromRow(deps, existing);
  }
  let installationId = input.installationId;
  if (existing && existing.installation_id !== installationId) {
    if (input.mode !== 'notification') {
      return result(409, { result: 'binding_mismatch' });
    }
    installationId = existing.installation_id;
  }

  if (input.facts.outcome === 'pending') {
    if (existing?.status === 'active') {
      return signFromRow(deps, existing);
    }
    const pendingWrite = writePurchase(deps, {
      row: existing,
      platform: input.platform,
      facts: input.facts,
      installationId,
      packageOrBundle: input.packageOrBundle,
      tokenHash: input.tokenHash,
      secret: input.secret,
      status: 'pending',
      recoveryHash: existing?.recovery_code_hash ?? null,
      accountId: existing?.account_id ?? null,
      eventTime: input.eventTime,
      eventId: input.eventId,
      eventType: input.eventType,
      acknowledged: 0,
      now,
    });
    if (pendingWrite === 'duplicate') {
      return result(200, { result: 'duplicate' });
    }
    return result(200, { result: 'pending' });
  }

  if (input.facts.outcome === 'revoke') {
    const revokedWrite = writePurchase(deps, {
      row: existing,
      platform: input.platform,
      facts: input.facts,
      installationId,
      packageOrBundle: input.packageOrBundle,
      tokenHash: input.tokenHash,
      secret: input.secret,
      status: 'revoked',
      recoveryHash: existing?.recovery_code_hash ?? null,
      accountId: existing?.account_id ?? null,
      eventTime: input.eventTime,
      eventId: input.eventId,
      eventType: input.eventType,
      acknowledged: existing?.acknowledged ?? 0,
      now,
    });
    if (revokedWrite === 'duplicate') {
      return result(200, { result: 'duplicate' });
    }
    return signInactive(deps, {
      installationId,
      platform: input.platform,
      environment: input.facts.environment,
      purchaseKey: input.facts.purchaseKey,
    });
  }

  const created = !existing || existing.status !== 'active';
  const recoveryCode = created ? (deps.recoveryCode?.() ?? generateRecoveryCode()) : undefined;
  const recoveryHash = recoveryCode
    ? hashRecoveryCode(deps.config.recoveryPepper, recoveryCode)
    : (existing?.recovery_code_hash ?? null);
  const link = accountLinkForHeldPurchase(deps, input, existing, created);
  let grantWrite = writePurchase(deps, {
    row: existing,
    platform: input.platform,
    facts: input.facts,
    installationId,
    packageOrBundle: input.packageOrBundle,
    tokenHash: input.tokenHash,
    secret: input.secret,
    status: 'active',
    recoveryHash,
    accountId: link.accountId,
    eventTime: input.eventTime,
    eventId: input.eventId,
    eventType: input.eventType,
    acknowledged: input.facts.needsAcknowledge ? 0 : 1,
    now,
    expectRecoveryHash: link.expectRecoveryHash,
  });
  let accountLink = link.accountLink;
  if (grantWrite === 'stale_code') {
    accountLink = input.session && !existing?.account_id ? 'unchanged' : undefined;
    grantWrite = writePurchase(deps, {
      row: existing,
      platform: input.platform,
      facts: input.facts,
      installationId,
      packageOrBundle: input.packageOrBundle,
      tokenHash: input.tokenHash,
      secret: input.secret,
      status: 'active',
      recoveryHash,
      accountId: existing?.account_id ?? null,
      eventTime: input.eventTime,
      eventId: input.eventId,
      eventType: input.eventType,
      acknowledged: input.facts.needsAcknowledge ? 0 : 1,
      now,
    });
  }
  if (grantWrite === 'duplicate') {
    return result(200, { result: 'duplicate' });
  }
  if (grantWrite !== 'ok') {
    deps.logger.info('binding_mismatch');
    return result(409, { result: 'binding_mismatch' });
  }
  return finishGrant(deps, {
    platform: input.platform,
    facts: input.facts,
    installationId,
    secret: input.secret,
    status: 'active',
    recoveryCode,
    accountLink,
  });
}

async function finishGrant(
  deps: BillingDeps,
  input: {
    platform: StorePlatform;
    facts: StoreFacts;
    installationId: string;
    secret: string;
    status: 'active' | 'inactive';
    recoveryCode?: string;
    accountLink?: 'bound' | 'linked' | 'unchanged';
  },
): Promise<ServiceResult> {
  let acknowledgementPending = false;
  if (
    input.platform === 'google' &&
    input.status === 'active' &&
    input.facts.needsAcknowledge &&
    input.secret
  ) {
    acknowledgementPending = true;
  }
  const signed = signClaims(deps, {
    installationId: input.installationId,
    platform: input.platform,
    environment: input.facts.environment,
    purchaseKey: input.facts.purchaseKey,
    status: input.status,
  });
  if (acknowledgementPending) {
    const acknowledged = await acknowledgeLater(deps, input.facts, input.secret);
    acknowledgementPending = !acknowledged;
  }
  return result(200, {
    result: 'granted',
    ...signed,
    ...(input.recoveryCode ? { recoveryCode: input.recoveryCode } : {}),
    ...(input.accountLink ? { accountLink: input.accountLink } : {}),
    ...(acknowledgementPending ? { acknowledgementPending: true } : {}),
  });
}

async function acknowledgeLater(
  deps: BillingDeps,
  facts: StoreFacts,
  token: string,
): Promise<boolean> {
  try {
    await deps.google.acknowledgeProduct({
      packageName: deps.config.androidPackageName,
      productId: deps.config.productId,
      token,
    });
    deps.db
      .prepare(
        `UPDATE purchases SET acknowledged = 1, updated_at = ?
         WHERE platform = 'google' AND environment = ? AND purchase_key = ?`,
      )
      .run(deps.now().toISOString(), facts.environment, facts.purchaseKey);
    deps.logger.info('acknowledged');
    return true;
  } catch (error) {
    if (error instanceof TransientStoreError) {
      deps.logger.error('acknowledge_retry', { error: 'transient_store' });
      return false;
    }
    deps.logger.error('acknowledge_retry', { error: 'google_rejected' });
    return false;
  }
}

async function moveInstallation(
  deps: BillingDeps,
  input: {
    platform: StorePlatform;
    facts: StoreFacts;
    installationId: string;
    packageOrBundle: string;
    tokenHash: string;
    secret: string;
    eventTime: string;
    eventId?: string;
    eventType?: string;
  },
  row: PurchaseRow,
  now: string,
  options: {
    accountId: string | null;
    expectRecoveryHash?: string;
    expectAccountId?: string | null;
    accountLink?: 'linked';
  },
): Promise<ServiceResult> {
  const nextCode = deps.recoveryCode?.() ?? generateRecoveryCode();
  const nextHash = hashRecoveryCode(deps.config.recoveryPepper, nextCode);
  const rebound = writePurchase(deps, {
    row,
    platform: input.platform,
    facts: input.facts,
    installationId: input.installationId,
    packageOrBundle: input.packageOrBundle,
    tokenHash: input.tokenHash,
    secret: input.secret,
    status: 'active',
    recoveryHash: nextHash,
    accountId: options.accountId,
    eventTime: input.eventTime,
    eventId: input.eventId,
    eventType: input.eventType,
    acknowledged: input.facts.needsAcknowledge ? 0 : 1,
    now,
    expectRecoveryHash: options.expectRecoveryHash,
    expectAccountId: options.expectAccountId,
  });
  if (rebound === 'duplicate') {
    return result(200, { result: 'duplicate' });
  }
  if (rebound !== 'ok') {
    deps.logger.info('binding_mismatch');
    return result(409, { result: 'binding_mismatch' });
  }
  return finishGrant(deps, {
    platform: input.platform,
    facts: input.facts,
    installationId: input.installationId,
    secret: input.secret,
    status: 'active',
    recoveryCode: nextCode,
    accountLink: options.accountLink,
  });
}

async function refreshHeldPurchase(
  deps: BillingDeps,
  input: {
    platform: StorePlatform;
    facts: StoreFacts;
    packageOrBundle: string;
    tokenHash: string;
    secret: string;
    mode: 'verify' | 'restore' | 'notification';
    recoveryCode?: string;
    session?: AccountSession | null;
    eventTime: string;
    eventId?: string;
    eventType?: string;
  },
  row: PurchaseRow,
  now: string,
): Promise<ServiceResult> {
  const link = accountLinkForHeldPurchase(deps, input, row, false);
  let written = writePurchase(deps, {
    row,
    platform: input.platform,
    facts: input.facts,
    installationId: row.installation_id,
    packageOrBundle: input.packageOrBundle,
    tokenHash: input.tokenHash,
    secret: input.secret,
    status: 'active',
    recoveryHash: row.recovery_code_hash,
    accountId: link.accountId,
    eventTime: input.eventTime,
    eventId: input.eventId,
    eventType: input.eventType,
    acknowledged: input.facts.needsAcknowledge ? 0 : row.acknowledged,
    now,
    expectRecoveryHash: link.expectRecoveryHash,
  });
  let accountLink = link.accountLink;
  if (written === 'stale_code') {
    accountLink = input.session && !row.account_id ? 'unchanged' : undefined;
    written = writePurchase(deps, {
      row,
      platform: input.platform,
      facts: input.facts,
      installationId: row.installation_id,
      packageOrBundle: input.packageOrBundle,
      tokenHash: input.tokenHash,
      secret: input.secret,
      status: 'active',
      recoveryHash: row.recovery_code_hash,
      accountId: row.account_id,
      eventTime: input.eventTime,
      eventId: input.eventId,
      eventType: input.eventType,
      acknowledged: input.facts.needsAcknowledge ? 0 : row.acknowledged,
      now,
    });
  }
  if (written === 'duplicate') {
    return result(200, { result: 'duplicate' });
  }
  if (written !== 'ok') {
    return result(409, { result: 'binding_mismatch' });
  }
  return finishGrant(deps, {
    platform: input.platform,
    facts: input.facts,
    installationId: row.installation_id,
    secret: input.secret,
    status: 'active',
    accountLink,
  });
}

function accountLinkForHeldPurchase(
  deps: BillingDeps,
  input: {
    mode: 'verify' | 'restore' | 'notification';
    recoveryCode?: string;
    session?: AccountSession | null;
  },
  existing: PurchaseRow | undefined,
  created: boolean,
): {
  accountId: string | null;
  accountLink?: 'bound' | 'linked' | 'unchanged';
  expectRecoveryHash?: string;
} {
  if (created && input.session) {
    return { accountId: input.session.accountId, accountLink: 'bound' };
  }
  const current = existing?.account_id ?? null;
  if (
    !created &&
    current == null &&
    input.session &&
    input.mode === 'restore' &&
    input.recoveryCode
  ) {
    return {
      accountId: input.session.accountId,
      accountLink: 'linked',
      expectRecoveryHash: hashRecoveryCode(deps.config.recoveryPepper, input.recoveryCode),
    };
  }
  if (!created && current == null && input.session) {
    return { accountId: null, accountLink: 'unchanged' };
  }
  return { accountId: current };
}

function writePurchase(
  deps: BillingDeps,
  input: {
    row: PurchaseRow | undefined;
    platform: StorePlatform;
    facts: StoreFacts;
    installationId: string;
    packageOrBundle: string;
    tokenHash: string;
    secret: string;
    status: string;
    recoveryHash: string | null;
    accountId: string | null;
    eventTime: string;
    eventId?: string;
    eventType?: string;
    acknowledged: number;
    now: string;
    expectRecoveryHash?: string;
    expectAccountId?: string | null;
  },
): 'ok' | 'duplicate' | 'stale_code' | 'stale_account' {
  if (!deps.config.tokenKey) {
    throw new NotConfiguredError();
  }
  const ciphertext = input.secret
    ? encryptSecret(deps.config.tokenKey, input.secret)
    : input.row?.token_ciphertext ?? null;
  deps.db.exec('BEGIN IMMEDIATE');
  try {
    if (input.eventId && eventExists(deps, input.eventId)) {
      deps.db.exec('COMMIT');
      return 'duplicate';
    }
    if (input.expectRecoveryHash) {
      const current = findPurchase(
        deps.db,
        input.platform,
        input.facts.environment,
        input.facts.purchaseKey,
      );
      if (
        !current ||
        current.status !== 'active' ||
        !current.recovery_code_hash ||
        !recoveryCodesMatch(current.recovery_code_hash, input.expectRecoveryHash)
      ) {
        deps.db.exec('ROLLBACK');
        return 'stale_code';
      }
    }
    if (input.expectAccountId !== undefined) {
      const current = findPurchase(
        deps.db,
        input.platform,
        input.facts.environment,
        input.facts.purchaseKey,
      );
      if (!current || current.account_id !== input.expectAccountId) {
        deps.db.exec('ROLLBACK');
        return 'stale_account';
      }
    }
    deps.db
      .prepare(
        `INSERT INTO purchases (
           platform, environment, purchase_key, product_id, package_or_bundle,
           token_hash, token_ciphertext, installation_id, recovery_code_hash,
           account_id, status, store_state, acknowledged, last_event_at, created_at, updated_at
         ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
         ON CONFLICT(platform, environment, purchase_key) DO UPDATE SET
           token_hash = excluded.token_hash,
           token_ciphertext = excluded.token_ciphertext,
           installation_id = excluded.installation_id,
           recovery_code_hash = excluded.recovery_code_hash,
           account_id = excluded.account_id,
           status = excluded.status,
           store_state = excluded.store_state,
           acknowledged = excluded.acknowledged,
           last_event_at = excluded.last_event_at,
           updated_at = excluded.updated_at`,
      )
      .run(
        input.platform,
        input.facts.environment,
        input.facts.purchaseKey,
        deps.config.productId,
        input.packageOrBundle,
        input.tokenHash,
        ciphertext,
        input.installationId,
        input.recoveryHash,
        input.accountId,
        input.status,
        input.facts.storeState,
        input.acknowledged,
        input.eventTime,
        input.row?.created_at ?? input.now,
        input.now,
      );
    if (input.eventId && input.eventType) {
      deps.db
        .prepare(
          `INSERT INTO notification_events (
             event_id, platform, environment, purchase_key, event_type, event_time, applied, created_at
           ) VALUES (?, ?, ?, ?, ?, ?, 1, ?)`,
        )
        .run(
          input.eventId,
          input.platform,
          input.facts.environment,
          input.facts.purchaseKey,
          input.eventType,
          input.eventTime,
          input.now,
        );
    }
    deps.db.exec('COMMIT');
    return 'ok';
  } catch (error) {
    deps.db.exec('ROLLBACK');
    throw error;
  }
}

function insertEvent(
  deps: BillingDeps,
  input: {
    platform: StorePlatform;
    facts: StoreFacts;
    eventTime: string;
    eventId?: string;
    eventType?: string;
  },
  applied: number,
  now: string,
): void {
  if (!input.eventId || !input.eventType || eventExists(deps, input.eventId)) {
    return;
  }
  deps.db
    .prepare(
      `INSERT INTO notification_events (
         event_id, platform, environment, purchase_key, event_type, event_time, applied, created_at
       ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
    )
    .run(
      input.eventId,
      input.platform,
      input.facts.environment,
      input.facts.purchaseKey,
      input.eventType,
      input.eventTime,
      applied,
      now,
    );
}

function eventExists(deps: BillingDeps, eventId: string): boolean {
  const row = deps.db
    .prepare('SELECT event_id FROM notification_events WHERE event_id = ?')
    .get(eventId) as { event_id: string } | undefined;
  return row !== undefined;
}

function recordOnly(
  deps: BillingDeps,
  input: {
    eventId: string;
    platform: StorePlatform;
    environment: StoreEnvironment;
    eventType: string;
    eventTime: string;
  },
): ServiceResult {
  if (eventExists(deps, input.eventId)) {
    return result(200, { result: 'duplicate' });
  }
  deps.db
    .prepare(
      `INSERT INTO notification_events (
         event_id, platform, environment, purchase_key, event_type, event_time, applied, created_at
       ) VALUES (?, ?, ?, NULL, ?, ?, 0, ?)`,
    )
    .run(
      input.eventId,
      input.platform,
      input.environment,
      input.eventType,
      input.eventTime,
      deps.now().toISOString(),
    );
  return result(200, { result: 'ignored' });
}

function signFromRow(deps: BillingDeps, row: PurchaseRow): ServiceResult {
  if (row.status === 'active') {
    const signed = signClaims(deps, {
      installationId: row.installation_id,
      platform: row.platform as StorePlatform,
      environment: row.environment as StoreEnvironment,
      purchaseKey: row.purchase_key,
      status: 'active',
    });
    return result(200, { result: 'granted', ...signed });
  }
  return signInactive(deps, {
    installationId: row.installation_id,
    platform: row.platform as StorePlatform,
    environment: row.environment as StoreEnvironment,
    purchaseKey: row.purchase_key,
  });
}

function signInactive(
  deps: BillingDeps,
  input: {
    installationId: string;
    platform: StorePlatform;
    environment: StoreEnvironment;
    purchaseKey: string;
  },
): ServiceResult {
  const signed = signClaims(deps, { ...input, status: 'inactive' });
  return result(200, { result: 'inactive', ...signed });
}

function signClaims(
  deps: BillingDeps,
  input: {
    installationId: string;
    platform: StorePlatform;
    environment: StoreEnvironment;
    purchaseKey: string;
    status: 'active' | 'inactive';
  },
): { canonical: string; signature: string } {
  if (!deps.config.grantPrivateJwk) {
    throw new NotConfiguredError();
  }
  const verifiedAt = deps.now().toISOString();
  const revalidateAfter = new Date(
    deps.now().getTime() + deps.config.revalidateAfterHours * 60 * 60 * 1000,
  ).toISOString();
  const claims: GrantClaims = {
    v: 1,
    installationId: input.installationId,
    productId: deps.config.productId,
    platform: input.platform,
    environment: input.environment,
    status: input.status,
    purchaseKey: input.purchaseKey,
    verifiedAt,
    revalidateAfter,
  };
  const signed = signGrant(deps.config.grantPrivateJwk, claims);
  if (signed.canonical !== canonicalGrant(claims)) {
    throw new Error('canonical_mismatch');
  }
  return signed;
}

function configurationResult(deps: BillingDeps): ServiceResult | null {
  if (!deps.config.grantPrivateJwk || !deps.config.tokenKey || !deps.config.recoveryPepper) {
    return result(503, { error: 'not_configured' });
  }
  return null;
}

function mapStoreError(deps: BillingDeps, error: unknown): ServiceResult {
  if (error instanceof NotConfiguredError) {
    deps.logger.error('store_not_configured');
    return result(503, { error: 'not_configured' });
  }
  if (error instanceof TransientStoreError) {
    deps.logger.error('store_transient');
    return result(503, { error: 'transient' });
  }
  if (error instanceof WrongEnvironmentError) {
    deps.logger.info('purchase_rejected', { error: 'wrong_environment' });
    return result(400, { error: 'wrong_environment' });
  }
  deps.logger.error('store_rejected');
  return result(400, { error: 'invalid_purchase' });
}

function parseVerify(
  body: unknown,
  config: BillingConfig,
): { ok: true; value: VerifyValue } | { ok: false; status: number; error: string } {
  if (!body || typeof body !== 'object') {
    return { ok: false, status: 400, error: 'invalid_request' };
  }
  const record = body as Record<string, unknown>;
  const platform = record.platform;
  const environment = record.environment;
  const installationId = record.installationId;
  const productId = record.productId;
  if (platform !== 'google' && platform !== 'apple') {
    return { ok: false, status: 400, error: 'invalid_request' };
  }
  if (environment !== 'sandbox' && environment !== 'production') {
    return { ok: false, status: 400, error: 'invalid_request' };
  }
  if (typeof installationId !== 'string' || !installationIdPattern.test(installationId)) {
    return { ok: false, status: 400, error: 'invalid_request' };
  }
  if (typeof productId !== 'string' || productId !== config.productId) {
    return { ok: false, status: 400, error: 'wrong_product' };
  }
  if (typeof record.packageName === 'string' && record.packageName !== config.androidPackageName) {
    return { ok: false, status: 400, error: 'wrong_application' };
  }
  if (typeof record.bundleId === 'string' && record.bundleId !== config.iosBundleId) {
    return { ok: false, status: 400, error: 'wrong_application' };
  }
  const purchaseToken = record.purchaseToken;
  const signedTransaction = record.signedTransaction;
  if (platform === 'google') {
    if (typeof purchaseToken !== 'string' || !acceptableToken(purchaseToken)) {
      return { ok: false, status: 400, error: 'invalid_request' };
    }
  } else if (
    typeof signedTransaction !== 'string' ||
    signedTransaction.length > 20_000 ||
    !jwsPattern.test(signedTransaction)
  ) {
    return { ok: false, status: 400, error: 'invalid_request' };
  }
  let recoveryCode: string | undefined;
  if (record.recoveryCode !== undefined) {
    if (typeof record.recoveryCode !== 'string') {
      return { ok: false, status: 400, error: 'invalid_request' };
    }
    const normalized = normalizeRecoveryCode(record.recoveryCode);
    if (!/^[A-Z2-9]{16}$/.test(normalized)) {
      return { ok: false, status: 400, error: 'invalid_request' };
    }
    recoveryCode = record.recoveryCode;
  }
  return {
    ok: true,
    value: {
      platform,
      environment,
      installationId,
      productId,
      purchaseToken: typeof purchaseToken === 'string' ? purchaseToken : undefined,
      signedTransaction: typeof signedTransaction === 'string' ? signedTransaction : undefined,
      recoveryCode,
    },
  };
}

function parseRevalidate(
  body: unknown,
  config: BillingConfig,
):
  | {
      ok: true;
      value: {
        platform: StorePlatform;
        environment: StoreEnvironment;
        installationId: string;
        purchaseKey: string;
      };
    }
  | { ok: false; status: number; error: string } {
  if (!body || typeof body !== 'object') {
    return { ok: false, status: 400, error: 'invalid_request' };
  }
  const record = body as Record<string, unknown>;
  if (record.platform !== 'google' && record.platform !== 'apple') {
    return { ok: false, status: 400, error: 'invalid_request' };
  }
  if (record.environment !== 'sandbox' && record.environment !== 'production') {
    return { ok: false, status: 400, error: 'invalid_request' };
  }
  if (typeof record.installationId !== 'string' || !installationIdPattern.test(record.installationId)) {
    return { ok: false, status: 400, error: 'invalid_request' };
  }
  if (record.productId !== config.productId) {
    return { ok: false, status: 400, error: 'wrong_product' };
  }
  if (typeof record.purchaseKey !== 'string' || record.purchaseKey.length < 1 || record.purchaseKey.length > 256) {
    return { ok: false, status: 400, error: 'invalid_request' };
  }
  return {
    ok: true,
    value: {
      platform: record.platform,
      environment: record.environment,
      installationId: record.installationId,
      purchaseKey: record.purchaseKey,
    },
  };
}

function acceptableToken(token: string): boolean {
  if (token.length < 1 || token.length > 4096) {
    return false;
  }
  return !/[\u0000-\u001f]/.test(token);
}

function decodeGoogleMessage(body: unknown):
  | {
      ok: true;
      value: {
        packageName?: string;
        sku?: string;
        purchaseToken?: string;
        notificationType?: number;
        productType?: number;
        voided: boolean;
        eventTimeMillis?: string;
        eventId: string;
      };
    }
  | { ok: false; error: string } {
  if (!body || typeof body !== 'object' || !('message' in body)) {
    return { ok: false, error: 'invalid_request' };
  }
  const message = (body as { message?: { data?: unknown; messageId?: unknown } }).message;
  if (!message || typeof message.data !== 'string' || typeof message.messageId !== 'string') {
    return { ok: false, error: 'invalid_request' };
  }
  if (message.data.length > 100_000) {
    return { ok: false, error: 'invalid_request' };
  }
  let decoded: Record<string, unknown>;
  try {
    decoded = JSON.parse(Buffer.from(message.data, 'base64').toString('utf8')) as Record<
      string,
      unknown
    >;
  } catch {
    return { ok: false, error: 'invalid_request' };
  }
  const oneTime = decoded.oneTimeProductNotification as
    | { notificationType?: number; purchaseToken?: string; sku?: string }
    | undefined;
  const voided = decoded.voidedPurchaseNotification as
    | { purchaseToken?: string; productType?: number }
    | undefined;
  return {
    ok: true,
    value: {
      packageName: typeof decoded.packageName === 'string' ? decoded.packageName : undefined,
      sku: oneTime?.sku,
      purchaseToken: oneTime?.purchaseToken ?? voided?.purchaseToken,
      notificationType: oneTime?.notificationType,
      productType: voided?.productType,
      voided: voided !== undefined,
      eventTimeMillis:
        typeof decoded.eventTimeMillis === 'string' ? decoded.eventTimeMillis : undefined,
      eventId: `google:${message.messageId}`,
    },
  };
}

function googleEnvironmentFromPurchase(purchaseType: number | undefined): StoreEnvironment {
  return purchaseType === 0 ? 'sandbox' : 'production';
}

function appleEnv(value: string | undefined): StoreEnvironment | null {
  if (value === 'Sandbox') {
    return 'sandbox';
  }
  if (value === 'Production') {
    return 'production';
  }
  return null;
}

function terminalStoreRejection(error: string | undefined): boolean {
  return (
    error === 'consumed' ||
    error === 'wrong_ownership' ||
    error === 'wrong_product_type' ||
    error === 'invalid_purchase'
  );
}

function millisToIso(value: string | number | undefined): string | null {
  if (value === undefined) {
    return null;
  }
  const millis = typeof value === 'number' ? value : Number(value);
  if (!Number.isFinite(millis)) {
    return null;
  }
  return new Date(millis).toISOString();
}

function result(status: number, body: Record<string, unknown>): ServiceResult {
  return { status, body };
}
