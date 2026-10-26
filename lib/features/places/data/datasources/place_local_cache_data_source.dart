import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/data/json_reading.dart';

/// Copia local de los lugares para el modo sin conexión (RF-15, RNF-05).
class PlaceLocalCacheDataSource {
  const PlaceLocalCacheDataSource(this._preferences);

  static const String storageKey = 'cache.places.v1';

  final SharedPreferences _preferences;

  Future<void> savePlaceRows(List<JsonMap> placeRows, DateTime savedAt) =>
      _preferences.setString(
        storageKey,
        jsonEncode(<String, Object?>{
          'saved_at': savedAt.toUtc().toIso8601String(),
          'places': placeRows,
        }),
      );

  /// `null` si nunca se guardó caché o está corrupta.
  CachedPlaceRows? readPlaceRows() {
    final String? encoded = _preferences.getString(storageKey);
    if (encoded == null) return null;
    try {
      final JsonMap document = jsonDecode(encoded) as JsonMap;
      return CachedPlaceRows(
        savedAt: DateTime.parse(document.read<String>('saved_at')),
        placeRows: document.read<List<Object?>>('places').cast<JsonMap>(),
      );
    } on FormatException {
      return null;
    }
  }

  Future<void> clear() => _preferences.remove(storageKey);
}

class CachedPlaceRows {
  const CachedPlaceRows({required this.savedAt, required this.placeRows});

  final DateTime savedAt;
  final List<JsonMap> placeRows;
}
