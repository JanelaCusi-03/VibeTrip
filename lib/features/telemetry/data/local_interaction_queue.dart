import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/data/json_reading.dart';
import '../domain/entities/interaction_event.dart';
import 'interaction_event_json_mapper.dart';

/// Cola FIFO persistente de eventos pendientes de envío (ADR-01).
class LocalInteractionQueue {
  const LocalInteractionQueue(this._preferences, {this.maximumLength = 200});

  static const String storageKey = 'telemetry.queue.v1';

  final SharedPreferences _preferences;

  /// Si se supera, se descartan los eventos más antiguos.
  final int maximumLength;

  List<InteractionEvent> readAll() {
    final String? encoded = _preferences.getString(storageKey);
    if (encoded == null) return <InteractionEvent>[];
    try {
      return (jsonDecode(encoded) as List<Object?>)
          .cast<JsonMap>()
          .map(InteractionEventJsonMapper.fromJson)
          .toList();
    } on FormatException {
      return <InteractionEvent>[];
    }
  }

  /// Agrega el evento salvo que su `event_id` ya esté en la cola.
  Future<void> add(InteractionEvent event) async {
    final List<InteractionEvent> queuedEvents = readAll();
    if (queuedEvents.any((queued) => queued.eventId == event.eventId)) return;
    queuedEvents.add(event);
    final int overflow = queuedEvents.length - maximumLength;
    await _writeAll(
      overflow > 0 ? queuedEvents.sublist(overflow) : queuedEvents,
    );
  }

  Future<void> removeByEventIds(Set<String> deliveredEventIds) => _writeAll(
        readAll()
            .where((event) => !deliveredEventIds.contains(event.eventId))
            .toList(),
      );

  Future<void> clear() => _preferences.remove(storageKey);

  Future<void> _writeAll(List<InteractionEvent> events) =>
      _preferences.setString(
        storageKey,
        jsonEncode(events.map(InteractionEventJsonMapper.toJson).toList()),
      );
}
