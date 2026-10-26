import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibetrip/core/domain/tag_catalog.dart';
import 'package:vibetrip/core/domain/tag_vector.dart';
import 'package:vibetrip/features/places/domain/entities/place.dart';
import 'package:vibetrip/features/profile/data/local_user_profile_repository.dart';
import 'package:vibetrip/features/profile/domain/entities/user_profile.dart';
import 'package:vibetrip/features/telemetry/data/interaction_remote_data_source.dart';
import 'package:vibetrip/features/telemetry/data/local_interaction_queue.dart';
import 'package:vibetrip/features/telemetry/data/queued_interaction_repository.dart';
import 'package:vibetrip/features/telemetry/domain/entities/interaction_event.dart';
import 'package:vibetrip/features/telemetry/domain/entities/interaction_type.dart';
import 'package:vibetrip/features/telemetry/domain/services/dwell_stopwatch.dart';
import 'package:vibetrip/features/telemetry/domain/services/preference_vector_updater.dart';
import 'package:vibetrip/features/telemetry/domain/services/telemetry_service.dart';

import '../../helpers/fixtures.dart';

int indexOf(String slug) => TagCatalog.bySlug(slug).vectorIndex;

void main() {
  const PreferenceVectorUpdater updater = PreferenceVectorUpdater();

  group('PreferenceVectorUpdater', () {
    test('favorite_add sobre el mirador reproduce el Entregable 2 §4.2', () {
      final TagVector updated = updater.applySignal(
        currentVector: TagVector.fromTagWeights(<String, double>{
          'tranquilo': 0.8,
          'aire_libre': 0.6,
        }),
        placeVector: TagVector.fromTagWeights(<String, double>{
          'tranquilo': 0.9,
          'animado': 0.1,
          'aire_libre': 1.0,
        }),
        signalWeight: 1,
      );
      expect(updated[indexOf('tranquilo')], closeTo(0.935, 1e-9));
      expect(updated[indexOf('aire_libre')], closeTo(0.75, 1e-9));
      expect(updated[indexOf('animado')], closeTo(0.015, 1e-9));
    });

    test('nunca sale de [-1, 1]', () {
      final TagVector updated = updater.applySignal(
        currentVector: TagVector.fromTagWeights(<String, double>{'bar': -0.95}),
        placeVector: TagVector.fromTagWeights(<String, double>{'bar': 1}),
        signalWeight: -1,
      );
      expect(updated[indexOf('bar')], -1);
    });

    test('el tope por sesión limita |Σs| a 1.5', () {
      expect(
        updater.capSessionSignal(accumulatedSignal: 1.0, signalWeight: 0.9),
        closeTo(0.5, 1e-9),
      );
      expect(
        updater.capSessionSignal(accumulatedSignal: 1.5, signalWeight: 1),
        0,
      );
      expect(
        updater.capSessionSignal(accumulatedSignal: -1.2, signalWeight: -1),
        closeTo(-0.3, 1e-9),
      );
    });

    test('olvido temporal: tras 30 días la deriva se reduce a la mitad', () {
      final DateTime start = DateTime.utc(2026, 9, 1);
      final UserProfile profile = buildProfile(
        preferences: <String, double>{'museo': 0.2},
      ).copyWith(
        currentVector: TagVector.fromTagWeights(<String, double>{
          'museo': 0.2,
          'bar': 0.8,
        }),
        lastDecayAppliedAt: start,
      );
      final UserProfile decayed = updater.applyTemporalDecay(
        profile,
        start.add(const Duration(days: 30)),
      );
      expect(decayed.currentVector[indexOf('bar')], closeTo(0.4, 1e-9));
      expect(decayed.currentVector[indexOf('museo')], closeTo(0.2, 1e-9));
      expect(decayed.lastDecayAppliedAt, start.add(const Duration(days: 30)));
    });

    test('la primera vez solo registra la fecha', () {
      final DateTime now = DateTime.utc(2026, 10, 24);
      final UserProfile profile = buildProfile(
        preferences: <String, double>{'bar': 1},
      );
      final UserProfile decayed = updater.applyTemporalDecay(profile, now);
      expect(decayed.currentVector, profile.currentVector);
      expect(decayed.lastDecayAppliedAt, now);
    });
  });

  group('DwellStopwatch', () {
    final DateTime t0 = DateTime.utc(2026, 10, 24, 20);
    DateTime at(int milliseconds) =>
        t0.add(Duration(milliseconds: milliseconds));

    test('mide solo con ≥ 50 % visible', () {
      final DwellStopwatch stopwatch = DwellStopwatch();
      expect(stopwatch.onVisibilityChanged(0.3, at(0)), isNull);
      expect(stopwatch.isRunning, isFalse);
      expect(stopwatch.onVisibilityChanged(0.6, at(100)), isNull);
      expect(stopwatch.onVisibilityChanged(1.0, at(500)), isNull);
      expect(
        stopwatch.onVisibilityChanged(0.4, at(4100)),
        const Duration(milliseconds: 4000),
      );
    });

    test('se pausa cuando la app pasa a segundo plano', () {
      final DwellStopwatch stopwatch = DwellStopwatch();
      stopwatch.onVisibilityChanged(1, at(0));
      expect(
        stopwatch.onAppLifecycleChanged(isInForeground: false, now: at(3000)),
        const Duration(seconds: 3),
      );
      expect(
        stopwatch.onAppLifecycleChanged(isInForeground: true, now: at(9000)),
        isNull,
      );
      expect(stopwatch.stop(at(10000)), const Duration(seconds: 1));
      expect(stopwatch.stop(at(11000)), isNull);
    });
  });

  group('TelemetryService', () {
    late LocalUserProfileRepository profileRepository;
    late QueuedInteractionRepository interactionRepository;
    late TelemetryService service;
    late int eventCounter;
    final Place mirador = buildPlace(
      id: 'mirador',
      tagWeights: <String, double>{'vista_panoramica': 1},
    );

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();
      profileRepository = LocalUserProfileRepository(preferences);
      interactionRepository = QueuedInteractionRepository(
        queue: LocalInteractionQueue(preferences),
        remoteDataSource: const LocalOnlyInteractionRemoteDataSource(),
      );
      eventCounter = 0;
      service = TelemetryService(
        profileRepository: profileRepository,
        interactionRepository: interactionRepository,
        generateEventId: () => 'event-${eventCounter++}',
        clock: () => DateTime.utc(2026, 10, 24, 20),
        sessionId: 'session-1',
        flushThreshold: 3,
      );
    });

    test('favorito: aprende, guarda perfil y encola el evento', () async {
      final UserProfile updated = await service.recordInteraction(
        profile: buildProfile(),
        place: mirador,
        type: InteractionType.favoriteAdd,
        matchScore: 80,
      );
      expect(updated.isFavorite('mirador'), isTrue);
      expect(updated.currentVector[indexOf('vista_panoramica')], 0.15);
      expect(updated.interactionCount, 1);
      expect(updated.version, 2);
      expect((await profileRepository.loadProfile())?.version, 2);
      expect(await interactionRepository.pendingCount(), 1);
    });

    test('quitar favorito y descartar (RF-11, RF-12)', () async {
      UserProfile profile = await service.recordInteraction(
        profile: buildProfile(),
        place: mirador,
        type: InteractionType.favoriteAdd,
      );
      profile = await service.recordInteraction(
        profile: profile,
        place: mirador,
        type: InteractionType.favoriteRemove,
      );
      expect(profile.isFavorite('mirador'), isFalse);

      profile = await service.recordInteraction(
        profile: profile,
        place: mirador,
        type: InteractionType.discard,
      );
      expect(profile.isDiscarded('mirador'), isTrue);
    });

    test('sin consentimiento ignora señales implícitas (RNF-09)', () async {
      final UserProfile withoutConsent = buildProfile(
        hasTelemetryConsent: false,
      );
      final UserProfile result = await service.recordViewDuration(
        profile: withoutConsent,
        place: mirador,
        visibleDuration: const Duration(seconds: 8),
      );
      expect(identical(result, withoutConsent), isTrue);
      expect(await interactionRepository.pendingCount(), 0);
    });

    test('dwell con consentimiento suma su peso', () async {
      final UserProfile updated = await service.recordViewDuration(
        profile: buildProfile(),
        place: mirador,
        visibleDuration: const Duration(seconds: 8),
      );
      expect(
        updated.currentVector[indexOf('vista_panoramica')],
        closeTo(0.15 * 0.3793, 1e-4),
      );
    });

    test('aplica el tope de sesión por lugar', () async {
      UserProfile profile = buildProfile();
      for (int repetition = 0; repetition < 3; repetition++) {
        profile = await service.recordInteraction(
          profile: profile,
          place: mirador,
          type: InteractionType.favoriteAdd,
        );
      }
      // 1 + 0.5 + 0 = 1.5 → 0.15 · 1.5 = 0.225
      expect(
        profile.currentVector[indexOf('vista_panoramica')],
        closeTo(0.225, 1e-9),
      );
    });

    test('al llegar al umbral envía el lote', () async {
      UserProfile profile = buildProfile();
      for (final InteractionType type in <InteractionType>[
        InteractionType.viewDetail,
        InteractionType.photoExpand,
        InteractionType.directionsClick,
      ]) {
        profile = await service.recordInteraction(
          profile: profile,
          place: mirador,
          type: type,
        );
      }
      expect(await interactionRepository.pendingCount(), 0);
      expect(await service.flush(), 0);
    });

    test('el evento guarda el event_id generado y el snapshot', () async {
      await service.recordInteraction(
        profile: buildProfile(),
        place: mirador,
        type: InteractionType.share,
      );
      final List<InteractionEvent> queued =
          LocalInteractionQueue(await SharedPreferences.getInstance())
              .readAll();
      expect(queued.single.eventId, 'event-0');
      expect(queued.single.sessionId, 'session-1');
    });
  });
}
