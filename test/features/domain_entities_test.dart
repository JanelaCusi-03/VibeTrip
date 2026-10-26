import 'package:flutter_test/flutter_test.dart';
import 'package:vibetrip/core/domain/context_types.dart';
import 'package:vibetrip/core/domain/geo_distance.dart';
import 'package:vibetrip/core/domain/tag_catalog.dart';
import 'package:vibetrip/core/domain/tag_vector.dart';
import 'package:vibetrip/core/domain/tag_weight.dart';
import 'package:vibetrip/features/places/domain/entities/place_category.dart';
import 'package:vibetrip/features/profile/domain/entities/user_profile.dart';
import 'package:vibetrip/features/recommendation/domain/entities/recommendation_context.dart';
import 'package:vibetrip/features/recommendation/domain/entities/recommendation_result.dart';
import 'package:vibetrip/features/telemetry/domain/entities/interaction_event.dart';
import 'package:vibetrip/features/telemetry/domain/entities/interaction_type.dart';
import 'package:vibetrip/features/telemetry/domain/services/signal_weight_policy.dart';

import '../helpers/fixtures.dart';

void main() {
  group('TagWeight', () {
    test('rankedFromVector ordena de mayor a menor y omite ceros', () {
      final List<TagWeight> ranked = TagWeight.rankedFromVector(
        TagVector.fromTagWeights(<String, double>{'bar': 0.4, 'arte': 0.9}),
      );
      expect(ranked.map((tagWeight) => tagWeight.tag.slug), <String>[
        'arte',
        'bar',
      ]);
      expect(
        ranked.first,
        TagWeight(tag: TagCatalog.bySlug('arte'), weight: 0.9),
      );
      expect(ranked.first.hashCode, isNot(ranked.last.hashCode));
      expect(ranked.first.toString(), 'TagWeight(arte: 0.9)');
    });
  });

  group('PlaceCategoryCatalog', () {
    test('resuelve subcategorías y su raíz', () {
      final PlaceCategory mirador = PlaceCategoryCatalog.bySlug('mirador');
      expect(mirador.isRoot, isFalse);
      expect(PlaceCategoryCatalog.rootOf(mirador).slug, 'turismo_cultura');
      expect(
        PlaceCategoryCatalog.rootOf(PlaceCategoryCatalog.bySlug('gastronomia'))
            .slug,
        'gastronomia',
      );
      expect(mirador, PlaceCategoryCatalog.bySlug('mirador'));
      expect(mirador.hashCode, 'mirador'.hashCode);
      expect(mirador.toString(), 'PlaceCategory(mirador)');
    });

    test('rechaza categorías desconocidas', () {
      expect(
        () => PlaceCategoryCatalog.bySlug('zoologico'),
        throwsArgumentError,
      );
    });
  });

  group('Place', () {
    test('expone sus etiquetas principales e identidad por id', () {
      final place = buildPlace(
        tagWeights: <String, double>{
          'vista_panoramica': 1,
          'fotografico': 0.9,
          'economico': 0.8,
          'tranquilo': 0.2,
        },
      );
      expect(
        place.topTagWeights().map((tagWeight) => tagWeight.tag.slug),
        <String>['vista_panoramica', 'fotografico', 'economico'],
      );
      expect(place, buildPlace(name: 'Otro nombre'));
      expect(place.hashCode, 'place-1'.hashCode);
      expect(place.toString(), 'Place(place-1, Lugar de prueba)');
    });

    test('valida price_level entre 1 y 4', () {
      expect(() => buildPlace(priceLevel: 5), throwsArgumentError);
    });
  });

  group('UserProfile', () {
    test('initial arranca sin onboarding ni consentimiento (RNF-09)', () {
      final UserProfile profile = UserProfile.initial(id: 'u1');
      expect(profile.hasCompletedOnboarding, isFalse);
      expect(profile.hasTelemetryConsent, isFalse);
      expect(profile.currentVector.isZero, isTrue);
      expect(profile.defaultBudgetLevel, 2);
      expect(profile.searchRadiusInMeters, 3000);
    });

    test('copyWith conserva lo no indicado y marca favoritos/descartes', () {
      final UserProfile profile = UserProfile.initial(id: 'u1').copyWith(
        favoritePlaceIds: <String>{'p1'},
        discardedPlaceIds: <String>{'p2'},
        onboardingCompletedAt: DateTime(2026, 10, 1),
        version: 3,
      );
      expect(profile.isFavorite('p1'), isTrue);
      expect(profile.isDiscarded('p2'), isTrue);
      expect(profile.hasCompletedOnboarding, isTrue);
      expect(profile.displayName, 'Viajero');
      expect(profile, profile.copyWith());
      expect(profile.hashCode, profile.copyWith().hashCode);
      expect(profile.toString(), 'UserProfile(u1, v3)');
    });

    test('resetPreferences borra gustos y descartes pero no favoritos', () {
      final UserProfile profile = buildProfile(
        preferences: <String, double>{'bar': 1},
      ).copyWith(
        favoritePlaceIds: <String>{'p1'},
        discardedPlaceIds: <String>{'p2'},
        onboardingCompletedAt: DateTime(2026),
      );
      final UserProfile reset = profile.resetPreferences();
      expect(reset.currentVector.isZero, isTrue);
      expect(reset.hasCompletedOnboarding, isFalse);
      expect(reset.discardedPlaceIds, isEmpty);
      expect(reset.favoritePlaceIds, <String>{'p1'});
      expect(reset.version, profile.version + 1);
    });

    test('valida presupuesto y radio', () {
      expect(
        () => UserProfile.initial(id: 'u1').copyWith(defaultBudgetLevel: 0),
        throwsArgumentError,
      );
      expect(
        () => UserProfile.initial(id: 'u1').copyWith(searchRadiusInMeters: 10),
        throwsArgumentError,
      );
    });
  });

  group('SignalWeightPolicy', () {
    test('dwell bajo t_min vale 0', () {
      expect(SignalWeightPolicy.computeDwellSignalWeight(1999), 0);
    });

    test('dwell de 8 s vale 0.60·(1 − e⁻¹) ≈ 0.379 (Entregable 2 §4.1)', () {
      expect(
        SignalWeightPolicy.computeDwellSignalWeight(8000),
        closeTo(0.3793, 1e-4),
      );
    });

    test('dwell satura en w_max', () {
      expect(
        SignalWeightPolicy.computeDwellSignalWeight(120000),
        closeTo(0.60, 1e-6),
      );
    });
  });

  group('InteractionEvent', () {
    final DateTime occurredAt = DateTime.utc(2026, 10, 24, 20);

    test('fromViewDuration < 1 s produce impression_skip', () {
      final InteractionEvent event = InteractionEvent.fromViewDuration(
        eventId: 'e1',
        userId: 'u1',
        placeId: 'p1',
        sessionId: 's1',
        visibleDuration: const Duration(milliseconds: 600),
        occurredAt: occurredAt,
      );
      expect(event.type, InteractionType.impressionSkip);
      expect(event.signalWeight, -0.05);
      expect(event.channel, CaptureChannel.implicit);
    });

    test('fromViewDuration ≥ 1 s produce dwell con su peso', () {
      final InteractionEvent event = InteractionEvent.fromViewDuration(
        eventId: 'e2',
        userId: 'u1',
        placeId: 'p1',
        sessionId: 's1',
        visibleDuration: const Duration(seconds: 8),
        occurredAt: occurredAt,
      );
      expect(event.type, InteractionType.dwell);
      expect(event.dwellInMilliseconds, 8000);
      expect(event.signalWeight, closeTo(0.3793, 1e-4));
      expect(event.toString(), contains('dwell'));
    });

    test('create usa el peso base del tipo y rechaza dwell', () {
      final InteractionEvent event = InteractionEvent.create(
        eventId: 'e3',
        userId: 'u1',
        placeId: 'p1',
        sessionId: 's1',
        type: InteractionType.favoriteAdd,
        occurredAt: occurredAt,
      );
      expect(event.signalWeight, 1.0);
      expect(event.channel, CaptureChannel.explicit);
      expect(
        () => InteractionEvent.create(
          eventId: 'e4',
          userId: 'u1',
          placeId: 'p1',
          sessionId: 's1',
          type: InteractionType.dwell,
          occurredAt: occurredAt,
        ),
        throwsArgumentError,
      );
    });

    test('restore valida rango del peso y duración de dwell', () {
      expect(
        () => InteractionEvent.restore(
          eventId: 'e5',
          userId: 'u1',
          placeId: 'p1',
          sessionId: 's1',
          type: InteractionType.share,
          signalWeight: 2,
          occurredAt: occurredAt,
        ),
        throwsArgumentError,
      );
      expect(
        () => InteractionEvent.restore(
          eventId: 'e6',
          userId: 'u1',
          placeId: 'p1',
          sessionId: 's1',
          type: InteractionType.dwell,
          signalWeight: 0.2,
          occurredAt: occurredAt,
        ),
        throwsArgumentError,
      );
    });

    test('la identidad es el event_id (idempotencia)', () {
      InteractionEvent build(InteractionType type) => InteractionEvent.create(
            eventId: 'same',
            userId: 'u1',
            placeId: 'p1',
            sessionId: 's1',
            type: type,
            occurredAt: occurredAt,
          );
      expect(build(InteractionType.share), build(InteractionType.discard));
      expect(build(InteractionType.share).hashCode, 'same'.hashCode);
    });

    test('InteractionType se traduce desde el ENUM SQL', () {
      expect(
        InteractionType.fromWireName('directions_click'),
        InteractionType.directionsClick,
      );
      expect(InteractionType.discard.isImplicit, isFalse);
    });
  });

  group('RecommendationContext y RecommendationResult', () {
    test('toSnapshot serializa el contexto para el log', () {
      const RecommendationContext context = RecommendationContext(
        userLocation: GeoPoint(latitude: -13.5, longitude: -71.9),
        timeBucket: TimeBucket.evening,
        weather: WeatherCondition.clear,
        budgetLevel: 2,
        companion: CompanionType.couple,
        searchRadiusInMeters: 3000,
      );
      expect(context.toSnapshot(), <String, Object?>{
        'lat': -13.5,
        'lon': -71.9,
        'time_bucket': 'evening',
        'weather': 'clear',
        'budget': 2,
        'companion': 'couple',
      });
      final RecommendationContext economic = context.copyWith(
        maximumPriceLevel: 2,
        searchRadiusInMeters: 1000,
      );
      expect(economic.maximumPriceLevel, 2);
      expect(economic.searchRadiusInMeters, 1000);
      expect(economic.companion, CompanionType.couple);
    });

    test('RecommendationResult describe el lugar y su puntaje', () {
      final RecommendationResult result = RecommendationResult(
        place: buildPlace(name: 'Mirador'),
        matchScore: 90,
        explanation: 'Recomendado',
        factorScores: const <String, double>{'affinity': 0.97},
      );
      expect(result.toString(), 'RecommendationResult(Mirador, 90 %)');
    });
  });
}
