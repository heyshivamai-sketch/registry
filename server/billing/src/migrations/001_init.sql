CREATE TABLE purchases (
  platform TEXT NOT NULL,
  environment TEXT NOT NULL,
  purchase_key TEXT NOT NULL,
  product_id TEXT NOT NULL,
  package_or_bundle TEXT NOT NULL,
  token_hash TEXT NOT NULL,
  token_ciphertext TEXT,
  installation_id TEXT NOT NULL,
  recovery_code_hash TEXT,
  status TEXT NOT NULL,
  store_state TEXT NOT NULL,
  acknowledged INTEGER NOT NULL DEFAULT 0,
  last_event_at TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  PRIMARY KEY (platform, environment, purchase_key)
);

CREATE TABLE notification_events (
  event_id TEXT PRIMARY KEY,
  platform TEXT NOT NULL,
  environment TEXT NOT NULL,
  purchase_key TEXT,
  event_type TEXT NOT NULL,
  event_time TEXT NOT NULL,
  applied INTEGER NOT NULL,
  created_at TEXT NOT NULL
);

CREATE TABLE rate_buckets (
  bucket TEXT PRIMARY KEY,
  window_start INTEGER NOT NULL,
  count INTEGER NOT NULL
);
