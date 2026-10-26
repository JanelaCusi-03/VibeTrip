import '../../../../core/domain/context_types.dart';
import '../../../../core/domain/geo_distance.dart';

/// Contexto en tiempo real con el que se consulta el motor (E1 §1.4).
///
/// No se guarda en el vector de gustos: modula el puntaje y se registra como
/// [toSnapshot] en cada evento de telemetría.
class RecommendationContext {
  const RecommendationContext({
    required this.timeBucket,
    required this.budgetLevel,
    required this.companion,
    required this.searchRadiusInMeters,
    this.userLocation,
    this.weather = WeatherCondition.unknown,
    this.maximumPriceLevel,
  });

  /// `null` si no hay permiso de GPS ni zona manual: no se filtra por distancia.
  final GeoPoint? userLocation;
  final TimeBucket timeBucket;
  final WeatherCondition weather;
  final int budgetLevel;
  final CompanionType companion;
  final int searchRadiusInMeters;

  /// Filtro duro opcional (filtro rápido «Económico»).
  final int? maximumPriceLevel;

  RecommendationContext copyWith({
    GeoPoint? userLocation,
    TimeBucket? timeBucket,
    WeatherCondition? weather,
    int? budgetLevel,
    CompanionType? companion,
    int? searchRadiusInMeters,
    int? maximumPriceLevel,
  }) =>
      RecommendationContext(
        userLocation: userLocation ?? this.userLocation,
        timeBucket: timeBucket ?? this.timeBucket,
        weather: weather ?? this.weather,
        budgetLevel: budgetLevel ?? this.budgetLevel,
        companion: companion ?? this.companion,
        searchRadiusInMeters: searchRadiusInMeters ?? this.searchRadiusInMeters,
        maximumPriceLevel: maximumPriceLevel ?? this.maximumPriceLevel,
      );

  /// Forma de `context_snapshot` (JSONB) en `user_interactions_log`.
  Map<String, Object?> toSnapshot() => <String, Object?>{
        'lat': userLocation?.latitude,
        'lon': userLocation?.longitude,
        'time_bucket': timeBucket.wireName,
        'weather': weather.wireName,
        'budget': budgetLevel,
        'companion': companion.wireName,
      };
}
