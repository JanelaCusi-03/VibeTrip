import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibetrip/core/data/json_reading.dart';
import 'package:vibetrip/core/domain/context_types.dart';
import 'package:vibetrip/features/profile/data/local_user_profile_repository.dart';
import 'package:vibetrip/features/profile/domain/entities/user_profile.dart';
import 'package:vibetrip/features/telemetry/data/interaction_event_json_mapper.dart';
import 'package:vibetrip/features/telemetry/data/interaction_remote_data_source.dart';
import 'package:vibetrip/features/telemetry/data/local_interaction_queue.dart';
import 'package:vibetrip/features/telemetry/data/queued_interaction_repository.dart';
import 'package:vibetrip/features/telemetry/domain/entities/interaction_event.dart';
import 'package:vibetrip/features/telemetry/domain/entities/interaction_type.dart';

import '../helpers/fixtures.dart';

class MockInteractionRemoteDataSource extends Mock
    implements InteractionRemoteDataSource {}

InteractionEvent buildEvent(String eventId) => InteractionEvent.create(
      eventId: eventId,
      userId: 'user-1',
      placeId: 'place-1',
      sessionId: 'session-1',
      type: InteractionType.favoriteAdd,
      occurredAt: DateTime.utc(2026, 10, 24, 20),
      contextSnapshot: const <String, Object?>{'time_bucket': 'evening'},
    );

void main() {
  late SharedPreferences preferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    preferences = await SharedPreferences.getInstance();
  });

  group('LocalUserProfileRepository', () {
    test('guarda y recupera el perfil completo', () async {
      final LocalUserProfileRepository repository =
          LocalUserProfileRepository(preferences);
      final UserProfile profile = buildProfile(
        preferences: <String, double>{'tranquilo': 0.8, 'bar': -0.4},
      ).copyWith(
        defaultCompanion: CompanionType.couple,
        onboardingCompletedAt: DateTime.utc(2026, 10, 1),
        lastDecayAppliedAt: DateTime.utc(2026, 10, 2),
        selectedVibes: <String>['relax'],
        favoritePlaceIds: <String>{'p1'},
        discardedPlaceIds: <String>{'p2'},
        version: 4,
      );

      expect(await repository.loadProfile(), isNull);
      await repository.saveProfile(profile);
      final UserProfile? restored = await repository.loadProfile();

      expect(restored, profile);
      expect(restored!.currentVector, profile.currentVector);
      expect(restored.defaultCompanion, CompanionType.couple);
      expect(restored.onboardingCompletedAt, DateTime.utc(2026, 10, 1));
      expect(restored.selectedVibes, <String>['relax']);
      expect(restored.favoritePlaceIds, <String>{'p1'});
      expect(restored.discardedPlaceIds, <String>{'p2'});

      await repository.deleteProfile();
      expect(await repository.loadProfile(), isNull);
    });

    test('un perfil corrupto se ignora', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        LocalUserProfileRepository.storageKey: '{"id": 3}',
      });
      final LocalUserProfileRepository repository =
          LocalUserProfileRepository(await SharedPreferences.getInstance());
      expect(await repository.loadProfile(), isNull);
    });
  });

  group('InteractionEventJsonMapper', () {
    test('ida y vuelta con columnas de user_interactions_log', () {
      final InteractionEvent event = InteractionEvent.fromViewDuration(
        eventId: 'e1',
        userId: 'user-1',
        placeId: 'place-1',
        sessionId: 'session-1',
        visibleDuration: const Duration(seconds: 5),
        occurredAt: DateTime.utc(2026, 10, 24, 20),
        matchScoreAtTime: 87,
      );
      final JsonMap row = InteractionEventJsonMapper.toJson(event);
      expect(row['channel'], 'implicit');
      expect(row['interaction_type'], 'dwell');
      expect(row['dwell_ms'], 5000);

      final InteractionEvent restored = InteractionEventJsonMapper.fromJson(
        row,
      );
      expect(restored, event);
      expect(restored.signalWeight, event.signalWeight);
      expect(restored.matchScoreAtTime, 87);
      expect(restored.occurredAt, event.occurredAt);
    });
  });

  group('LocalInteractionQueue', () {
    test('es idempotente por event_id y respeta el máximo', () async {
      final LocalInteractionQueue queue = LocalInteractionQueue(
        preferences,
        maximumLength: 2,
      );
      await queue.add(buildEvent('e1'));
      await queue.add(buildEvent('e1'));
      expect(queue.readAll(), hasLength(1));

      await queue.add(buildEvent('e2'));
      await queue.add(buildEvent('e3'));
      expect(
        queue.readAll().map((event) => event.eventId),
        <String>['e2', 'e3'],
      );

      await queue.removeByEventIds(<String>{'e2'});
      expect(queue.readAll().single.eventId, 'e3');
      await queue.clear();
      expect(queue.readAll(), isEmpty);
    });

    test('una cola corrupta se lee como vacía', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        LocalInteractionQueue.storageKey: 'xx',
      });
      final LocalInteractionQueue queue = LocalInteractionQueue(
        await SharedPreferences.getInstance(),
      );
      expect(queue.readAll(), isEmpty);
    });
  });

  group('QueuedInteractionRepository', () {
    late MockInteractionRemoteDataSource remoteDataSource;
    late QueuedInteractionRepository repository;

    setUp(() {
      remoteDataSource = MockInteractionRemoteDataSource();
      repository = QueuedInteractionRepository(
        queue: LocalInteractionQueue(preferences),
        remoteDataSource: remoteDataSource,
        batchSize: 2,
      );
    });

    test('envía en lotes y vacía la cola', () async {
      when(() => remoteDataSource.sendBatch(any())).thenAnswer((_) async {});
      for (final String eventId in <String>['e1', 'e2', 'e3']) {
        await repository.enqueue(buildEvent(eventId));
      }
      expect(await repository.pendingCount(), 3);

      expect(await repository.flush(), 3);
      expect(await repository.pendingCount(), 0);
      verify(() => remoteDataSource.sendBatch(any())).called(2);
    });

    test('si falla la red conserva los eventos para reintentar', () async {
      when(() => remoteDataSource.sendBatch(any()))
          .thenThrow(Exception('timeout'));
      await repository.enqueue(buildEvent('e1'));

      expect(await repository.flush(), 0);
      expect(await repository.pendingCount(), 1);

      await repository.clear();
      expect(await repository.pendingCount(), 0);
    });

    test('el modo local da por entregado cualquier lote', () async {
      await const LocalOnlyInteractionRemoteDataSource().sendBatch(
        <JsonMap>[InteractionEventJsonMapper.toJson(buildEvent('e1'))],
      );
    });
  });
}
