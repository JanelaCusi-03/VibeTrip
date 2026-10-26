import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/context_types.dart';
import '../../../core/domain/geo_distance.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/providers/dependency_providers.dart';
import '../../places/domain/entities/place.dart';
import '../../profile/domain/entities/user_profile.dart';
import '../../profile/presentation/user_profile_controller.dart';
import '../domain/entities/recommendation_context.dart';
import '../domain/entities/recommendation_result.dart';
import '../domain/services/recommendation_context_builder.dart';

/// Zona manual por defecto (E1 §1.4): Plaza de Armas del Cusco, donde están
/// los datos semilla.
const GeoPoint manualZoneLocation = GeoPoint(
  latitude: -13.5167,
  longitude: -71.9788,
);
const String manualZoneLabel = 'Centro de Cusco';

/// De dónde salió la ubicación del contexto actual.
enum LocationSourceKind { deviceGps, manualZone }

/// `true` para usar el GPS; `false` para fijar la zona manual.
final NotifierProvider<UseDeviceLocationNotifier, bool>
    useDeviceLocationProvider =
    NotifierProvider<UseDeviceLocationNotifier, bool>(
  UseDeviceLocationNotifier.new,
);

class UseDeviceLocationNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void toggle() => state = !state;
}

/// Filtro rápido seleccionado (o ninguno).
final NotifierProvider<QuickFilterNotifier, QuickFilter?> quickFilterProvider =
    NotifierProvider<QuickFilterNotifier, QuickFilter?>(
  QuickFilterNotifier.new,
);

class QuickFilterNotifier extends Notifier<QuickFilter?> {
  @override
  QuickFilter? build() => null;

  /// Tocar el filtro activo lo desactiva.
  void select(QuickFilter filter) => state = state == filter ? null : filter;
}

class FeedContext {
  const FeedContext({required this.context, required this.locationSource});

  final RecommendationContext context;
  final LocationSourceKind locationSource;
}

/// Contexto actual: perfil + reloj + GPS (o zona manual) + clima + filtro.
///
/// Solo se recalcula si cambian los *defaults* del perfil, no con cada
/// interacción (evita pedir GPS y clima en cada evento de telemetría).
final FutureProvider<FeedContext> feedContextProvider =
    FutureProvider.autoDispose<FeedContext>((ref) async {
  final QuickFilter? quickFilter = ref.watch(quickFilterProvider);
  final bool useDeviceLocation = ref.watch(useDeviceLocationProvider);
  await ref.watch(
    userProfileControllerProvider.selectAsync(
      (profile) => (
        profile.defaultBudgetLevel,
        profile.defaultCompanion,
        profile.searchRadiusInMeters,
      ),
    ),
  );
  final UserProfile profile =
      await ref.read(userProfileControllerProvider.future);
  final ContextSensor sensor = ref.watch(contextSensorProvider);

  final GeoPoint? deviceLocation =
      useDeviceLocation ? await sensor.readLocation() : null;
  final GeoPoint userLocation = deviceLocation ?? manualZoneLocation;
  final WeatherCondition weather = await sensor.readWeather(userLocation);

  return FeedContext(
    context: RecommendationContextBuilder.build(
      profile: profile,
      now: ref.read(clockProvider)(),
      userLocation: userLocation,
      weather: weather,
      quickFilter: quickFilter,
    ),
    locationSource: deviceLocation == null
        ? LocationSourceKind.manualZone
        : LocationSourceKind.deviceGps,
  );
});

/// Lugares activos (con caché Offline-First).
final FutureProvider<List<Place>> placesProvider = FutureProvider<List<Place>>(
  (ref) => ref.watch(placeRepositoryProvider).getActivePlaces(),
);

/// Feed ordenado (RF-07).
///
/// El vector se lee una sola vez por cálculo (`ref.read`), así el orden no
/// salta mientras el usuario hace scroll; se recalcula al cambiar el filtro,
/// el contexto o al refrescar. Los descartes se ocultan de inmediato en la
/// pantalla (RF-12).
final FutureProvider<List<RecommendationResult>> feedProvider =
    FutureProvider.autoDispose<List<RecommendationResult>>((ref) async {
  final FeedContext feedContext = await ref.watch(feedContextProvider.future);
  await ref.watch(
    userProfileControllerProvider.selectAsync(
      (profile) => profile.onboardingCompletedAt,
    ),
  );
  final List<Place> places = await ref.watch(placesProvider.future);
  final UserProfile profile =
      await ref.read(userProfileControllerProvider.future);
  return ref.read(recommendationEngineProvider).rank(
        profile: profile,
        candidatePlaces: places,
        context: feedContext.context,
      );
});
