import { sha256Hex } from './cryptoBox.ts';
import type {
  AppleTransaction,
  GoogleProductPurchase,
  StoreEnvironment,
} from './types.ts';

export interface StoreFacts {
  environment: StoreEnvironment;
  purchaseKey: string;
  outcome: 'grant' | 'pending' | 'revoke' | 'reject';
  error?: string;
  storeState: string;
  needsAcknowledge: boolean;
  accountMatches: boolean;
}

export function googleEnvironment(
  purchaseType: number | undefined,
): StoreEnvironment {
  return purchaseType === 0 ? 'sandbox' : 'production';
}

export function appleEnvironment(value: string | undefined): StoreEnvironment | null {
  if (value === 'Sandbox') {
    return 'sandbox';
  }
  if (value === 'Production') {
    return 'production';
  }
  return null;
}

export function decideGoogle(input: {
  expectedProduct: string;
  requestedEnvironment: StoreEnvironment;
  installationId: string;
  token: string;
  purchase: GoogleProductPurchase;
}): StoreFacts {
  const tokenHash = sha256Hex(input.token);
  const purchaseKey = input.purchase.orderId?.trim() || `token:${tokenHash}`;
  const environment = googleEnvironment(input.purchase.purchaseType);
  const account = input.purchase.obfuscatedExternalAccountId ?? '';
  const accountMatches = account.length > 0 && account === input.installationId;
  if (input.purchase.productId && input.purchase.productId !== input.expectedProduct) {
    return reject(environment, purchaseKey, 'wrong_product', accountMatches);
  }
  if (input.purchase.purchaseType === 2) {
    return reject(environment, purchaseKey, 'invalid_purchase', accountMatches);
  }
  if (environment !== input.requestedEnvironment) {
    return reject(environment, purchaseKey, 'wrong_environment', accountMatches);
  }
  if (input.purchase.consumptionState === 1) {
    return reject(environment, purchaseKey, 'consumed', accountMatches);
  }
  const base = {
    environment,
    purchaseKey,
    needsAcknowledge: input.purchase.acknowledgementState !== 1,
    accountMatches,
  };
  if (input.purchase.purchaseState === 2) {
    return { ...base, outcome: 'pending', storeState: 'pending' };
  }
  if (input.purchase.purchaseState === 1) {
    return { ...base, outcome: 'revoke', storeState: 'canceled', needsAcknowledge: false };
  }
  if (input.purchase.purchaseState !== 0) {
    return reject(environment, purchaseKey, 'invalid_purchase', accountMatches);
  }
  if (input.purchase.refundableQuantity === 0) {
    return { ...base, outcome: 'revoke', storeState: 'refunded', needsAcknowledge: false };
  }
  return { ...base, outcome: 'grant', storeState: 'purchased' };
}

export function decideApple(input: {
  expectedBundle: string;
  expectedProduct: string;
  requestedEnvironment: StoreEnvironment;
  installationId: string;
  transaction: AppleTransaction;
}): StoreFacts {
  const environment = appleEnvironment(input.transaction.environment) ?? input.requestedEnvironment;
  const purchaseKey =
    input.transaction.originalTransactionId?.trim() ||
    input.transaction.transactionId?.trim() ||
    '';
  const account = (input.transaction.appAccountToken ?? '').toLowerCase();
  const accountMatches =
    account.length > 0 && account === input.installationId.toLowerCase();
  if (!purchaseKey) {
    return reject(environment, 'missing', 'invalid_purchase', false);
  }
  if (input.transaction.bundleId !== input.expectedBundle) {
    return reject(environment, purchaseKey, 'wrong_application', accountMatches);
  }
  if (input.transaction.productId !== input.expectedProduct) {
    return reject(environment, purchaseKey, 'wrong_product', accountMatches);
  }
  if (appleEnvironment(input.transaction.environment) !== input.requestedEnvironment) {
    return reject(environment, purchaseKey, 'wrong_environment', accountMatches);
  }
  if (input.transaction.type !== 'Non-Consumable') {
    return reject(environment, purchaseKey, 'wrong_product_type', accountMatches);
  }
  if (input.transaction.inAppOwnershipType !== 'PURCHASED') {
    return reject(environment, purchaseKey, 'wrong_ownership', accountMatches);
  }
  if (input.transaction.revocationDate != null) {
    return {
      environment,
      purchaseKey,
      outcome: 'revoke',
      storeState: 'revoked',
      needsAcknowledge: false,
      accountMatches,
    };
  }
  return {
    environment,
    purchaseKey,
    outcome: 'grant',
    storeState: 'purchased',
    needsAcknowledge: false,
    accountMatches,
  };
}

function reject(
  environment: StoreEnvironment,
  purchaseKey: string,
  error: string,
  accountMatches: boolean,
): StoreFacts {
  return {
    environment,
    purchaseKey,
    outcome: 'reject',
    error,
    storeState: error,
    needsAcknowledge: false,
    accountMatches,
  };
}
