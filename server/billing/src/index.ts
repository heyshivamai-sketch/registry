import { mkdirSync } from 'node:fs';
import { dirname } from 'node:path';
import { OAuth2Client } from 'google-auth-library';
import { createAppleVerifier, notConfiguredApple, routeAppleVerifiers } from './appleStore.ts';
import { loadConfig } from './config.ts';
import { openDatabase } from './db.ts';
import { createGooglePlayClient, notConfiguredGoogle } from './googlePlay.ts';
import { createBillingHttpServer } from './httpApp.ts';
import { createLogger } from './log.ts';
import type { GooglePushAuth } from './types.ts';

const config = loadConfig(process.env);
mkdirSync(dirname(config.databasePath), { recursive: true });
const db = openDatabase(config.databasePath);
const logger = createLogger();

const google = config.googleServiceAccountJson
  ? createGooglePlayClient(config.googleServiceAccountJson)
  : notConfiguredGoogle();

const appleRoot = config.appleRootCaDir;
const apple =
  appleRoot === null
    ? notConfiguredApple()
    : routeAppleVerifiers(
        createAppleVerifier({
          rootCaDir: appleRoot,
          bundleId: config.iosBundleId,
          environment: 'sandbox',
        }),
        config.appleAppAppleId === null
          ? null
          : createAppleVerifier({
              rootCaDir: appleRoot,
              bundleId: config.iosBundleId,
              environment: 'production',
              appAppleId: config.appleAppAppleId,
            }),
      );

const googlePushAuth: GooglePushAuth = {
  async verifyAuthorization(authorizationHeader) {
    if (!config.googlePubsubAudience || !config.googlePubsubEmail) {
      return false;
    }
    const token = authorizationHeader?.replace(/^Bearer\s+/i, '').trim();
    if (!token || token === authorizationHeader) {
      return false;
    }
    try {
      const client = new OAuth2Client();
      const ticket = await client.verifyIdToken({
        idToken: token,
        audience: config.googlePubsubAudience,
      });
      const payload = ticket.getPayload();
      return payload?.email_verified === true && payload.email === config.googlePubsubEmail;
    } catch {
      logger.error('google_push_auth_failed');
      return false;
    }
  },
};

const server = createBillingHttpServer({
  db,
  config,
  google,
  apple,
  googlePushAuth,
  logger,
  now: () => new Date(),
});

server.listen(config.port, () => {
  logger.info('billing_listening', { port: config.port });
});
