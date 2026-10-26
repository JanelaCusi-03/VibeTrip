import '../../../../core/domain/context_types.dart';
import '../../../../core/domain/geo_distance.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../entities/recommendation_context.dart';

/// Filtros rápidos del feed: «¿Qué plan buscas hoy?» (RF-06).
enum QuickFilter {
  solo('Solo'),
  friends('Con amigos'),
  economic('Económico'),
  nearMe('Cerca de mí');

  const QuickFilter(this.label);

  final String label;

  static const int economicMaximumPriceLevel = 2;
  static const int nearMeRadiusInMeters = 1000;

  RecommendationContext applyTo(RecommendationContext context) =>
      switch (this) {
        QuickFilter.solo => context.copyWith(companion: CompanionType.solo),
        QuickFilter.friends =>
          context.copyWith(companion: CompanionType.friends),
        QuickFilter.economic =>
          context.copyWith(maximumPriceLevel: economicMaximumPriceLevel),
        QuickFilter.nearMe =>
          context.copyWith(searchRadiusInMeters: nearMeRadiusInMeters),
      };
}

/// Lecturas del dispositivo para la captura contextual (E1 §1.4).
abstract interface class ContextSensor {
  /// `null` si no hay permiso, servicio desactivado o tiempo agotado.
  Future<GeoPoint?> readLocation();

  /// [WeatherCondition.unknown] si no hay red (efecto neutro).
  Future<WeatherCondition> readWeather(GeoPoint location);
}

/// Combina los *defaults* del perfil, el reloj, el clima, la ubicación y el
/// filtro rápido en un [RecommendationContext].
abstract final class RecommendationContextBuilder {
  static RecommendationContext build({
    required UserProfile profile,
    required DateTime now,
    GeoPoint? userLocation,
    WeatherCondition weather = WeatherCondition.unknown,
    QuickFilter? quickFilter,
  }) {
    final RecommendationContext baseContext = RecommendationContext(
      userLocation: userLocation,
      timeBucket: TimeBucket.fromDateTime(now),
      weather: weather,
      budgetLevel: profile.defaultBudgetLevel,
      companion: profile.defaultCompanion,
      searchRadiusInMeters: profile.searchRadiusInMeters,
    );
    return quickFilter?.applyTo(baseContext) ?? baseContext;
  }
}
