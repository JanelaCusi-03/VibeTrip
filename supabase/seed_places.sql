-- ARCHIVO GENERADO por tool/generate_seed_sql.dart; no editar.
-- Fuente: assets/seed/places.json (18 lugares).
-- Ejecutar después de seed.sql (requiere tags y categories).

-- Qorikancha
INSERT INTO places (id, category_id, name, description, address, latitude, longitude, price_level, estimated_cost, is_outdoor, best_time_buckets, companion_fit, image_urls, is_active)
SELECT 'a1000000-0000-4000-8000-000000000001', c.id, 'Qorikancha', 'Templo inca del Sol con el convento de Santo Domingo construido encima.', 'Av. El Sol s/n, Cusco', -13.5199, -71.9752, 2, 20.0, false, ARRAY['morning', 'afternoon']::time_bucket[], ARRAY['solo', 'couple', 'family']::companion_type[], '{}'::text[], true
FROM categories c WHERE c.slug = 'sitio_historico';
INSERT INTO place_tags (place_id, tag_id, weight)
SELECT 'a1000000-0000-4000-8000-000000000001', t.id, v.weight
FROM (VALUES ('historico', 1.0), ('arquitectura', 1.0), ('cultural', 0.9), ('mistico', 0.7), ('fotografico', 0.7), ('museo', 0.6), ('tranquilo', 0.6), ('solo_friendly', 0.6), ('accesible', 0.5)) AS v(slug, weight)
JOIN tags t ON t.slug = v.slug;

-- Museo de Arte Precolombino (MAP)
INSERT INTO places (id, category_id, name, description, address, latitude, longitude, price_level, estimated_cost, is_outdoor, best_time_buckets, companion_fit, image_urls, is_active)
SELECT 'a1000000-0000-4000-8000-000000000002', c.id, 'Museo de Arte Precolombino (MAP)', 'Colección de arte precolombino en una casona colonial frente a la plaza Nazarenas.', 'Plaza Nazarenas 231, Cusco', -13.5153, -71.9775, 2, 25.0, false, ARRAY['morning', 'afternoon', 'evening']::time_bucket[], ARRAY['solo', 'couple']::companion_type[], '{}'::text[], true
FROM categories c WHERE c.slug = 'museo';
INSERT INTO place_tags (place_id, tag_id, weight)
SELECT 'a1000000-0000-4000-8000-000000000002', t.id, v.weight
FROM (VALUES ('museo', 1.0), ('arte', 1.0), ('cultural', 0.9), ('tranquilo', 0.7), ('solo_friendly', 0.7), ('elegante', 0.5), ('para_parejas', 0.5), ('historico', 0.5)) AS v(slug, weight)
JOIN tags t ON t.slug = v.slug;

-- Sacsayhuamán
INSERT INTO places (id, category_id, name, description, address, latitude, longitude, price_level, estimated_cost, is_outdoor, best_time_buckets, companion_fit, image_urls, is_active)
SELECT 'a1000000-0000-4000-8000-000000000003', c.id, 'Sacsayhuamán', 'Complejo arqueológico inca con muros ciclópeos y vista a la ciudad.', 'Parque Arqueológico de Saqsaywaman, Cusco', -13.5094, -71.9817, 3, 70.0, true, ARRAY['morning', 'afternoon']::time_bucket[], ARRAY['solo', 'couple', 'friends', 'family']::companion_type[], '{}'::text[], true
FROM categories c WHERE c.slug = 'sitio_historico';
INSERT INTO place_tags (place_id, tag_id, weight)
SELECT 'a1000000-0000-4000-8000-000000000003', t.id, v.weight
FROM (VALUES ('historico', 1.0), ('aire_libre', 1.0), ('arquitectura', 0.9), ('fotografico', 0.9), ('vista_panoramica', 0.7), ('mistico', 0.6), ('para_grupos', 0.6), ('aventura', 0.3)) AS v(slug, weight)
JOIN tags t ON t.slug = v.slug;

