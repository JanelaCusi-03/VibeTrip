// Evaluación offline del recomendador para la sustentación (Entregable 5).
//
// Ejecutar y ver el reporte:
//   flutter test test/evaluation --reporter expanded
//
// 1. Precision@K con 5 perfiles sintéticos sobre los 18 lugares de Cusco,
//    comparado con una línea base que solo usa la distancia.
// 2. Latencia de ranking de 500 candidatos (RNF-01: p95 ≤ 150 ms).
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:vibetrip/core/domain/context_types.dart';
import 'package:vibetrip/core/domain/geo_distance.dart';
import 'package:vibetrip/core/domain/tag_catalog.dart';
import 'package:vibetrip/core/domain/tag_vector.dart';
import 'package:vibetrip/features/places/data/datasources/place_remote_data_source.dart';
import 'package:vibetrip/features/places/data/repositories/remote_place_repository.dart';
import 'package:vibetrip/features/places/domain/entities/place.dart';
import 'package:vibetrip/features/places/domain/entities/place_category.dart';
import 'package:vibetrip/features/profile/domain/entities/user_profile.dart';
import 'package:vibetrip/features/recommendation/domain/entities/recommendation_context.dart';
import 'package:vibetrip/features/recommendation/domain/services/recommendation_engine_service.dart';
import 'package:vibetrip/features/recommendation/domain/services/recommendation_metrics.dart';
import 'package:vibetrip/features/recommendation/domain/services/scoring/proximity_scoring_strategy.dart';
import 'package:vibetrip/features/recommendation/domain/services/scoring/scoring_strategy.dart';

import '../helpers/fixtures.dart';

/// Perfil sintético: gustos, contexto y categorías que el perfil considera
/// relevantes (verdad de referencia definida por categoría, no por etiquetas,
/// para no favorecer al motor).
class EvaluationPersona {
  const EvaluationPersona({
    required this.name,
    required this.preferences,
    required this.timeBucket,
    required this.companion,
    required this.budgetLevel,
    required this.relevantCategorySlugs,
  });

  final String name;
  final Map<String, double> preferences;
  final TimeBucket timeBucket;
  final CompanionType companion;
  final int budgetLevel;
  final Set<String> relevantCategorySlugs;
}

const List<EvaluationPersona> personas = <EvaluationPersona>[
  EvaluationPersona(
    name: 'Fiestero',
    preferences: <String, double>{
      'vida_nocturna': 1,
      'animado': 0.8,
      'musica_en_vivo': 0.7,
    },
    timeBucket: TimeBucket.night,
    companion: CompanionType.friends,
    budgetLevel: 2,
    relevantCategorySlugs: <String>{'bar', 'discoteca'},
  ),
  EvaluationPersona(
    name: 'Cultural',
    preferences: <String, double>{
      'historico': 1,
      'museo': 0.9,
      'cultural': 0.9,
      'arquitectura': 0.6,
    },
    timeBucket: TimeBucket.morning,
    companion: CompanionType.solo,
    budgetLevel: 3,
    relevantCategorySlugs: <String>{'museo', 'sitio_historico'},
  ),
  EvaluationPersona(
    name: 'Foodie económico',
    preferences: <String, double>{
      'comida_local': 1,
      'street_food': 0.8,
      'mercado': 0.6,
      'economico': 0.6,
    },
    timeBucket: TimeBucket.afternoon,
    companion: CompanionType.friends,
    budgetLevel: 1,
    relevantCategorySlugs: <String>{'restaurante', 'cafeteria'},
  ),
  EvaluationPersona(
    name: 'Pareja romántica',
    preferences: <String, double>{
      'romantico': 1,
      'vista_panoramica': 0.9,
      'para_parejas': 0.8,
    },
    timeBucket: TimeBucket.evening,
    companion: CompanionType.couple,
    budgetLevel: 3,
    relevantCategorySlugs: <String>{'mirador', 'bar', 'restaurante'},
  ),
  EvaluationPersona(
    name: 'Naturaleza y aventura',
    preferences: <String, double>{
      'naturaleza': 1,
      'aire_libre': 1,
      'aventura': 0.8,
    },
    timeBucket: TimeBucket.morning,
    companion: CompanionType.friends,
    budgetLevel: 2,
    relevantCategorySlugs: <String>{'aventura', 'mirador', 'parque'},
  ),
];

const int evaluatedK = 3;

/// Objetivo mínimo de calidad acordado para la sustentación.
const double minimumMeanPrecisionAtK = 0.70;

