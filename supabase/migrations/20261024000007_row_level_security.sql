ALTER TABLE users                    ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_preference_vectors  ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_interactions_log    ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_favorites           ENABLE ROW LEVEL SECURITY;
ALTER TABLE places                   ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories               ENABLE ROW LEVEL SECURITY;
ALTER TABLE tags                     ENABLE ROW LEVEL SECURITY;
ALTER TABLE place_tags               ENABLE ROW LEVEL SECURITY;

-- Datos propios: lectura y escritura solo del dueno
CREATE POLICY users_owner_all ON users
  FOR ALL USING (id = auth.uid()) WITH CHECK (id = auth.uid());
CREATE POLICY preference_vectors_owner_all ON user_preference_vectors
  FOR ALL USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE POLICY favorites_owner_all ON user_favorites
  FOR ALL USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- Log de eventos: el dueno puede leer e insertar, pero no modificar ni borrar
CREATE POLICY interactions_owner_select ON user_interactions_log
  FOR SELECT USING (user_id = auth.uid());
CREATE POLICY interactions_owner_insert ON user_interactions_log
  FOR INSERT WITH CHECK (user_id = auth.uid());

-- Catalogos: lectura para usuarios autenticados
CREATE POLICY places_authenticated_read     ON places     FOR SELECT TO authenticated USING (is_active);
CREATE POLICY categories_authenticated_read ON categories FOR SELECT TO authenticated USING (TRUE);
CREATE POLICY tags_authenticated_read       ON tags       FOR SELECT TO authenticated USING (TRUE);
CREATE POLICY place_tags_authenticated_read ON place_tags FOR SELECT TO authenticated USING (TRUE);