-- Mirador de San Cristóbal
INSERT INTO places (id, category_id, name, description, address, latitude, longitude, price_level, estimated_cost, is_outdoor, best_time_buckets, companion_fit, image_urls, is_active)
SELECT 'a1000000-0000-4000-8000-000000000004', c.id, 'Mirador de San Cristóbal', 'Mirador gratuito junto a la iglesia de San Cristóbal con vista de los techos del centro.', 'Plaza San Cristóbal, Cusco', -13.5134, -71.9806, 1, 0.0, true, ARRAY['afternoon', 'evening']::time_bucket[], ARRAY['solo', 'couple', 'friends']::companion_type[], '{}'::text[], true
FROM categories c WHERE c.slug = 'mirador';
INSERT INTO place_tags (place_id, tag_id, weight)
SELECT 'a1000000-0000-4000-8000-000000000004', t.id, v.weight
FROM (VALUES ('vista_panoramica', 1.0), ('fotografico', 0.9), ('economico', 0.9), ('aire_libre', 0.8), ('romantico', 0.6), ('tranquilo', 0.5), ('arquitectura', 0.4), ('para_parejas', 0.5)) AS v(slug, weight)
JOIN tags t ON t.slug = v.slug;

-- Cristo Blanco
INSERT INTO places (id, category_id, name, description, address, latitude, longitude, price_level, estimated_cost, is_outdoor, best_time_buckets, companion_fit, image_urls, is_active)
SELECT 'a1000000-0000-4000-8000-000000000005', c.id, 'Cristo Blanco', 'Estatua y mirador en la colina sobre Sacsayhuamán, ideal para caminar al atardecer.', 'Colina Pukamoqo, Cusco', -13.5097, -71.9765, 1, 0.0, true, ARRAY['morning', 'afternoon']::time_bucket[], ARRAY['solo', 'couple', 'friends', 'family']::companion_type[], '{}'::text[], true
FROM categories c WHERE c.slug = 'mirador';
INSERT INTO place_tags (place_id, tag_id, weight)
SELECT 'a1000000-0000-4000-8000-000000000005', t.id, v.weight
FROM (VALUES ('vista_panoramica', 1.0), ('aire_libre', 0.9), ('economico', 0.9), ('fotografico', 0.8), ('familiar', 0.6), ('tranquilo', 0.6), ('naturaleza', 0.5), ('deportivo', 0.3)) AS v(slug, weight)
JOIN tags t ON t.slug = v.slug;

-- Barrio de San Blas
INSERT INTO places (id, category_id, name, description, address, latitude, longitude, price_level, estimated_cost, is_outdoor, best_time_buckets, companion_fit, image_urls, is_active)
SELECT 'a1000000-0000-4000-8000-000000000006', c.id, 'Barrio de San Blas', 'Barrio de artesanos con calles empinadas, talleres y galerías.', 'Plazoleta de San Blas, Cusco', -13.5163, -71.975, 1, 0.0, true, ARRAY['morning', 'afternoon', 'evening']::time_bucket[], ARRAY['solo', 'couple', 'friends', 'family']::companion_type[], '{}'::text[], true
FROM categories c WHERE c.slug = 'sitio_historico';
INSERT INTO place_tags (place_id, tag_id, weight)
SELECT 'a1000000-0000-4000-8000-000000000006', t.id, v.weight
FROM (VALUES ('bohemio', 1.0), ('artesania', 0.9), ('arte', 0.8), ('arquitectura', 0.7), ('fotografico', 0.7), ('casual', 0.6), ('compras', 0.5), ('economico', 0.6)) AS v(slug, weight)
JOIN tags t ON t.slug = v.slug;

-- Mercado Central de San Pedro
INSERT INTO places (id, category_id, name, description, address, latitude, longitude, price_level, estimated_cost, is_outdoor, best_time_buckets, companion_fit, image_urls, is_active)
SELECT 'a1000000-0000-4000-8000-000000000007', c.id, 'Mercado Central de San Pedro', 'Mercado tradicional con jugos, caldos y comida típica a precios populares.', 'Calle Cascaparo, Cusco', -13.5225, -71.9844, 1, 12.0, false, ARRAY['morning', 'afternoon']::time_bucket[], ARRAY['solo', 'friends', 'family']::companion_type[], '{}'::text[], true
FROM categories c WHERE c.slug = 'restaurante';
INSERT INTO place_tags (place_id, tag_id, weight)
SELECT 'a1000000-0000-4000-8000-000000000007', t.id, v.weight
FROM (VALUES ('mercado', 1.0), ('economico', 1.0), ('comida_local', 0.9), ('street_food', 0.9), ('tradicion_local', 0.9), ('animado', 0.7), ('casual', 0.7), ('compras', 0.6)) AS v(slug, weight)
JOIN tags t ON t.slug = v.slug;

