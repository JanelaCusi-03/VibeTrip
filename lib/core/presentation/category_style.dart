import 'package:flutter/material.dart';

import '../../features/places/domain/entities/place_category.dart';

/// Ícono y color de cada categoría (pines del mapa y tarjetas del feed).
abstract final class CategoryStyle {
  static const Map<String, IconData> _iconsByKey = <String, IconData>{
    'landmark': Icons.account_balance,
    'restaurant': Icons.restaurant,
    'hiking': Icons.hiking,
    'nightlife': Icons.nightlife,
    'museum': Icons.museum,
    'binoculars': Icons.landscape,
    'monument': Icons.account_balance,
    'coffee': Icons.local_cafe,
    'park': Icons.park,
    'cocktail': Icons.local_bar,
    'music': Icons.music_note,
  };

  static IconData iconOf(PlaceCategory category) =>
      _iconsByKey[category.iconKey] ?? Icons.place;

  static Color colorOf(PlaceCategory category) => Color(category.colorValue);
}
