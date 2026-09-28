import { GoogleAuth } from 'google-auth-library';
import { NotConfiguredError, TransientStoreError, type GooglePlayClient, type GoogleProductPurchase } from './types.ts';

const publisherScope = 'https://www.googleapis.com/auth/androidpublisher';

export function googleProductGetUrl(
  packageName: string,
  productId: string,
  token: string,
): string {
  return `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${encodeURIComponent(packageName)}/purchases/products/${encodeURIComponent(productId)}/tokens/${encodeURIComponent(token)}`;
}

export function googleAcknowledgeUrl(
  packageName: string,
  productId: string,
  token: string,
): string {
  return `${googleProductGetUrl(packageName, productId, token)}:acknowledge`;
}

export function createGooglePlayClient(serviceAccountJson: string): GooglePlayClient {
  const credentials = JSON.parse(serviceAccountJson) as Record<string, unknown>;
  const auth = new GoogleAuth({
    credentials,
    scopes: [publisherScope],
  });
  return {
    async getProductPurchase({ packageName, productId, token }) {
      const client = await auth.getClient();
      try {
        const response = await client.request<GoogleProductPurchase>({
          url: googleProductGetUrl(packageName, productId, token),
          method: 'GET',
        });
        return response.data ?? {};
      } catch (error) {
        throw mapGoogleFailure(error);
      }
    },
    async acknowledgeProduct({ packageName, productId, token }) {
      const client = await auth.getClient();
      try {
        await client.request({
          url: googleAcknowledgeUrl(packageName, productId, token),
          method: 'POST',
          data: {},
        });
      } catch (error) {
        throw mapGoogleFailure(error);
      }
    },
  };
}

export function notConfiguredGoogle(): GooglePlayClient {
  return {
    async getProductPurchase() {
      throw new NotConfiguredError();
    },
    async acknowledgeProduct() {
      throw new NotConfiguredError();
    },
  };
}

function mapGoogleFailure(error: unknown): Error {
  const status = readStatus(error);
  if (status === undefined || status === 429 || status >= 500) {
    return new TransientStoreError();
  }
  return new Error('google_rejected');
}

function readStatus(error: unknown): number | undefined {
  if (!error || typeof error !== 'object' || !('response' in error)) {
    return undefined;
  }
  const response = (error as { response?: { status?: number } }).response;
  return typeof response?.status === 'number' ? response.status : undefined;
}