-- Chicha por Gastón Acurio
INSERT INTO places (id, category_id, name, description, address, latitude, longitude, price_level, estimated_cost, is_outdoor, best_time_buckets, companion_fit, image_urls, is_active)
SELECT 'a1000000-0000-4000-8000-000000000008', c.id, 'Chicha por Gastón Acurio', 'Cocina regional cusqueña reinterpretada por un chef reconocido.', 'Plaza Regocijo 261, Cusco', -13.517, -71.98, 3, 90.0, false, ARRAY['afternoon', 'evening']::time_bucket[], ARRAY['couple', 'friends', 'family']::companion_type[], '{}'::text[], true
FROM categories c WHERE c.slug = 'restaurante';
INSERT INTO place_tags (place_id, tag_id, weight)
SELECT 'a1000000-0000-4000-8000-000000000008', t.id, v.weight
FROM (VALUES ('comida_local', 1.0), ('fine_dining', 0.6), ('elegante', 0.6), ('para_parejas', 0.6), ('premium', 0.5), ('bebidas_artesanales', 0.4), ('romantico', 0.4)) AS v(slug, weight)
JOIN tags t ON t.slug = v.slug;

-- Cicciolina
INSERT INTO places (id, category_id, name, description, address, latitude, longitude, price_level, estimated_cost, is_outdoor, best_time_buckets, companion_fit, image_urls, is_active)
SELECT 'a1000000-0000-4000-8000-000000000009', c.id, 'Cicciolina', 'Restaurante y bar de tapas mediterráneas en el segundo piso de una casona.', 'Calle Triunfo 393, Cusco', -13.516, -71.9767, 3, 100.0, false, ARRAY['evening']::time_bucket[], ARRAY['couple']::companion_type[], '{}'::text[], true
FROM categories c WHERE c.slug = 'restaurante';
INSERT INTO place_tags (place_id, tag_id, weight)
SELECT 'a1000000-0000-4000-8000-000000000009', t.id, v.weight
FROM (VALUES ('comida_internacional', 0.9), ('para_parejas', 0.9), ('romantico', 0.8), ('elegante', 0.7), ('bohemio', 0.5), ('bebidas_artesanales', 0.5), ('premium', 0.5)) AS v(slug, weight)
JOIN tags t ON t.slug = v.slug;

-- Pachapapa
INSERT INTO places (id, category_id, name, description, address, latitude, longitude, price_level, estimated_cost, is_outdoor, best_time_buckets, companion_fit, image_urls, is_active)
SELECT 'a1000000-0000-4000-8000-000000000010', c.id, 'Pachapapa', 'Cocina andina en un patio colonial con horno de barro, ideal para grupos.', 'Plazoleta San Blas 120, Cusco', -13.5161, -71.9753, 2, 55.0, false, ARRAY['afternoon', 'evening']::time_bucket[], ARRAY['couple', 'friends', 'family']::companion_type[], '{}'::text[], true
FROM categories c WHERE c.slug = 'restaurante';
INSERT INTO place_tags (place_id, tag_id, weight)
SELECT 'a1000000-0000-4000-8000-000000000010', t.id, v.weight
FROM (VALUES ('comida_local', 1.0), ('tradicion_local', 0.8), ('familiar', 0.8), ('terraza', 0.7), ('para_grupos', 0.7), ('casual', 0.6)) AS v(slug, weight)
JOIN tags t ON t.slug = v.slug;

-- Green Point
INSERT INTO places (id, category_id, name, description, address, latitude, longitude, price_level, estimated_cost, is_outdoor, best_time_buckets, companion_fit, image_urls, is_active)
SELECT 'a1000000-0000-4000-8000-000000000011', c.id, 'Green Point', 'Restaurante vegano con menú del día económico en San Blas.', 'Calle Carmen Bajo 235, Cusco', -13.5158, -71.9746, 1, 25.0, false, ARRAY['morning', 'afternoon']::time_bucket[], ARRAY['solo', 'couple', 'friends']::companion_type[], '{}'::text[], true
FROM categories c WHERE c.slug = 'restaurante';
INSERT INTO place_tags (place_id, tag_id, weight)
SELECT 'a1000000-0000-4000-8000-000000000011', t.id, v.weight
FROM (VALUES ('vegetariano', 1.0), ('casual', 0.7), ('solo_friendly', 0.7), ('economico', 0.6), ('bohemio', 0.5), ('tranquilo', 0.5)) AS v(slug, weight)
JOIN tags t ON t.slug = v.slug;

