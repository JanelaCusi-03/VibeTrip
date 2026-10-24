-- Datos base: catalogo de las 48 etiquetas (vector_index 0-47) y categorias.
-- Se ejecuta automaticamente con `supabase db reset`.

INSERT INTO tags (slug, display_name, group_name, vector_index) VALUES
  -- ambiente (0-7)
  ('tranquilo', 'Tranquilo', 'ambiente', 0),
  ('animado', 'Animado', 'ambiente', 1),
  ('romantico', 'Romántico', 'ambiente', 2),
  ('familiar', 'Familiar', 'ambiente', 3),
  ('bohemio', 'Bohemio', 'ambiente', 4),
  ('elegante', 'Elegante', 'ambiente', 5),
  ('casual', 'Casual', 'ambiente', 6),
  ('vista_panoramica', 'Vista panorámica', 'ambiente', 7),
  -- actividad (8-15)
  ('aire_libre', 'Aire libre', 'actividad', 8),
  ('aventura', 'Aventura', 'actividad', 9),
  ('cultural', 'Cultural', 'actividad', 10),
  ('historico', 'Histórico', 'actividad', 11),
  ('naturaleza', 'Naturaleza', 'actividad', 12),
  ('deportivo', 'Deportivo', 'actividad', 13),
  ('relajante', 'Relajante', 'actividad', 14),
  ('fotografico', 'Fotográfico', 'actividad', 15),
  -- gastronomia (16-23)
  ('comida_local', 'Comida local', 'gastronomia', 16),
  ('comida_internacional', 'Comida internacional', 'gastronomia', 17),
  ('vegetariano', 'Vegetariano', 'gastronomia', 18),
  ('cafeteria', 'Cafetería', 'gastronomia', 19),
  ('postres', 'Postres', 'gastronomia', 20),
  ('street_food', 'Street food', 'gastronomia', 21),
  ('fine_dining', 'Alta cocina', 'gastronomia', 22),
  ('bebidas_artesanales', 'Bebidas artesanales', 'gastronomia', 23),
  -- social_nocturno (24-31)
  ('vida_nocturna', 'Vida nocturna', 'social_nocturno', 24),
  ('musica_en_vivo', 'Música en vivo', 'social_nocturno', 25),
  ('bar', 'Bar', 'social_nocturno', 26),
  ('discoteca', 'Discoteca', 'social_nocturno', 27),
  ('karaoke', 'Karaoke', 'social_nocturno', 28),
  ('juegos', 'Juegos', 'social_nocturno', 29),
  ('eventos', 'Eventos', 'social_nocturno', 30),
  ('terraza', 'Terraza', 'social_nocturno', 31),
  -- perfil_contexto (32-39)
  ('economico', 'Económico', 'perfil_contexto', 32),
  ('premium', 'Premium', 'perfil_contexto', 33),
  ('para_grupos', 'Para grupos', 'perfil_contexto', 34),
  ('para_parejas', 'Para parejas', 'perfil_contexto', 35),
  ('solo_friendly', 'Ideal para ir solo', 'perfil_contexto', 36),
  ('pet_friendly', 'Pet friendly', 'perfil_contexto', 37),
  ('accesible', 'Accesible', 'perfil_contexto', 38),
  ('wifi_trabajo', 'Wifi para trabajar', 'perfil_contexto', 39),
  -- experiencia (40-47)
  ('artesania', 'Artesanía', 'experiencia', 40),
  ('arte', 'Arte', 'experiencia', 41),
  ('museo', 'Museo', 'experiencia', 42),
  ('arquitectura', 'Arquitectura', 'experiencia', 43),
  ('tradicion_local', 'Tradición local', 'experiencia', 44),
  ('mistico', 'Místico', 'experiencia', 45),
  ('compras', 'Compras', 'experiencia', 46),
  ('mercado', 'Mercado', 'experiencia', 47);

-- Categorias raiz
INSERT INTO categories (slug, name, icon_key, color_hex) VALUES
  ('turismo_cultura', 'Turismo y cultura', 'landmark', '#8E44AD'),
  ('gastronomia', 'Gastronomía', 'restaurant', '#E67E22'),
  ('actividades', 'Actividades', 'hiking', '#27AE60'),
  ('entretenimiento', 'Entretenimiento', 'nightlife', '#E91E63');

-- Subcategorias
INSERT INTO categories (parent_id, slug, name, icon_key, color_hex)
SELECT p.id, s.slug, s.name, s.icon_key, s.color_hex
FROM (VALUES
  ('turismo_cultura', 'museo',        'Museos',              'museum',      '#8E44AD'),
  ('turismo_cultura', 'mirador',      'Miradores',           'binoculars',  '#9B59B6'),
  ('turismo_cultura', 'sitio_historico', 'Sitios históricos', 'monument',   '#7D3C98'),
  ('gastronomia',     'restaurante',  'Restaurantes',        'restaurant',  '#E67E22'),
  ('gastronomia',     'cafeteria',    'Cafeterías',          'coffee',      '#D35400'),
  ('actividades',     'parque',       'Parques',             'park',        '#27AE60'),
  ('actividades',     'aventura',     'Aventura',            'hiking',      '#1E8449'),
  ('entretenimiento', 'bar',          'Bares',               'cocktail',    '#E91E63'),
  ('entretenimiento', 'discoteca',    'Discotecas',          'music',       '#C2185B')
) AS s(parent_slug, slug, name, icon_key, color_hex)
JOIN categories p ON p.slug = s.parent_slug;
