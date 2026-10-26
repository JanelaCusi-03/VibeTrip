/// Catálogo de las 48 etiquetas del espacio de características.
///
/// Es el espejo en Dart de la tabla `tags` (supabase/seed.sql): mismo `slug`,
/// mismo grupo y mismo `vector_index`. Una prueba unitaria verifica que el
/// orden y la cantidad no cambien.
library;

enum TagGroup {
  ambiente('ambiente', 'Ambiente'),
  actividad('actividad', 'Actividad'),
  gastronomia('gastronomia', 'Gastronomía'),
  socialNocturno('social_nocturno', 'Social y nocturno'),
  perfilContexto('perfil_contexto', 'Perfil y contexto'),
  experiencia('experiencia', 'Experiencia');

  const TagGroup(this.wireName, this.displayName);

  final String wireName;
  final String displayName;
}

class TagDefinition {
  const TagDefinition({
    required this.slug,
    required this.displayName,
    required this.group,
    required this.vectorIndex,
  });

  final String slug;
  final String displayName;
  final TagGroup group;
  final int vectorIndex;
}

abstract final class TagCatalog {
  static const int dimension = 48;
  static const int tagsPerGroup = 8;

  static const List<String> _orderedSlugs = <String>[
    // ambiente (0-7)
    'tranquilo', 'animado', 'romantico', 'familiar',
    'bohemio', 'elegante', 'casual', 'vista_panoramica',
    // actividad (8-15)
    'aire_libre', 'aventura', 'cultural', 'historico',
    'naturaleza', 'deportivo', 'relajante', 'fotografico',
    // gastronomia (16-23)
    'comida_local', 'comida_internacional', 'vegetariano', 'cafeteria',
    'postres', 'street_food', 'fine_dining', 'bebidas_artesanales',
    // social_nocturno (24-31)
    'vida_nocturna', 'musica_en_vivo', 'bar', 'discoteca',
    'karaoke', 'juegos', 'eventos', 'terraza',
    // perfil_contexto (32-39)
    'economico', 'premium', 'para_grupos', 'para_parejas',
    'solo_friendly', 'pet_friendly', 'accesible', 'wifi_trabajo',
    // experiencia (40-47)
    'artesania', 'arte', 'museo', 'arquitectura',
    'tradicion_local', 'mistico', 'compras', 'mercado',
  ];

  static const List<String> _orderedDisplayNames = <String>[
    'Tranquilo',
    'Animado',
    'Romántico',
    'Familiar',
    'Bohemio',
    'Elegante',
    'Casual',
    'Vista panorámica',
    'Aire libre',
    'Aventura',
    'Cultural',
    'Histórico',
    'Naturaleza',
    'Deportivo',
    'Relajante',
    'Fotográfico',
    'Comida local',
    'Comida internacional',
    'Vegetariano',
    'Cafetería',
    'Postres',
    'Street food',
    'Alta cocina',
    'Bebidas artesanales',
    'Vida nocturna',
    'Música en vivo',
    'Bar',
    'Discoteca',
    'Karaoke',
    'Juegos',
    'Eventos',
    'Terraza',
    'Económico',
    'Premium',
    'Para grupos',
    'Para parejas',
    'Ideal para ir solo',
    'Pet friendly',
    'Accesible',
    'Wifi para trabajar',
    'Artesanía',
    'Arte',
    'Museo',
    'Arquitectura',
    'Tradición local',
    'Místico',
    'Compras',
    'Mercado',
  ];

  static final List<TagDefinition> all = List<TagDefinition>.unmodifiable(
    List<TagDefinition>.generate(
      dimension,
      (vectorIndex) => TagDefinition(
        slug: _orderedSlugs[vectorIndex],
        displayName: _orderedDisplayNames[vectorIndex],
        group: TagGroup.values[vectorIndex ~/ tagsPerGroup],
        vectorIndex: vectorIndex,
      ),
    ),
  );

  static final Map<String, TagDefinition> _bySlug = <String, TagDefinition>{
    for (final TagDefinition tag in all) tag.slug: tag,
  };

  static bool contains(String slug) => _bySlug.containsKey(slug);

  /// Lanza [ArgumentError] si el slug no pertenece al catálogo.
  static TagDefinition bySlug(String slug) {
    final TagDefinition? tag = _bySlug[slug];
    if (tag == null) {
      throw ArgumentError.value(slug, 'slug', 'Etiqueta desconocida');
    }
    return tag;
  }

  static TagDefinition byIndex(int vectorIndex) => all[vectorIndex];
}
