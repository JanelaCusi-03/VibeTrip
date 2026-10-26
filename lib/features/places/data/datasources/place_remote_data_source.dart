import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/data/json_reading.dart';

/// Origen "remoto" de las filas de `places` (Supabase o seed empaquetado).
abstract interface class PlaceRemoteDataSource {
  Future<List<JsonMap>> fetchActivePlaceRows();
}

/// Lee `assets/seed/places.json` (modo local, sin backend configurado).
class SeedPlaceDataSource implements PlaceRemoteDataSource {
  const SeedPlaceDataSource(this._loadSeedJson);

  static const String assetPath = 'assets/seed/places.json';

  /// Normalmente `() => rootBundle.loadString(assetPath)`; inyectable en pruebas.
  final Future<String> Function() _loadSeedJson;

  @override
  Future<List<JsonMap>> fetchActivePlaceRows() async {
    final JsonMap seedDocument = jsonDecode(await _loadSeedJson()) as JsonMap;
    return seedDocument
        .read<List<Object?>>('places')
        .cast<JsonMap>()
        .where((row) => row['is_active'] != false)
        .toList();
  }
}

/// Lee la tabla `places` vía PostgREST, uniendo el slug de su categoría.
class SupabasePlaceDataSource implements PlaceRemoteDataSource {
  const SupabasePlaceDataSource(this._client);

  final SupabaseClient _client;

  @override
  Future<List<JsonMap>> fetchActivePlaceRows() async {
    final List<JsonMap> rows = await _client
        .from('places')
        .select(
          'id, name, description, address, latitude, longitude, price_level, '
          'estimated_cost, is_outdoor, best_time_buckets, companion_fit, '
          'rating_average, rating_count, image_urls, tag_weights, is_active, '
          'categories(slug)',
        )
        .eq('is_active', true);
    return rows;
  }
}
