/**
 * Sends a Local Pro verification code.
 *
 * The billing process ships with [UnconfiguredEmailDelivery]. A deployment
 * must inject an implementation that actually delivers mail. Nothing in this
 * module reports success unless `sendVerification` resolves.
 */
export interface VerificationEmail {
  to: string;
  code: string;
}

export interface EmailDelivery {
  /** False until a real provider is configured. Callers must not claim a send. */
  readonly configured: boolean;
  sendVerification(message: VerificationEmail): Promise<void>;
}

export class EmailNotConfiguredError extends Error {
  readonly code = 'email_not_configured';

  constructor() {
    super('email_not_configured');
    this.name = 'EmailNotConfiguredError';
  }
}

export class EmailDeliveryFailedError extends Error {
  readonly code = 'email_delivery_failed';

  constructor() {
    super('email_delivery_failed');
    this.name = 'EmailDeliveryFailedError';
  }
}

/** Default provider. It never accepts a message and never reports a delivery. */
export class UnconfiguredEmailDelivery implements EmailDelivery {
  readonly configured = false;

  sendVerification(_message: VerificationEmail): Promise<void> {
    return Promise.reject(new EmailNotConfiguredError());
  }
}
