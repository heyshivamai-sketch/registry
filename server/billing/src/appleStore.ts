import { readdirSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import {
  Environment,
  SignedDataVerifier,
  VerificationException,
  VerificationStatus,
  type JWSTransactionDecodedPayload,
} from '@apple/app-store-server-library';
import {
  NotConfiguredError,
  TransientStoreError,
  WrongEnvironmentError,
  type AppleNotification,
  type AppleTransaction,
  type AppleVerifier,
} from './types.ts';

export function createAppleVerifier(options: {
  rootCaDir: string;
  bundleId: string;
  environment: 'sandbox' | 'production';
  appAppleId?: number;
}): AppleVerifier {
  const certificates = readdirSync(options.rootCaDir)
    .filter((name) => name.endsWith('.cer') || name.endsWith('.der') || name.endsWith('.pem'))
    .map((name) => readFileSync(join(options.rootCaDir, name)));
  const environment =
    options.environment === 'sandbox' ? Environment.SANDBOX : Environment.PRODUCTION;
  const verifier = new SignedDataVerifier(
    certificates,
    true,
    environment,
    options.bundleId,
    options.environment === 'production' ? options.appAppleId : undefined,
  );
  return verifierAdapter(verifier);
}

export function verifierAdapter(verifier: {
  verifyAndDecodeTransaction(signedTransaction: string): Promise<JWSTransactionDecodedPayload>;
  verifyAndDecodeNotification(signedPayload: string): Promise<{
    notificationUUID?: string;
    notificationType?: string;
    signedDate?: number;
    data?: { bundleId?: string; signedTransactionInfo?: string; environment?: string };
  }>;
}): AppleVerifier {
  return {
    async verifyTransaction(signedTransaction) {
      try {
        return mapTransaction(await verifier.verifyAndDecodeTransaction(signedTransaction));
      } catch (error) {
        throw translateAppleError(error);
      }
    },
    async verifyNotification(signedPayload) {
      let decoded: Awaited<ReturnType<typeof verifier.verifyAndDecodeNotification>>;
      try {
        decoded = await verifier.verifyAndDecodeNotification(signedPayload);
      } catch (error) {
        throw translateAppleError(error);
      }
      const signedTransaction = decoded.data?.signedTransactionInfo;
      let transaction = null;
      if (signedTransaction) {
        try {
          transaction = mapTransaction(await verifier.verifyAndDecodeTransaction(signedTransaction));
        } catch (error) {
          throw translateAppleError(error);
        }
      }
      const note: AppleNotification = {
        notificationUUID: decoded.notificationUUID ?? '',
        notificationType: String(decoded.notificationType ?? ''),
        signedDate: decoded.signedDate,
        bundleId: decoded.data?.bundleId ?? transaction?.bundleId,
        environment: transaction?.environment ?? decoded.data?.environment,
        transaction,
        signedTransaction: signedTransaction ?? null,
      };
      return note;
    },
  };
}

export function routeAppleVerifiers(
  sandbox: AppleVerifier | null,
  production: AppleVerifier | null,
): AppleVerifier {
  const verifiers = [sandbox, production].filter((item): item is AppleVerifier => item !== null);
  if (verifiers.length === 0) {
    return notConfiguredApple();
  }
  return {
    async verifyTransaction(signedTransaction) {
      return firstMatch(verifiers, (verifier) => verifier.verifyTransaction(signedTransaction));
    },
    async verifyNotification(signedPayload) {
      return firstMatch(verifiers, (verifier) => verifier.verifyNotification(signedPayload));
    },
  };
}

async function firstMatch<T>(
  verifiers: AppleVerifier[],
  call: (verifier: AppleVerifier) => Promise<T>,
): Promise<T> {
  let wrongEnvironment: WrongEnvironmentError | null = null;
  for (const verifier of verifiers) {
    try {
      return await call(verifier);
    } catch (error) {
      if (error instanceof WrongEnvironmentError) {
        wrongEnvironment = error;
        continue;
      }
      throw error;
    }
  }
  throw wrongEnvironment ?? new NotConfiguredError();
}

export function notConfiguredApple(): AppleVerifier {
  return {
    async verifyTransaction() {
      throw new NotConfiguredError();
    },
    async verifyNotification() {
      throw new NotConfiguredError();
    },
  };
}

function translateAppleError(error: unknown): Error {
  if (error instanceof VerificationException) {
    if (error.status === VerificationStatus.INVALID_ENVIRONMENT) {
      return new WrongEnvironmentError();
    }
    if (error.status === VerificationStatus.RETRYABLE_VERIFICATION_FAILURE) {
      return new TransientStoreError();
    }
  }
  return error instanceof Error ? error : new Error('invalid_purchase');
}

export function mapTransaction(payload: JWSTransactionDecodedPayload): AppleTransaction {
  return {
    productId: payload.productId,
    bundleId: payload.bundleId,
    environment: payload.environment === undefined ? undefined : String(payload.environment),
    type: payload.type === undefined ? undefined : String(payload.type),
    revocationDate: payload.revocationDate,
    appAccountToken: payload.appAccountToken,
    originalTransactionId: payload.originalTransactionId,
    transactionId: payload.transactionId,
    inAppOwnershipType:
      payload.inAppOwnershipType === undefined
        ? undefined
        : String(payload.inAppOwnershipType),
  };
}
