import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vibetrip/core/domain/context_types.dart';
import 'package:vibetrip/core/domain/geo_distance.dart';
import 'package:vibetrip/core/domain/tag_vector.dart';
import 'package:vibetrip/features/places/data/datasources/place_remote_data_source.dart';
import 'package:vibetrip/features/places/data/repositories/remote_place_repository.dart';
import 'package:vibetrip/features/places/domain/entities/place.dart';
import 'package:vibetrip/features/profile/domain/entities/user_profile.dart';
import 'package:vibetrip/features/recommendation/domain/entities/recommendation_context.dart';
import 'package:vibetrip/features/recommendation/domain/entities/recommendation_result.dart';
import 'package:vibetrip/features/recommendation/domain/services/recommendation_engine_service.dart';
import 'package:vibetrip/features/recommendation/domain/services/recommendation_explainer.dart';
import 'package:vibetrip/features/recommendation/domain/services/scoring/affinity_scoring_strategy.dart';
import 'package:vibetrip/features/recommendation/domain/services/scoring/context_scoring_strategy.dart';
import 'package:vibetrip/features/recommendation/domain/services/scoring/proximity_scoring_strategy.dart';
import 'package:vibetrip/features/recommendation/domain/services/scoring/scoring_strategy.dart';

import '../../helpers/fixtures.dart';

/// Punto a [distanceInMeters] al norte de la Plaza de Armas (sobre el
/// meridiano la distancia de Haversine es exactamente R·Δφ).
GeoPoint pointNorthOfPlaza(double distanceInMeters) => GeoPoint(
      latitude: plazaDeArmas.latitude +
          distanceInMeters /
              (earthMeanRadiusInMeters * 3.141592653589793 / 180),
      longitude: plazaDeArmas.longitude,
    );

const RecommendationContext eveningCoupleContext = RecommendationContext(
  userLocation: plazaDeArmas,
  timeBucket: TimeBucket.evening,
  weather: WeatherCondition.clear,
  budgetLevel: 2,
  companion: CompanionType.couple,
  searchRadiusInMeters: 3000,
);

