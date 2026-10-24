CREATE INDEX idx_places_location_gist   ON places USING GIST (location);
CREATE INDEX idx_places_category        ON places (category_id) WHERE is_active;
CREATE INDEX idx_places_price_level     ON places (price_level) WHERE is_active;
CREATE INDEX idx_places_tag_weights_gin ON places USING GIN (tag_weights);
CREATE INDEX idx_places_embedding_hnsw  ON places USING hnsw (embedding vector_cosine_ops);
CREATE INDEX idx_place_tags_tag         ON place_tags (tag_id);
CREATE INDEX idx_interactions_user_time ON user_interactions_log (user_id, occurred_at DESC);
CREATE INDEX idx_interactions_place     ON user_interactions_log (place_id);
CREATE INDEX idx_interactions_time_brin ON user_interactions_log USING BRIN (occurred_at);
