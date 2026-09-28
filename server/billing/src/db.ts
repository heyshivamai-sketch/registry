import { readdirSync, readFileSync } from 'node:fs';
import { DatabaseSync } from 'node:sqlite';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

export function openDatabase(path: string): DatabaseSync {
  const database = new DatabaseSync(path);
  database.exec('PRAGMA foreign_keys = ON');
  migrate(database);
  return database;
}

export function migrate(database: DatabaseSync): void {
  database.exec(`CREATE TABLE IF NOT EXISTS schema_migrations (
    id TEXT PRIMARY KEY,
    applied_at TEXT NOT NULL
  )`);
  const migrationsDir = join(dirname(fileURLToPath(import.meta.url)), 'migrations');
  const files = readdirSync(migrationsDir)
    .filter((name) => name.endsWith('.sql'))
    .sort();
  const existing = database.prepare('SELECT id FROM schema_migrations');
  const applied = new Set(
    existing.all().map((row) => String((row as { id: string }).id)),
  );
  for (const file of files) {
    const id = file.replace(/\.sql$/, '');
    if (applied.has(id)) {
      continue;
    }
    database.exec('BEGIN');
    try {
      database.exec(readFileSync(join(migrationsDir, file), 'utf8'));
      database
        .prepare('INSERT INTO schema_migrations (id, applied_at) VALUES (?, ?)')
        .run(id, new Date().toISOString());
      database.exec('COMMIT');
    } catch (error) {
      database.exec('ROLLBACK');
      throw error;
    }
  }
}

export interface PurchaseRow {
  platform: string;
  environment: string;
  purchase_key: string;
  product_id: string;
  package_or_bundle: string;
  token_hash: string;
  token_ciphertext: string | null;
  installation_id: string;
  recovery_code_hash: string | null;
  account_id: string | null;
  status: string;
  store_state: string;
  acknowledged: number;
  last_event_at: string | null;
  created_at: string;
  updated_at: string;
}

export function findPurchase(
  database: DatabaseSync,
  platform: string,
  environment: string,
  purchaseKey: string,
): PurchaseRow | undefined {
  return database
    .prepare(
      `SELECT * FROM purchases
       WHERE platform = ? AND environment = ? AND purchase_key = ?`,
    )
    .get(platform, environment, purchaseKey) as PurchaseRow | undefined;
}

export function allowRate(
  database: DatabaseSync,
  bucket: string,
  nowMs: number,
  limit: number,
  windowMs = 60_000,
): boolean {
  const row = database
    .prepare('SELECT window_start, count FROM rate_buckets WHERE bucket = ?')
    .get(bucket) as { window_start: number; count: number } | undefined;
  if (!row || nowMs - Number(row.window_start) >= windowMs) {
    database
      .prepare(
        `INSERT INTO rate_buckets (bucket, window_start, count)
         VALUES (?, ?, 1)
         ON CONFLICT(bucket) DO UPDATE SET window_start = excluded.window_start, count = 1`,
      )
      .run(bucket, nowMs);
    return true;
  }
  if (Number(row.count) >= limit) {
    return false;
  }
  database
    .prepare('UPDATE rate_buckets SET count = count + 1 WHERE bucket = ?')
    .run(bucket);
  return true;
}