void main() {
  final RecommendationEngineService engine = RecommendationEngineService();

  group('Ejemplo numérico del Entregable 2 §3.4', () {
    final UserProfile calmOutdoorUser = buildProfile(
      preferences: <String, double>{'tranquilo': 0.8, 'aire_libre': 0.6},
    );
    final Place mirador = buildPlace(
      id: 'mirador',
      name: 'Mirador',
      location: pointNorthOfPlaza(1200),
      tagWeights: <String, double>{
        'tranquilo': 0.9,
        'animado': 0.1,
        'aire_libre': 1.0,
      },
      isOutdoor: true,
      bestTimeBuckets: <TimeBucket>{TimeBucket.afternoon, TimeBucket.evening},
      companionFit: <CompanionType>{CompanionType.couple, CompanionType.family},
    );
    final Place discoteca = buildPlace(
      id: 'discoteca',
      name: 'Discoteca',
      categorySlug: 'discoteca',
      location: pointNorthOfPlaza(300),
      priceLevel: 2,
      tagWeights: <String, double>{'animado': 1.0},
      bestTimeBuckets: <TimeBucket>{TimeBucket.night},
      companionFit: <CompanionType>{CompanionType.friends},
    );

    late List<RecommendationResult> ranking;

    setUpAll(() {
      ranking = engine.rank(
        profile: calmOutdoorUser,
        candidatePlaces: <Place>[discoteca, mirador],
        context: eveningCoupleContext,
      );
    });

    test('el mirador obtiene 90 % y la discoteca 29 %', () {
      expect(ranking.map((result) => result.place.id), <String>[
        'mirador',
        'discoteca',
      ]);
      expect(ranking.first.matchScore, 90);
      expect(ranking.last.matchScore, 29);
    });

    test('los factores coinciden con la tabla del documento', () {
      final Map<String, double> miradorFactors = ranking.first.factorScores;
      expect(miradorFactors['affinity'], closeTo(0.9784, 1e-4));
      expect(miradorFactors['proximity'], closeTo(0.5743, 1e-4));
      expect(miradorFactors['context'], closeTo(1.0, 1e-9));

      final Map<String, double> discotecaFactors = ranking.last.factorScores;
      expect(discotecaFactors['affinity'], 0);
      expect(discotecaFactors['proximity'], closeTo(0.8706, 1e-4));
      expect(discotecaFactors['context'], closeTo(0.575, 1e-9));
      expect(ranking.first.distanceInMeters, closeTo(1200, 0.01));
    });

    test('la explicación menciona gustos, distancia y franja horaria', () {
      expect(
        ranking.first.explanation,
        'Recomendado porque te gusta: Tranquilo y Aire libre · a 1.2 km · '
        'ideal para esta hora',
      );
      expect(
        ranking.last.explanation,
        'Recomendado por tu contexto · a 300 m · dentro de tu presupuesto',
      );
    });
  });

  group('Filtros y exclusiones', () {
    final UserProfile anyUser = buildProfile(
      preferences: <String, double>{'tranquilo': 1},
    );

    test('excluye descartados (RF-12), inactivos y fuera del radio', () {
      final List<RecommendationResult> ranking = engine.rank(
        profile: anyUser.copyWith(discardedPlaceIds: <String>{'descartado'}),
        candidatePlaces: <Place>[
          buildPlace(id: 'ok'),
          buildPlace(id: 'descartado'),
          buildPlace(id: 'inactivo', isActive: false),
          buildPlace(id: 'lejos', location: pointNorthOfPlaza(3500)),
        ],
        context: eveningCoupleContext,
      );
      expect(ranking.map((result) => result.place.id), <String>['ok']);
    });

    test('el filtro «Económico» aplica un tope de precio', () {
      final List<RecommendationResult> ranking = engine.rank(
        profile: anyUser,
        candidatePlaces: <Place>[
          buildPlace(id: 'barato', priceLevel: 1),
          buildPlace(id: 'caro', priceLevel: 4),
        ],
        context: eveningCoupleContext.copyWith(maximumPriceLevel: 2),
      );
      expect(ranking.single.place.id, 'barato');
    });

    test('sin ubicación no filtra por distancia y usa proximidad neutra', () {
      const RecommendationContext withoutLocation = RecommendationContext(
        timeBucket: TimeBucket.morning,
        budgetLevel: 2,
        companion: CompanionType.solo,
        searchRadiusInMeters: 1000,
      );
      final List<RecommendationResult> ranking = engine.rank(
        profile: anyUser,
        candidatePlaces: <Place>[
          buildPlace(id: 'lejos', location: pointNorthOfPlaza(9000)),
        ],
        context: withoutLocation,
      );
      expect(ranking.single.distanceInMeters, isNull);
      expect(
        ranking.single.factorScores['proximity'],
        ProximityScoringStrategy.unknownLocationScore,
      );
    });

    test('limit recorta y los empates se ordenan por distancia y nombre', () {
      final List<RecommendationResult> ranking = engine.rank(
        profile: anyUser,
        candidatePlaces: <Place>[
          buildPlace(id: 'b', name: 'B'),
          buildPlace(id: 'a', name: 'A'),
          buildPlace(id: 'c', name: 'C'),
        ],
        context: eveningCoupleContext,
        limit: 2,
      );
      expect(ranking.map((result) => result.place.name), <String>['A', 'B']);
    });

    test('un usuario sin gustos se recomienda solo por contexto', () {
      final List<RecommendationResult> ranking = engine.rank(
        profile: UserProfile.initial(id: 'nuevo'),
        candidatePlaces: <Place>[buildPlace()],
        context: eveningCoupleContext,
      );
      expect(ranking.single.factorScores['affinity'], 0);
      expect(
        ranking.single.explanation,
        startsWith('Recomendado por tu contexto'),
      );
    });

    test('rechaza estrategias cuya suma de pesos es 0', () {
      expect(
        () => RecommendationEngineService(
          scoringStrategies: const <ScoringStrategy>[
            AffinityScoringStrategy(weight: 0),
          ],
        ),
        throwsArgumentError,
      );
    });
  });

  group('ContextScoringStrategy', () {
    test('presupuesto: 1 nivel de exceso vale 0.5 y 2 niveles 0.25', () {
      expect(
        ContextScoringStrategy.scoreBudget(buildPlace(priceLevel: 3), 2),
        0.5,
      );
      expect(
        ContextScoringStrategy.scoreBudget(buildPlace(priceLevel: 4), 2),
        0.25,
      );
      expect(
        ContextScoringStrategy.scoreBudget(buildPlace(priceLevel: 1), 2),
        1,
      );
    });

    test('franja y compañía sin dato valen 0.6', () {
      expect(
        ContextScoringStrategy.scoreTimeBucket(buildPlace(), TimeBucket.night),
        0.6,
      );
      expect(
        ContextScoringStrategy.scoreCompanion(buildPlace(), CompanionType.solo),
        0.6,
      );
    });

    test('tabla de clima para exterior e interior', () {
      final Place outdoor = buildPlace(isOutdoor: true);
      final Place indoor = buildPlace();
      final Map<WeatherCondition, double> expectedOutdoor =
          <WeatherCondition, double>{
        WeatherCondition.clear: 1.0,
        WeatherCondition.cloudy: 0.8,
        WeatherCondition.hot: 0.7,
        WeatherCondition.cold: 0.4,
        WeatherCondition.rain: 0.2,
        WeatherCondition.unknown: 0.8,
      };
      expectedOutdoor.forEach((weather, expectedScore) {
        expect(
          ContextScoringStrategy.scoreWeather(outdoor, weather),
          expectedScore,
        );
      });
      expect(
        ContextScoringStrategy.scoreWeather(indoor, WeatherCondition.rain),
        1.0,
      );
      expect(
        ContextScoringStrategy.scoreWeather(indoor, WeatherCondition.cold),
        1.0,
      );
      expect(
        ContextScoringStrategy.scoreWeather(indoor, WeatherCondition.clear),
        0.8,
      );
    });
  });

  group('RecommendationExplainer', () {
    test('formatDistance redondea metros y kilómetros', () {
      expect(RecommendationExplainer.formatDistance(647), 'a 650 m');
      expect(RecommendationExplainer.formatDistance(1234), 'a 1.2 km');
    });

    test('con una sola etiqueta no usa conjunción', () {
      final String explanation = const RecommendationExplainer().explain(
        userVector: TagVector.fromTagWeights(<String, double>{'bar': 1}),
        place:
            buildPlace(tagWeights: <String, double>{'bar': 1}, priceLevel: 4),
        context: eveningCoupleContext,
      );
      expect(explanation, 'Recomendado porque te gusta: Bar');
    });
  });

  group('Perfiles sobre el seed real de Cusco', () {
    late List<Place> cuscoPlaces;

    setUpAll(() async {
      cuscoPlaces = await RemotePlaceRepository(
        SeedPlaceDataSource(
          () => File(SeedPlaceDataSource.assetPath).readAsString(),
        ),
      ).getActivePlaces();
    });

    List<String> topCategorySlugs(
      Map<String, double> preferences,
      RecommendationContext context, {
      int count = 3,
    }) =>
        engine
            .rank(
              profile: buildProfile(preferences: preferences),
              candidatePlaces: cuscoPlaces,
              context: context,
              limit: count,
            )
            .map((result) => result.place.category.slug)
            .toList();

    test('perfil fiestero de noche con amigos → bares y discotecas', () {
      final List<String> categories = topCategorySlugs(
        <String, double>{'vida_nocturna': 1, 'animado': 0.8, 'bar': 0.7},
        eveningCoupleContext.copyWith(
          timeBucket: TimeBucket.night,
          companion: CompanionType.friends,
        ),
      );
      expect(categories, everyElement(isIn(<String>['bar', 'discoteca'])));
    });

    test('perfil cultural de mañana → museos y sitios históricos', () {
      final List<String> categories = topCategorySlugs(
        <String, double>{'historico': 1, 'museo': 0.9, 'cultural': 0.9},
        eveningCoupleContext.copyWith(
          timeBucket: TimeBucket.morning,
          companion: CompanionType.solo,
        ),
      );
      expect(
        categories,
        everyElement(isIn(<String>['museo', 'sitio_historico'])),
      );
    });

    test('perfil foodie económico → restaurantes y mercado', () {
      final List<String> categories = topCategorySlugs(
        <String, double>{
          'comida_local': 1,
          'street_food': 0.8,
          'economico': 0.7,
        },
        eveningCoupleContext.copyWith(
          timeBucket: TimeBucket.afternoon,
          budgetLevel: 1,
        ),
        count: 2,
      );
      expect(categories, everyElement('restaurante'));
    });
  });
}
