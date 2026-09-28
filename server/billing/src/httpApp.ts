import { createServer, type IncomingMessage, type Server, type ServerResponse } from 'node:http';
import {
  confirmEmailVerification,
  deleteAccount,
  startEmailVerification,
} from './accountService.ts';
import {
  handleAppleNotification,
  handleGoogleNotification,
  revalidatePurchase,
  verifyPurchase,
  type BillingDeps,
} from './billingService.ts';
import type { ServiceResult } from './types.ts';

export function createBillingHttpServer(deps: BillingDeps): Server {
  return createServer((request, response) => {
    void dispatch(deps, request, response);
  });
}

async function dispatch(
  deps: BillingDeps,
  request: IncomingMessage,
  response: ServerResponse,
): Promise<void> {
  try {
    const path = new URL(request.url ?? '/', 'http://127.0.0.1').pathname;
    if (request.method === 'GET' && path === '/health') {
      send(response, 200, { ok: true });
      return;
    }
    if (request.method !== 'POST') {
      send(response, 404, { error: 'not_found' });
      return;
    }
    const limit = path.startsWith('/v1/notifications/')
      ? deps.config.notificationBodyLimit
      : deps.config.verifyBodyLimit;
    const body = await readBody(request, limit);
    if (!body.ok) {
      send(response, 413, { error: 'body_too_large' });
      return;
    }
    let json: unknown = {};
    if (body.text.length > 0) {
      try {
        json = JSON.parse(body.text) as unknown;
      } catch {
        send(response, 400, { error: 'invalid_request' });
        return;
      }
    }
    const ip = request.socket.remoteAddress ?? 'unknown';
    const authorization = request.headers.authorization;
    const result = await route(
      deps,
      path,
      request,
      json,
      ip,
      Array.isArray(authorization) ? authorization[0] : authorization,
    );
    send(response, result.status, result.body);
  } catch {
    deps.logger.error('request_failed');
    if (!response.headersSent) {
      send(response, 500, { error: 'internal' });
    }
  }
}

async function route(
  deps: BillingDeps,
  path: string,
  request: IncomingMessage,
  json: unknown,
  ip: string,
  authorization: string | undefined,
): Promise<ServiceResult> {
  if (path === '/v1/accounts/verification/start') {
    return startEmailVerification(deps, json, ip);
  }
  if (path === '/v1/accounts/verification/confirm') {
    return confirmEmailVerification(deps, json, ip);
  }
  if (path === '/v1/accounts/delete') {
    return deleteAccount(deps, authorization, ip);
  }
  if (path === '/v1/purchases/verify') {
    return verifyPurchase(deps, json, { restore: false, ip, authorization });
  }
  if (path === '/v1/purchases/restore') {
    return verifyPurchase(deps, json, { restore: true, ip, authorization });
  }
  if (path === '/v1/entitlements/revalidate') {
    return revalidatePurchase(deps, json, ip);
  }
  if (path === '/v1/notifications/google') {
    const authorization = request.headers.authorization;
    return handleGoogleNotification(
      deps,
      Array.isArray(authorization) ? authorization[0] : authorization,
      json,
    );
  }
  if (path === '/v1/notifications/apple') {
    return handleAppleNotification(deps, json);
  }
  return { status: 404, body: { error: 'not_found' } };
}

function readBody(
  request: IncomingMessage,
  limit: number,
): Promise<{ ok: true; text: string } | { ok: false }> {
  return new Promise((resolve, reject) => {
    const chunks: Buffer[] = [];
    let size = 0;
    let tooBig = false;
    request.on('data', (chunk: Buffer | string) => {
      const buffer = typeof chunk === 'string' ? Buffer.from(chunk) : chunk;
      size += buffer.length;
      if (size > limit) {
        tooBig = true;
        return;
      }
      chunks.push(buffer);
    });
    request.on('end', () => {
      if (tooBig) {
        resolve({ ok: false });
        return;
      }
      resolve({ ok: true, text: Buffer.concat(chunks).toString('utf8') });
    });
    request.on('error', (error) => {
      reject(error);
    });
  });
}

function send(response: ServerResponse, status: number, body: Record<string, unknown>): void {
  const encoded = Buffer.from(JSON.stringify(body));
  response.writeHead(status, {
    'content-type': 'application/json; charset=utf-8',
    'content-length': String(encoded.length),
  });
  response.end(encoded);
}
