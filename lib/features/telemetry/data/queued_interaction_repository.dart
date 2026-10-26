import '../domain/entities/interaction_event.dart';
import '../domain/repositories/interaction_repository.dart';
import 'interaction_event_json_mapper.dart';
import 'interaction_remote_data_source.dart';
import 'local_interaction_queue.dart';

/// Telemetría Offline-First: todo evento pasa primero por la cola local y se
/// envía por lotes de [batchSize]. Un lote fallido permanece en la cola.
class QueuedInteractionRepository implements InteractionRepository {
  const QueuedInteractionRepository({
    required LocalInteractionQueue queue,
    required InteractionRemoteDataSource remoteDataSource,
    this.batchSize = 10,
  })  : _queue = queue,
        _remoteDataSource = remoteDataSource;

  final LocalInteractionQueue _queue;
  final InteractionRemoteDataSource _remoteDataSource;
  final int batchSize;

  @override
  Future<void> enqueue(InteractionEvent event) => _queue.add(event);

  @override
  Future<int> pendingCount() async => _queue.readAll().length;

  @override
  Future<int> flush() async {
    int deliveredCount = 0;
    while (true) {
      final List<InteractionEvent> batch =
          _queue.readAll().take(batchSize).toList();
      if (batch.isEmpty) return deliveredCount;
      try {
        await _remoteDataSource.sendBatch(
          batch.map(InteractionEventJsonMapper.toJson).toList(),
        );
      } on Exception {
        return deliveredCount;
      }
      await _queue.removeByEventIds(
        batch.map((event) => event.eventId).toSet(),
      );
      deliveredCount += batch.length;
    }
  }

  @override
  Future<void> clear() => _queue.clear();
}
