const secretKey =
  /purchaseToken|purchasetoken|token|signedTransaction|signedPayload|signedtransaction|recoveryCode|recoverycode|authorization|private|receipt|jws|serviceAccount|password|ciphertext/i;

export function redact(value: unknown): unknown {
  if (Array.isArray(value)) {
    return value.map((item) => redact(item));
  }
  if (value !== null && typeof value === 'object') {
    const redacted: Record<string, unknown> = {};
    for (const [key, nested] of Object.entries(value)) {
      redacted[key] = secretKey.test(key) ? '[redacted]' : redact(nested);
    }
    return redacted;
  }
  return value;
}

export interface Logger {
  info(event: string, fields?: Record<string, unknown>): void;
  error(event: string, fields?: Record<string, unknown>): void;
}

export function createLogger(
  write: (line: string) => void = (line) => {
    process.stdout.write(`${line}\n`);
  },
): Logger {
  const emit = (level: string, event: string, fields?: Record<string, unknown>) => {
    const payload = redact({ level, event, ...(fields ?? {}) });
    write(JSON.stringify(payload));
  };
  return {
    info(event, fields) {
      emit('info', event, fields);
    },
    error(event, fields) {
      emit('error', event, fields);
    },
  };
}