void main() {
  late List<Place> cuscoPlaces;

  setUpAll(() async {
    cuscoPlaces = await RemotePlaceRepository(
      SeedPlaceDataSource(
        () => File(SeedPlaceDataSource.assetPath).readAsString(),
      ),
    ).getActivePlaces();
  });

  RecommendationContext contextFor(EvaluationPersona persona) =>
      RecommendationContext(
        userLocation: plazaDeArmas,
        timeBucket: persona.timeBucket,
        weather: WeatherCondition.clear,
        budgetLevel: persona.budgetLevel,
        companion: persona.companion,
        searchRadiusInMeters: 5000,
      );

  double precisionFor(
    RecommendationEngineService engine,
    EvaluationPersona persona,
  ) {
    final List<String> rankedIds = engine
        .rank(
          profile: buildProfile(preferences: persona.preferences),
          candidatePlaces: cuscoPlaces,
          context: contextFor(persona),
        )
        .map((result) => result.place.id)
        .toList();
    final Set<String> relevantIds = cuscoPlaces
        .where(
          (place) =>
              persona.relevantCategorySlugs.contains(place.category.slug),
        )
        .map((place) => place.id)
        .toSet();
    return RecommendationMetrics.precisionAtK(
      rankedIds,
      relevantIds,
      evaluatedK,
    );
  }

  test('Precision@3: el motor híbrido supera a la línea base por distancia',
      () {
    final RecommendationEngineService hybridEngine =
        RecommendationEngineService();
    final RecommendationEngineService distanceOnlyBaseline =
        RecommendationEngineService(
      scoringStrategies: const <ScoringStrategy>[ProximityScoringStrategy()],
    );

    final StringBuffer report = StringBuffer()
      ..writeln()
      ..writeln(
        '| Perfil | P@$evaluatedK híbrido | P@$evaluatedK solo distancia |',
      )
      ..writeln('|---|---|---|');
    final List<double> hybridPrecisions = <double>[];
    final List<double> baselinePrecisions = <double>[];
    for (final EvaluationPersona persona in personas) {
      final double hybridPrecision = precisionFor(hybridEngine, persona);
      final double baselinePrecision =
          precisionFor(distanceOnlyBaseline, persona);
      hybridPrecisions.add(hybridPrecision);
      baselinePrecisions.add(baselinePrecision);
      report.writeln(
        '| ${persona.name} | ${hybridPrecision.toStringAsFixed(2)} | '
        '${baselinePrecision.toStringAsFixed(2)} |',
      );
    }
    final double meanHybrid = RecommendationMetrics.mean(hybridPrecisions);
    final double meanBaseline = RecommendationMetrics.mean(baselinePrecisions);
    report.writeln(
      '| **Media** | **${meanHybrid.toStringAsFixed(2)}** | '
      '**${meanBaseline.toStringAsFixed(2)}** |',
    );
    // ignore: avoid_print
    print(report);

    expect(meanHybrid, greaterThanOrEqualTo(minimumMeanPrecisionAtK));
    expect(meanHybrid, greaterThan(meanBaseline));
  });

  test('Latencia: ranking de 500 candidatos con p95 ≤ 150 ms (RNF-01)', () {
    final math.Random random = math.Random(42);
    final List<PlaceCategory> categories =
        PlaceCategoryCatalog.all.where((category) => !category.isRoot).toList();
    final List<Place> syntheticCandidates = List<Place>.generate(500, (index) {
      final Map<String, double> tagWeights = <String, double>{
        for (int tag = 0; tag < 6; tag++)
          TagCatalog.byIndex(random.nextInt(TagCatalog.dimension)).slug:
              random.nextDouble(),
      };
      return Place(
        id: 'synthetic-$index',
        name: 'Lugar $index',
        category: categories[random.nextInt(categories.length)],
        location: GeoPoint(
          latitude: plazaDeArmas.latitude + (random.nextDouble() - 0.5) * 0.04,
          longitude:
              plazaDeArmas.longitude + (random.nextDouble() - 0.5) * 0.04,
        ),
        priceLevel: 1 + random.nextInt(4),
        tagVector: TagVector.fromTagWeights(tagWeights),
        isOutdoor: random.nextBool(),
        bestTimeBuckets: <TimeBucket>{
          TimeBucket.values[random.nextInt(TimeBucket.values.length)],
        },
        companionFit: <CompanionType>{
          CompanionType.values[random.nextInt(CompanionType.values.length)],
        },
      );
    });
    final UserProfile profile = buildProfile(
      preferences: personas.first.preferences,
    );
    final RecommendationEngineService engine = RecommendationEngineService();
    final RecommendationContext context = contextFor(personas.first);

    // Calentamiento del JIT antes de medir.
    for (int run = 0; run < 5; run++) {
      engine.rank(
        profile: profile,
        candidatePlaces: syntheticCandidates,
        context: context,
      );
    }
    final List<Duration> samples = <Duration>[];
    for (int run = 0; run < 100; run++) {
      final Stopwatch stopwatch = Stopwatch()..start();
      engine.rank(
        profile: profile,
        candidatePlaces: syntheticCandidates,
        context: context,
      );
      samples.add(stopwatch.elapsed);
    }
    final Duration p50 = RecommendationMetrics.percentile(samples, 50);
    final Duration p95 = RecommendationMetrics.percentile(samples, 95);
    // ignore: avoid_print
    print(
      '\nLatencia ranking 500 candidatos (100 corridas): '
      'p50 = ${p50.inMicroseconds / 1000} ms, '
      'p95 = ${p95.inMicroseconds / 1000} ms',
    );

    expect(p95, lessThanOrEqualTo(const Duration(milliseconds: 150)));
  });
}
