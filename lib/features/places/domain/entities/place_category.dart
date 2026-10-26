/// Categoría de un lugar (tabla `categories`), con ícono y color del pin.
class PlaceCategory {
  const PlaceCategory({
    required this.slug,
    required this.name,
    required this.iconKey,
    required this.colorValue,
    this.parentSlug,
  });

  final String slug;
  final String name;
  final String iconKey;

  /// Color ARGB del pin (equivale a `color_hex` con alfa 0xFF).
  final int colorValue;
  final String? parentSlug;

  bool get isRoot => parentSlug == null;

  @override
  bool operator ==(Object other) =>
      other is PlaceCategory && other.slug == slug;

  @override
  int get hashCode => slug.hashCode;

  @override
  String toString() => 'PlaceCategory($slug)';
}

/// Espejo de las categorías del seed SQL para el modo local y el mapa.
abstract final class PlaceCategoryCatalog {
  static const List<PlaceCategory> all = <PlaceCategory>[
    PlaceCategory(
      slug: 'turismo_cultura',
      name: 'Turismo y cultura',
      iconKey: 'landmark',
      colorValue: 0xFF8E44AD,
    ),
    PlaceCategory(
      slug: 'gastronomia',
      name: 'Gastronomía',
      iconKey: 'restaurant',
      colorValue: 0xFFE67E22,
    ),
    PlaceCategory(
      slug: 'actividades',
      name: 'Actividades',
      iconKey: 'hiking',
      colorValue: 0xFF27AE60,
    ),
    PlaceCategory(
      slug: 'entretenimiento',
      name: 'Entretenimiento',
      iconKey: 'nightlife',
      colorValue: 0xFFE91E63,
    ),
    PlaceCategory(
      slug: 'museo',
      name: 'Museos',
      iconKey: 'museum',
      colorValue: 0xFF8E44AD,
      parentSlug: 'turismo_cultura',
    ),
    PlaceCategory(
      slug: 'mirador',
      name: 'Miradores',
      iconKey: 'binoculars',
      colorValue: 0xFF9B59B6,
      parentSlug: 'turismo_cultura',
    ),
    PlaceCategory(
      slug: 'sitio_historico',
      name: 'Sitios históricos',
      iconKey: 'monument',
      colorValue: 0xFF7D3C98,
      parentSlug: 'turismo_cultura',
    ),
    PlaceCategory(
      slug: 'restaurante',
      name: 'Restaurantes',
      iconKey: 'restaurant',
      colorValue: 0xFFE67E22,
      parentSlug: 'gastronomia',
    ),
    PlaceCategory(
      slug: 'cafeteria',
      name: 'Cafeterías',
      iconKey: 'coffee',
      colorValue: 0xFFD35400,
      parentSlug: 'gastronomia',
    ),
    PlaceCategory(
      slug: 'parque',
      name: 'Parques',
      iconKey: 'park',
      colorValue: 0xFF27AE60,
      parentSlug: 'actividades',
    ),
    PlaceCategory(
      slug: 'aventura',
      name: 'Aventura',
      iconKey: 'hiking',
      colorValue: 0xFF1E8449,
      parentSlug: 'actividades',
    ),
    PlaceCategory(
      slug: 'bar',
      name: 'Bares',
      iconKey: 'cocktail',
      colorValue: 0xFFE91E63,
      parentSlug: 'entretenimiento',
    ),
    PlaceCategory(
      slug: 'discoteca',
      name: 'Discotecas',
      iconKey: 'music',
      colorValue: 0xFFC2185B,
      parentSlug: 'entretenimiento',
    ),
  ];

  static final Map<String, PlaceCategory> _bySlug = <String, PlaceCategory>{
    for (final PlaceCategory category in all) category.slug: category,
  };

  /// Lanza [ArgumentError] si la categoría no existe.
  static PlaceCategory bySlug(String slug) {
    final PlaceCategory? category = _bySlug[slug];
    if (category == null) {
      throw ArgumentError.value(slug, 'slug', 'Categoría desconocida');
    }
    return category;
  }

  /// Categoría raíz (turismo, gastronomía, actividades o entretenimiento).
  static PlaceCategory rootOf(PlaceCategory category) =>
      category.isRoot ? category : bySlug(category.parentSlug!);
}
