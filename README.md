-- 1) Define the enum of native types
CREATE TYPE primitives AS ENUM (
  'smallint',         -- 2-byte int
  'integer',          -- 4-byte int
  'bigint',           -- 8-byte int
  'real',             -- 4-byte float
  'double precision', -- 8-byte float
  'numeric',          -- arbitrary precision
  'text',             -- variable-length string
  'varchar',          -- variable-length string
  'char',             -- fixed-length string
  'bytea',            -- binary
  'boolean',          -- true/false
  'uuid',             -- UUID
  'json',             -- JSON
  'jsonb',            -- binary JSON
  'date',             -- calendar date
  'time',             -- time of day
  'timestamp',        -- without time zone
  'timestamptz',      -- with time zone
  'interval'          -- span of time
);

-- 2) Create value_types with UUID PK, and name as UNIQUE
CREATE TABLE value_types (
  id        UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  name      TEXT        NOT NULL UNIQUE,
  primitive primitives  NOT NULL
);

-- 3) Add "Cardinality" as a boolean type entry
INSERT INTO value_types (name, primitive)
VALUES ('Cardinality', 'boolean');

-- 4) Create tag_types with UUID PK, and name as UNIQUE
CREATE TABLE tag_types (
  id             UUID     PRIMARY KEY DEFAULT gen_random_uuid(),
  name           TEXT     NOT NULL UNIQUE,
  value_type_id  UUID     NOT NULL REFERENCES value_types(id),
  cardinality    BOOLEAN  NOT NULL DEFAULT false  -- false = one, true = many
);

-- 5) Create block_types with array of tag_type UUIDs
CREATE TABLE block_types (
  id   UUID     PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT     NOT NULL UNIQUE,
  tags UUID[]   NOT NULL DEFAULT '{}'  -- array of tag_types.id
);

-- 6) Create hyperdoc_types with arrays of block_type and tag_type UUIDs
CREATE TABLE hyperdoc_types (
  id     UUID     PRIMARY KEY DEFAULT gen_random_uuid(),
  name   TEXT     NOT NULL UNIQUE,
  blocks UUID[]   NOT NULL DEFAULT '{}',  -- array of block_types.id
  tags   UUID[]   NOT NULL DEFAULT '{}'   -- array of tag_types.id
);

-- 7) Create blueprints, grouping hyperdoc, block, and tag types
CREATE TABLE blueprints (
  id        UUID     PRIMARY KEY DEFAULT gen_random_uuid(),
  name      TEXT     NOT NULL UNIQUE,
  hyperdocs UUID[]   NOT NULL DEFAULT '{}',  -- array of hyperdoc_types.id
  blocks    UUID[]   NOT NULL DEFAULT '{}',  -- array of block_types.id
  tags      UUID[]   NOT NULL DEFAULT '{}'   -- array of tag_types.id
);


