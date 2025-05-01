/* =========================================================
   0 ‣ Discrete set of multiplicities
   ========================================================= */
CREATE TYPE cardinality AS ENUM ('one', 'many');

/* =========================================================
   1 ‣ Primitive value buckets
   ========================================================= */
CREATE TYPE primitives AS ENUM (
  'smallint','integer','bigint',
  'real','double precision','numeric',
  'text','varchar','char','bytea',
  'boolean','uuid',
  'json','jsonb',
  'date','time',
  'timestamp','timestamptz','interval'
);

/* =========================================================
   2 ‣ Attribute catalog  (rows ≈ schema)
   ========================================================= */
CREATE TABLE attrs (
  id          uuid         PRIMARY KEY DEFAULT gen_random_uuid(),
  ident       text UNIQUE  NOT NULL,          -- e.g. :block/tags
  value_type  primitives   NOT NULL,          -- storage bucket
  cardinality cardinality  NOT NULL           -- ENUM: 'one' | 'many'
);

/* =========================================================
   3 ‣ Transaction header
   ========================================================= */
CREATE TABLE txs (
  id   uuid         PRIMARY KEY DEFAULT gen_random_uuid(),
  ts   timestamptz  NOT NULL DEFAULT now(),
  meta jsonb        NOT NULL DEFAULT '{}'    -- arbitrary JSON
);

/* =========================================================
   4 ‣ Immutable datom log
   ========================================================= */
CREATE TABLE datoms (
  tx     uuid        NOT NULL REFERENCES txs(id),   -- tx id
  e      uuid        NOT NULL,                      -- entity
  a      uuid        NOT NULL REFERENCES attrs(id), -- attribute
  v      jsonb       NOT NULL,                      -- value
  added  boolean     NOT NULL,                      -- true=assert / false=retract
  agent  uuid        NOT NULL,                      -- actor
  ts     timestamptz NOT NULL DEFAULT now(),        -- wall-clock
  CONSTRAINT datom_pk PRIMARY KEY (e, a, v, tx)     -- append-only
);

/* =========================================================
   5 ‣ Datomic-style covering indexes
   ========================================================= */
CREATE INDEX datoms_eavt ON datoms (e, a, v, tx);   -- EAVT
CREATE INDEX datoms_aevt ON datoms (a, e, v, tx);   -- AEVT
CREATE INDEX datoms_avet ON datoms (a, v, e, tx);   -- AVET
CREATE INDEX datoms_vaet ON datoms (v, a, e, tx);   -- VAET




-- =========================================================
-- 5 Bootstrap a few core attributes (optional starter kit)
INSERT INTO attrs (ident, value_type, cardinality) VALUES
  ('block/type',       'uuid', '1'),
  ('block/tags',       'uuid', 'n'),
  ('hyperdoc/blocks',  'uuid', 'n'),
  ('tag/label',        'text', '1'),
  ('space/hyperdocs',  'uuid', 'n');

-- =========================================================
-- 6 Sample write: create a tag entity labeled “urgent”
WITH new_tx AS (
  INSERT INTO txs (meta) VALUES ('{"actor":"alice"}') RETURNING id
), tag_entity AS (
  SELECT gen_random_uuid() AS eid, new_tx.id AS txid FROM new_tx
)
INSERT INTO datoms (e, a, v, added, actor, tx)
SELECT
  tag_entity.eid,
  attrs.id,
  to_jsonb('urgent'::text),
  true,
  'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::uuid,  -- alice’s UUID
  tag_entity.txid
FROM tag_entity
JOIN attrs ON attrs.ident = 'tag/label';

-- =========================================================
-- 7 Query pattern examples
-- 7a: all tags on entity :e
--   SELECT v->>0 AS tag
--   FROM datoms d JOIN attrs a ON a.id = d.a
--   WHERE d.e = :e AND a.ident = 'block/tags' AND d.added;

-- 7b: reconstruct entity state as of tx :t
--   SELECT a.ident, d.v
--   FROM datoms d JOIN attrs a ON a.id = d.a
--   WHERE d.e = :e AND d.tx <= :t
--   ORDER BY d.tx;