-- Jack's Café
INSERT INTO places (id, category_id, name, description, address, latitude, longitude, price_level, estimated_cost, is_outdoor, best_time_buckets, companion_fit, image_urls, is_active)
SELECT 'a1000000-0000-4000-8000-000000000012', c.id, 'Jack''s Café', 'Cafetería de desayunos abundantes, postres y buen café.', 'Calle Choquechaca 509, Cusco', -13.5165, -71.9757, 2, 30.0, false, ARRAY['morning', 'afternoon']::time_bucket[], ARRAY['solo', 'couple', 'friends', 'family']::companion_type[], '{}'::text[], true
FROM categories c WHERE c.slug = 'cafeteria';
INSERT INTO place_tags (place_id, tag_id, weight)
SELECT 'a1000000-0000-4000-8000-000000000012', t.id, v.weight
FROM (VALUES ('cafeteria', 1.0), ('casual', 0.8), ('postres', 0.7), ('comida_internacional', 0.6), ('solo_friendly', 0.6), ('wifi_trabajo', 0.5), ('animado', 0.4)) AS v(slug, weight)
JOIN tags t ON t.slug = v.slug;

-- Limbus Restobar
INSERT INTO places (id, category_id, name, description, address, latitude, longitude, price_level, estimated_cost, is_outdoor, best_time_buckets, companion_fit, image_urls, is_active)
SELECT 'a1000000-0000-4000-8000-000000000013', c.id, 'Limbus Restobar', 'Bar en la ladera de San Blas con terraza y una de las mejores vistas nocturnas.', 'Pasñapakana 133, Cusco', -13.5148, -71.9748, 3, 60.0, false, ARRAY['evening', 'night']::time_bucket[], ARRAY['couple', 'friends']::companion_type[], '{}'::text[], true
FROM categories c WHERE c.slug = 'bar';
INSERT INTO place_tags (place_id, tag_id, weight)
SELECT 'a1000000-0000-4000-8000-000000000013', t.id, v.weight
FROM (VALUES ('vista_panoramica', 1.0), ('terraza', 1.0), ('bar', 0.9), ('bebidas_artesanales', 0.8), ('romantico', 0.6), ('vida_nocturna', 0.6), ('para_parejas', 0.6), ('fotografico', 0.5)) AS v(slug, weight)
JOIN tags t ON t.slug = v.slug;

-- Ukukus
INSERT INTO places (id, category_id, name, description, address, latitude, longitude, price_level, estimated_cost, is_outdoor, best_time_buckets, companion_fit, image_urls, is_active)
SELECT 'a1000000-0000-4000-8000-000000000014', c.id, 'Ukukus', 'Bar con música en vivo todas las noches, de los clásicos de la vida nocturna cusqueña.', 'Calle Plateros 316, Cusco', -13.5163, -71.9791, 2, 30.0, false, ARRAY['night']::time_bucket[], ARRAY['solo', 'friends']::companion_type[], '{}'::text[], true
FROM categories c WHERE c.slug = 'bar';
INSERT INTO place_tags (place_id, tag_id, weight)
SELECT 'a1000000-0000-4000-8000-000000000014', t.id, v.weight
FROM (VALUES ('musica_en_vivo', 1.0), ('vida_nocturna', 1.0), ('animado', 1.0), ('bar', 0.9), ('para_grupos', 0.8), ('economico', 0.5), ('bohemio', 0.4)) AS v(slug, weight)
JOIN tags t ON t.slug = v.slug;

