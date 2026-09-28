import { randomUUID } from 'node:crypto';
import {
  generateEmailCode,
  generateSessionToken,
  hashEmailCode,
  hashSessionToken,
  normalizeEmail,
  recoveryCodesMatch,
} from './cryptoBox.ts';
import { allowRate } from './db.ts';
import {
  EmailDeliveryFailedError,
  EmailNotConfiguredError,
  type EmailDelivery,
} from './emailDelivery.ts';
import type { Logger } from './log.ts';
import type { ServiceResult } from './types.ts';
import type { DatabaseSync } from 'node:sqlite';

export interface AccountDeps {
  db: DatabaseSync;
  config: { recoveryPepper: string };
  email: EmailDelivery;
  logger: Logger;
  now: () => Date;
  emailCode?: () => string;
  sessionToken?: () => string;
}

const codeTtlMs = 15 * 60 * 1000;
const sessionTtlMs = 30 * 24 * 60 * 60 * 1000;
const maxAttempts = 5;

export interface AccountSession {
  accountId: string;
  email: string;
}

export function readAccountSession(
  deps: AccountDeps,
  authorization: string | undefined,
): AccountSession | null {
  const token = bearerToken(authorization);
  if (!token || !deps.config.recoveryPepper) {
    return null;
  }
  const row = deps.db
    .prepare(
      `SELECT s.account_id, s.expires_at, s.revoked_at, a.email, a.deleted_at
       FROM account_sessions s
       JOIN accounts a ON a.id = s.account_id
       WHERE s.token_hash = ?`,
    )
    .get(hashSessionToken(token)) as
    | {
        account_id: string;
        expires_at: string;
        revoked_at: string | null;
        email: string;
        deleted_at: string | null;
      }
    | undefined;
  if (!row || row.revoked_at || row.deleted_at) {
    return null;
  }
  if (row.expires_at <= deps.now().toISOString()) {
    return null;
  }
  return { accountId: row.account_id, email: row.email };
}

export async function startEmailVerification(
  deps: AccountDeps,
  body: unknown,
  ip: string,
): Promise<ServiceResult> {
  if (!deps.config.recoveryPepper) {
    return result(503, { error: 'not_configured' });
  }
  if (!deps.email.configured) {
    deps.logger.info('email_not_configured');
    return result(503, { error: 'email_not_configured' });
  }
  const email = emailFrom(body);
  if (!email) {
    return result(400, { error: 'invalid_request' });
  }
  const nowMs = deps.now().getTime();
  if (
    !allowRate(deps.db, `account-start:${ip}`, nowMs, 5) ||
    !allowRate(deps.db, `account-start-email:${hashSessionToken(email)}`, nowMs, 3)
  ) {
    deps.logger.info('rate_limited', { bucket: 'account_start' });
    return result(429, { error: 'rate_limited' });
  }
  const code = deps.emailCode?.() ?? generateEmailCode();
  const id = randomUUID();
  const createdAt = deps.now().toISOString();
  const expiresAt = new Date(deps.now().getTime() + codeTtlMs).toISOString();
  const codeHash = hashEmailCode(deps.config.recoveryPepper, email, code);
  deps.db.exec('BEGIN IMMEDIATE');
  try {
    deps.db
      .prepare(
        `UPDATE email_challenges
         SET consumed_at = ?
         WHERE email = ? AND consumed_at IS NULL`,
      )
      .run(createdAt, email);
    deps.db
      .prepare(
        `INSERT INTO email_challenges (
           id, email, code_hash, expires_at, consumed_at, attempts, created_at
         ) VALUES (?, ?, ?, ?, NULL, 0, ?)`,
      )
      .run(id, email, codeHash, expiresAt, createdAt);
    deps.db.exec('COMMIT');
  } catch (error) {
    deps.db.exec('ROLLBACK');
    throw error;
  }
  try {
    await deps.email.sendVerification({ to: email, code });
  } catch (error) {
    deps.db.prepare('DELETE FROM email_challenges WHERE id = ?').run(id);
    if (error instanceof EmailNotConfiguredError) {
      deps.logger.info('email_not_configured');
      return result(503, { error: 'email_not_configured' });
    }
    deps.logger.error('email_delivery_failed');
    if (error instanceof EmailDeliveryFailedError || error instanceof Error) {
      return result(503, { error: 'email_delivery_failed' });
    }
    return result(503, { error: 'email_delivery_failed' });
  }
  deps.logger.info('verification_pending');
  return result(200, { result: 'verification_pending' });
}

