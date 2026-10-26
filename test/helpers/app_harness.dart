import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibetrip/app.dart';
import 'package:vibetrip/core/domain/context_types.dart';
import 'package:vibetrip/core/domain/geo_distance.dart';
import 'package:vibetrip/core/providers/core_providers.dart';
import 'package:vibetrip/core/providers/dependency_providers.dart';
import 'package:vibetrip/features/places/domain/entities/place.dart';
import 'package:vibetrip/features/places/domain/repositories/place_repository.dart';
import 'package:vibetrip/features/recommendation/domain/services/recommendation_context_builder.dart';

import 'fixtures.dart';

class FakePlaceRepository implements PlaceRepository {
  FakePlaceRepository(this.places);

  final List<Place> places;

  @override
  Future<List<Place>> getActivePlaces({bool forceRefresh = false}) async =>
      places;

  @override
  Future<Place?> getPlaceById(String placeId) async =>
      places.where((place) => place.id == placeId).firstOrNull;
}

/// Sensor sin GPS ni red: siempre en la Plaza de Armas con cielo despejado.
class FakeContextSensor implements ContextSensor {
  @override
  Future<GeoPoint?> readLocation() async => plazaDeArmas;

  @override
  Future<WeatherCondition> readWeather(GeoPoint location) async =>
      WeatherCondition.clear;
}

/// Lugares de prueba cerca de la plaza.
final List<Place> testPlaces = <Place>[
  buildPlace(
    id: 'mirador',
    name: 'Mirador de prueba',
    tagWeights: <String, double>{'vista_panoramica': 1, 'tranquilo': 0.8},
    isOutdoor: true,
    bestTimeBuckets: <TimeBucket>{TimeBucket.evening},
  ),
  buildPlace(
    id: 'restaurante',
    name: 'Restaurante caro',
    categorySlug: 'restaurante',
    priceLevel: 4,
    tagWeights: <String, double>{'fine_dining': 1, 'elegante': 0.8},
  ),
  buildPlace(
    id: 'bar',
    name: 'Bar de prueba',
    categorySlug: 'bar',
    priceLevel: 2,
    tagWeights: <String, double>{'bar': 1, 'musica_en_vivo': 0.8},
  ),
];

/// Monta la app completa con dependencias falsas (DI con overrides).
Future<void> pumpVibeTrip(WidgetTester tester) async {
  // Pantalla alta para que todas las tarjetas de prueba estén construidas.
  tester.view.physicalSize = const Size(1080, 3200);
  tester.view.devicePixelRatio = 1.5;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues(<String, Object>{});
  final SharedPreferences preferences = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        placeRepositoryProvider
            .overrideWithValue(FakePlaceRepository(testPlaces)),
        contextSensorProvider.overrideWithValue(FakeContextSensor()),
        clockProvider.overrideWithValue(() => DateTime(2026, 10, 24, 19)),
      ],
      child: const VibeTripApp(),
    ),
  );
  await tester.pumpAndSettle();
}