-- Mama Africa
INSERT INTO places (id, category_id, name, description, address, latitude, longitude, price_level, estimated_cost, is_outdoor, best_time_buckets, companion_fit, image_urls, is_active)
SELECT 'a1000000-0000-4000-8000-000000000015', c.id, 'Mama Africa', 'Discoteca frente a la Plaza de Armas, punto de encuentro de viajeros.', 'Portal de Harinas 191, Cusco', -13.5171, -71.9785, 2, 25.0, false, ARRAY['night']::time_bucket[], ARRAY['friends']::companion_type[], '{}'::text[], true
FROM categories c WHERE c.slug = 'discoteca';
INSERT INTO place_tags (place_id, tag_id, weight)
SELECT 'a1000000-0000-4000-8000-000000000015', t.id, v.weight
FROM (VALUES ('discoteca', 1.0), ('vida_nocturna', 1.0), ('animado', 1.0), ('para_grupos', 0.9), ('economico', 0.5), ('musica_en_vivo', 0.3)) AS v(slug, weight)
JOIN tags t ON t.slug = v.slug;

-- Plaza de Armas del Cusco
INSERT INTO places (id, category_id, name, description, address, latitude, longitude, price_level, estimated_cost, is_outdoor, best_time_buckets, companion_fit, image_urls, is_active)
SELECT 'a1000000-0000-4000-8000-000000000016', c.id, 'Plaza de Armas del Cusco', 'Corazón histórico de la ciudad, rodeado por la Catedral y la Compañía de Jesús.', 'Plaza de Armas, Cusco', -13.5167, -71.9788, 1, 0.0, true, ARRAY['morning', 'afternoon', 'evening', 'night']::time_bucket[], ARRAY['solo', 'couple', 'friends', 'family']::companion_type[], '{}'::text[], true
FROM categories c WHERE c.slug = 'parque';
INSERT INTO place_tags (place_id, tag_id, weight)
SELECT 'a1000000-0000-4000-8000-000000000016', t.id, v.weight
FROM (VALUES ('arquitectura', 1.0), ('economico', 1.0), ('historico', 0.9), ('fotografico', 0.9), ('aire_libre', 0.7), ('familiar', 0.7), ('accesible', 0.7), ('animado', 0.6), ('eventos', 0.5), ('pet_friendly', 0.4)) AS v(slug, weight)
JOIN tags t ON t.slug = v.slug;

-- Caminata al Templo de la Luna
INSERT INTO places (id, category_id, name, description, address, latitude, longitude, price_level, estimated_cost, is_outdoor, best_time_buckets, companion_fit, image_urls, is_active)
SELECT 'a1000000-0000-4000-8000-000000000017', c.id, 'Caminata al Templo de la Luna', 'Ruta de caminata entre eucaliptos hacia el santuario inca de Amaru Marka Wasi.', 'Sector Templo de la Luna, Cusco', -13.5011, -71.9719, 1, 0.0, true, ARRAY['morning', 'afternoon']::time_bucket[], ARRAY['solo', 'couple', 'friends']::companion_type[], '{}'::text[], true
FROM categories c WHERE c.slug = 'aventura';
INSERT INTO place_tags (place_id, tag_id, weight)
SELECT 'a1000000-0000-4000-8000-000000000017', t.id, v.weight
FROM (VALUES ('aire_libre', 1.0), ('naturaleza', 0.9), ('mistico', 0.8), ('economico', 0.8), ('aventura', 0.7), ('deportivo', 0.6), ('tranquilo', 0.6), ('historico', 0.5)) AS v(slug, weight)
JOIN tags t ON t.slug = v.slug;

-- Centro de Textiles Tradicionales del Cusco
INSERT INTO places (id, category_id, name, description, address, latitude, longitude, price_level, estimated_cost, is_outdoor, best_time_buckets, companion_fit, image_urls, is_active)
SELECT 'a1000000-0000-4000-8000-000000000018', c.id, 'Centro de Textiles Tradicionales del Cusco', 'Museo vivo de tejido andino con demostraciones de tejedoras de comunidades.', 'Av. El Sol 603, Cusco', -13.5208, -71.9744, 1, 0.0, false, ARRAY['morning', 'afternoon', 'evening']::time_bucket[], ARRAY['solo', 'couple', 'family']::companion_type[], '{}'::text[], true
FROM categories c WHERE c.slug = 'museo';
INSERT INTO place_tags (place_id, tag_id, weight)
SELECT 'a1000000-0000-4000-8000-000000000018', t.id, v.weight
FROM (VALUES ('artesania', 1.0), ('tradicion_local', 1.0), ('cultural', 0.8), ('compras', 0.7), ('museo', 0.6), ('tranquilo', 0.5), ('accesible', 0.6)) AS v(slug, weight)
JOIN tags t ON t.slug = v.slug;