export function confirmEmailVerification(
  deps: AccountDeps,
  body: unknown,
  ip: string,
): ServiceResult {
  if (!deps.config.recoveryPepper) {
    return result(503, { error: 'not_configured' });
  }
  const email = emailFrom(body);
  const code = codeFrom(body);
  if (!email || !code) {
    return result(400, { error: 'invalid_request' });
  }
  if (!allowRate(deps.db, `account-confirm:${ip}`, deps.now().getTime(), 10)) {
    deps.logger.info('rate_limited', { bucket: 'account_confirm' });
    return result(429, { error: 'rate_limited' });
  }
  const now = deps.now().toISOString();
  const presented = hashEmailCode(deps.config.recoveryPepper, email, code);
  deps.db.exec('BEGIN IMMEDIATE');
  try {
    const challenge = deps.db
      .prepare(
        `SELECT id, code_hash, expires_at, attempts
         FROM email_challenges
         WHERE email = ? AND consumed_at IS NULL
         ORDER BY created_at DESC
         LIMIT 1`,
      )
      .get(email) as
      | { id: string; code_hash: string; expires_at: string; attempts: number }
      | undefined;
    if (!challenge || challenge.expires_at <= now || Number(challenge.attempts) >= maxAttempts) {
      if (challenge) {
        deps.db.prepare('UPDATE email_challenges SET consumed_at = ? WHERE id = ?').run(now, challenge.id);
      }
      deps.db.exec('COMMIT');
      deps.logger.info('verification_rejected');
      return result(401, { error: 'invalid_code' });
    }
    if (!recoveryCodesMatch(challenge.code_hash, presented)) {
      const attempts = Number(challenge.attempts) + 1;
      deps.db
        .prepare(
          `UPDATE email_challenges
           SET attempts = ?, consumed_at = CASE WHEN ? >= ? THEN ? ELSE consumed_at END
           WHERE id = ?`,
        )
        .run(attempts, attempts, maxAttempts, now, challenge.id);
      deps.db.exec('COMMIT');
      deps.logger.info('verification_rejected');
      return result(401, { error: 'invalid_code' });
    }
    deps.db.prepare('UPDATE email_challenges SET consumed_at = ? WHERE id = ?').run(now, challenge.id);
    const accountId = upsertAccount(deps, email, now);
    const token = deps.sessionToken?.() ?? generateSessionToken();
    const expiresAt = new Date(deps.now().getTime() + sessionTtlMs).toISOString();
    deps.db
      .prepare(
        `INSERT INTO account_sessions (token_hash, account_id, created_at, expires_at, revoked_at)
         VALUES (?, ?, ?, ?, NULL)`,
      )
      .run(hashSessionToken(token), accountId, now, expiresAt);
    deps.db.exec('COMMIT');
    deps.logger.info('verification_confirmed');
    return result(200, { result: 'signed_in', sessionToken: token, email });
  } catch (error) {
    deps.db.exec('ROLLBACK');
    throw error;
  }
}

export function deleteAccount(
  deps: AccountDeps,
  authorization: string | undefined,
  ip: string,
): ServiceResult {
  if (!deps.config.recoveryPepper) {
    return result(503, { error: 'not_configured' });
  }
  if (!allowRate(deps.db, `account-delete:${ip}`, deps.now().getTime(), 10)) {
    return result(429, { error: 'rate_limited' });
  }
  const session = readAccountSession(deps, authorization);
  if (!session) {
    return result(401, { error: 'unauthorized' });
  }
  const now = deps.now().toISOString();
  deps.db.exec('BEGIN IMMEDIATE');
  try {
    deps.db
      .prepare(
        `UPDATE account_sessions
         SET revoked_at = ?
         WHERE account_id = ? AND revoked_at IS NULL`,
      )
      .run(now, session.accountId);
    deps.db
      .prepare(
        `UPDATE purchases
         SET account_id = NULL, updated_at = ?
         WHERE account_id = ?`,
      )
      .run(now, session.accountId);
    deps.db
      .prepare('UPDATE accounts SET deleted_at = ? WHERE id = ? AND deleted_at IS NULL')
      .run(now, session.accountId);
    deps.db.exec('COMMIT');
  } catch (error) {
    deps.db.exec('ROLLBACK');
    throw error;
  }
  deps.logger.info('account_deleted');
  return result(200, { result: 'deleted' });
}

function upsertAccount(deps: AccountDeps, email: string, now: string): string {
  const existing = deps.db
    .prepare('SELECT id FROM accounts WHERE email = ? AND deleted_at IS NULL')
    .get(email) as { id: string } | undefined;
  if (existing) {
    return existing.id;
  }
  const id = randomUUID();
  deps.db
    .prepare('INSERT INTO accounts (id, email, created_at, deleted_at) VALUES (?, ?, ?, NULL)')
    .run(id, email, now);
  return id;
}

function emailFrom(body: unknown): string | null {
  if (!body || typeof body !== 'object' || !('email' in body)) {
    return null;
  }
  const value = (body as { email?: unknown }).email;
  if (typeof value !== 'string') {
    return null;
  }
  return normalizeEmail(value);
}

function codeFrom(body: unknown): string | null {
  if (!body || typeof body !== 'object' || !('code' in body)) {
    return null;
  }
  const value = (body as { code?: unknown }).code;
  if (typeof value !== 'string' || !/^\d{8}$/.test(value)) {
    return null;
  }
  return value;
}

function bearerToken(authorization: string | undefined): string | null {
  if (!authorization) {
    return null;
  }
  const match = /^Bearer\s+(\S+)$/i.exec(authorization.trim());
  const token = match?.[1];
  if (!token || token.length < 20 || token.length > 512) {
    return null;
  }
  return token;
}

function result(status: number, body: Record<string, unknown>): ServiceResult {
  return { status, body };
}
