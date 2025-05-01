-- enable uuid generator
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ───────────────────────────── 0. ENUMS ─────────────────────────────
CREATE TYPE cardinality AS ENUM ('one','many');

CREATE TYPE primitives AS ENUM (
  'smallint','integer','bigint',
  'real','double precision','numeric',
  'text','varchar','char','bytea',
  'boolean','uuid',
  'json','jsonb',
  'date','time',
  'timestamp','timestamptz','interval'
);

-- ─────────────────────── 1. ATTRIBUTE CATALOG ───────────────────────
CREATE TABLE attrs (
  id          uuid         PRIMARY KEY DEFAULT gen_random_uuid(),
  ident       text UNIQUE  NOT NULL,
  value_type  primitives   NOT NULL,
  cardinality cardinality  NOT NULL
);

-- ─────────────────────── 2. TRANSACTION HEADER ──────────────────────
CREATE TABLE txs (
  id     uuid         PRIMARY KEY DEFAULT gen_random_uuid(),
  t      bigserial    UNIQUE,                 -- dense, monotonic
  ts     timestamptz  NOT NULL DEFAULT now(), -- wall-clock
  agent  uuid         NOT NULL,               -- actor / service
  meta   jsonb        NOT NULL DEFAULT '{}'   -- arbitrary metadata
);

-- ───────────────────────── 3. DATOM LEDGER ──────────────────────────
CREATE TABLE datoms (
  tx    uuid        NOT NULL REFERENCES txs(id),
  e     uuid        NOT NULL,
  a     uuid        NOT NULL REFERENCES attrs(id),
  v     jsonb       NOT NULL,
  added boolean     NOT NULL,                 -- true = assert, false = retract
  PRIMARY KEY (e,a,v,tx)
);

-- ──────────────────────── 4. COVERING INDEXES ───────────────────────
CREATE INDEX datoms_eavt ON datoms (e,a,v,tx);
CREATE INDEX datoms_aevt ON datoms (a,e,v,tx);
CREATE INDEX datoms_avet ON datoms (a,v,e,tx);
CREATE INDEX datoms_vaet ON datoms (v,a,e,tx);

-- ─────────────── 5. CARDINALITY-ONE UNIQUENESS RULE ────────────────
CREATE UNIQUE INDEX only_one_live
  ON datoms (e,a)
  WHERE added
    AND a IN (SELECT id FROM attrs WHERE cardinality='one');

-- ───────────────── 6. VALIDATE LEGIT RETRACTIONS ────────────────────
CREATE OR REPLACE FUNCTION chk_retract() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.added = false AND
     NOT EXISTS (
       SELECT 1 FROM datoms
       WHERE e = NEW.e AND a = NEW.a AND v = NEW.v AND added = true
     )
  THEN
    RAISE EXCEPTION 'Cannot retract nonexistent assertion';
  END IF;
  RETURN NEW;
END $$;

CREATE CONSTRAINT TRIGGER ensure_retract
  AFTER INSERT ON datoms DEFERRABLE INITIALLY DEFERRED
  FOR EACH ROW EXECUTE FUNCTION chk_retract();

-- ─────────────── 7. MATERIALIZED VIEW OF “CURRENT” STATE ────────────
CREATE MATERIALIZED VIEW live AS
SELECT DISTINCT ON (e,a) e,a,v
FROM datoms
WHERE added
ORDER BY e,a,tx DESC;
