CREATE TRIGGER trg_users_updated_at   BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_places_updated_at  BEFORE UPDATE ON places
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_pref_updated_at    BEFORE UPDATE ON user_preference_vectors
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Reconstruye embedding y tag_weights de un lugar desde place_tags
CREATE OR REPLACE FUNCTION refresh_place_vector(target_place_id UUID) RETURNS VOID AS $$
DECLARE
  dense_vector REAL[] := array_fill(0::REAL, ARRAY[48]);
  tag_row      RECORD;
BEGIN
  FOR tag_row IN
    SELECT t.vector_index, pt.weight
    FROM place_tags pt
    JOIN tags t ON t.id = pt.tag_id
    WHERE pt.place_id = target_place_id
  LOOP
    dense_vector[tag_row.vector_index + 1] := tag_row.weight::REAL;
  END LOOP;

  UPDATE places
  SET embedding   = dense_vector::VECTOR(48),
      tag_weights = COALESCE((
        SELECT jsonb_object_agg(t.slug, pt.weight)
        FROM place_tags pt
        JOIN tags t ON t.id = pt.tag_id
        WHERE pt.place_id = target_place_id
      ), '{}'::jsonb)
  WHERE id = target_place_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION trg_place_tags_refresh_vector() RETURNS TRIGGER AS $$
BEGIN
  PERFORM refresh_place_vector(COALESCE(NEW.place_id, OLD.place_id));
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_place_tags_after_change
  AFTER INSERT OR UPDATE OR DELETE ON place_tags
  FOR EACH ROW EXECUTE FUNCTION trg_place_tags_refresh_vector();
