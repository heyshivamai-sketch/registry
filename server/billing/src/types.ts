export type StorePlatform = 'google' | 'apple';
export type StoreEnvironment = 'sandbox' | 'production';
export type PurchaseRowStatus = 'active' | 'pending' | 'revoked' | 'cancelled';

export interface GoogleProductPurchase {
  purchaseState?: number;
  consumptionState?: number;
  acknowledgementState?: number;
  purchaseType?: number;
  orderId?: string;
  productId?: string;
  quantity?: number;
  refundableQuantity?: number;
  obfuscatedExternalAccountId?: string;
}

export interface AppleTransaction {
  productId?: string;
  bundleId?: string;
  environment?: string;
  type?: string;
  revocationDate?: number | null;
  appAccountToken?: string;
  originalTransactionId?: string;
  transactionId?: string;
  inAppOwnershipType?: string;
}

export interface GooglePlayClient {
  getProductPurchase(args: {
    packageName: string;
    productId: string;
    token: string;
  }): Promise<GoogleProductPurchase>;
  acknowledgeProduct(args: {
    packageName: string;
    productId: string;
    token: string;
  }): Promise<void>;
}

export interface AppleNotification {
  notificationUUID: string;
  notificationType: string;
  signedDate?: number;
  bundleId?: string;
  environment?: string;
  transaction: AppleTransaction | null;
  /** Inner transaction JWS. Not the outer notification payload. */
  signedTransaction?: string | null;
}

export interface AppleVerifier {
  verifyTransaction(signedTransaction: string): Promise<AppleTransaction>;
  verifyNotification(signedPayload: string): Promise<AppleNotification>;
}

export interface GooglePushAuth {
  verifyAuthorization(authorizationHeader: string | undefined): Promise<boolean>;
}

export class TransientStoreError extends Error {
  readonly code = 'transient_store';

  constructor() {
    super('transient_store');
    this.name = 'TransientStoreError';
  }
}

export class WrongEnvironmentError extends Error {
  readonly code = 'wrong_environment';

  constructor() {
    super('wrong_environment');
    this.name = 'WrongEnvironmentError';
  }
}

export class NotConfiguredError extends Error {
  readonly code = 'not_configured';

  constructor() {
    super('not_configured');
    this.name = 'NotConfiguredError';
  }
}

export interface ServiceResult {
  status: number;
  body: Record<string, unknown>;
}
