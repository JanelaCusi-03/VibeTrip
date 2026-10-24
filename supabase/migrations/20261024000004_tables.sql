-- ---------- users (perfil de aplicacion; la identidad vive en auth.users de Supabase)
CREATE TABLE users (
  id                       UUID PRIMARY KEY REFERENCES auth.users (id) ON DELETE CASCADE,
  display_name             TEXT           NOT NULL CHECK (char_length(display_name) BETWEEN 1 AND 60),
  default_budget_level     SMALLINT       NOT NULL DEFAULT 2 CHECK (default_budget_level BETWEEN 1 AND 4),
  default_companion        companion_type NOT NULL DEFAULT 'solo',
  search_radius_m          INTEGER        NOT NULL DEFAULT 3000 CHECK (search_radius_m BETWEEN 500 AND 50000),
  telemetry_consent        BOOLEAN        NOT NULL DEFAULT FALSE,
  onboarding_completed_at  TIMESTAMPTZ,
  created_at               TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
  updated_at               TIMESTAMPTZ    NOT NULL DEFAULT NOW()
);

-- ---------- categories (jerarquia de un nivel: tipo > subcategoria)
CREATE TABLE categories (
  id          SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  parent_id   SMALLINT REFERENCES categories (id) ON DELETE RESTRICT,
  slug        TEXT NOT NULL UNIQUE CHECK (slug ~ '^[a-z0-9_]+$'),
  name        TEXT NOT NULL,
  icon_key    TEXT NOT NULL,
  color_hex   CHAR(7) NOT NULL CHECK (color_hex ~ '^#[0-9A-Fa-f]{6}$')
);

-- ---------- tags (catalogo del espacio de caracteristicas, d = 48)
CREATE TABLE tags (
  id            SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  slug          TEXT      NOT NULL UNIQUE CHECK (slug ~ '^[a-z0-9_]+$'),
  display_name  TEXT      NOT NULL,
  group_name    tag_group NOT NULL,
  vector_index  SMALLINT  NOT NULL UNIQUE CHECK (vector_index BETWEEN 0 AND 47)
);

-- ---------- places
CREATE TABLE places (
  id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category_id        SMALLINT         NOT NULL REFERENCES categories (id),
  name               TEXT             NOT NULL CHECK (char_length(name) BETWEEN 1 AND 120),
  description        TEXT             NOT NULL DEFAULT '',
  address            TEXT,
  latitude           DOUBLE PRECISION NOT NULL CHECK (latitude  BETWEEN -90  AND 90),
  longitude          DOUBLE PRECISION NOT NULL CHECK (longitude BETWEEN -180 AND 180),
  location           GEOGRAPHY(Point, 4326) GENERATED ALWAYS AS
                       (ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography) STORED,
  price_level        SMALLINT         NOT NULL CHECK (price_level BETWEEN 1 AND 4),
  estimated_cost     NUMERIC(8,2)     CHECK (estimated_cost >= 0),
  is_outdoor         BOOLEAN          NOT NULL DEFAULT FALSE,
  best_time_buckets  time_bucket[]    NOT NULL DEFAULT '{}',
  companion_fit      companion_type[] NOT NULL DEFAULT '{}',
  opening_hours      JSONB            NOT NULL DEFAULT '{}'::jsonb,
  rating_average     NUMERIC(2,1)     CHECK (rating_average BETWEEN 0 AND 5),
  rating_count       INTEGER          NOT NULL DEFAULT 0 CHECK (rating_count >= 0),
  image_urls         TEXT[]           NOT NULL DEFAULT '{}',
  tag_weights        JSONB            NOT NULL DEFAULT '{}'::jsonb,   -- derivado de place_tags
  embedding          VECTOR(48),                                      -- derivado de place_tags
  is_active          BOOLEAN          NOT NULL DEFAULT TRUE,
  created_at         TIMESTAMPTZ      NOT NULL DEFAULT NOW(),
  updated_at         TIMESTAMPTZ      NOT NULL DEFAULT NOW()
);

-- ---------- place_tags (fuente de verdad de los pesos de cada lugar)
CREATE TABLE place_tags (
  place_id  UUID         NOT NULL REFERENCES places (id) ON DELETE CASCADE,
  tag_id    SMALLINT     NOT NULL REFERENCES tags (id)   ON DELETE RESTRICT,
  weight    NUMERIC(4,3) NOT NULL CHECK (weight BETWEEN 0 AND 1),
  PRIMARY KEY (place_id, tag_id)
);

-- ---------- user_preference_vectors (relacion 1:1 con users)
CREATE TABLE user_preference_vectors (
  user_id               UUID PRIMARY KEY REFERENCES users (id) ON DELETE CASCADE,
  explicit_vector       VECTOR(48)  NOT NULL,                       -- semilla del onboarding
  current_vector        VECTOR(48)  NOT NULL,                       -- vector efectivo del motor
  tag_weights           JSONB       NOT NULL DEFAULT '{}'::jsonb,   -- vista legible de current_vector
  selected_vibes        TEXT[]      NOT NULL DEFAULT '{}',
  interaction_count     INTEGER     NOT NULL DEFAULT 0 CHECK (interaction_count >= 0),
  version               INTEGER     NOT NULL DEFAULT 1 CHECK (version >= 1),  -- concurrencia optimista
  last_decay_applied_at TIMESTAMPTZ,
  created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ---------- user_interactions_log (registro de eventos; solo se agregan filas)
CREATE TABLE user_interactions_log (
  id                    BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  event_id              UUID NOT NULL UNIQUE,                 -- clave de idempotencia (cliente)
  user_id               UUID NOT NULL REFERENCES users (id)  ON DELETE CASCADE,
  place_id              UUID NOT NULL REFERENCES places (id) ON DELETE CASCADE,
  session_id            UUID NOT NULL,
  channel               capture_channel  NOT NULL,
  interaction_type      interaction_type NOT NULL,
  dwell_ms              INTEGER CHECK (dwell_ms >= 0),
  signal_weight         REAL NOT NULL CHECK (signal_weight BETWEEN -1.0 AND 1.0),
  match_score_at_time   REAL CHECK (match_score_at_time BETWEEN 0 AND 100),
  context_snapshot      JSONB NOT NULL DEFAULT '{}'::jsonb,   -- lat, lon, time_bucket, weather, budget, companion
  occurred_at           TIMESTAMPTZ NOT NULL,
  received_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT dwell_requires_duration
    CHECK (interaction_type <> 'dwell' OR dwell_ms IS NOT NULL)
);

-- ---------- user_favorites (RF-11)
CREATE TABLE user_favorites (
  user_id     UUID NOT NULL REFERENCES users (id)  ON DELETE CASCADE,
  place_id    UUID NOT NULL REFERENCES places (id) ON DELETE CASCADE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_id, place_id)
);
