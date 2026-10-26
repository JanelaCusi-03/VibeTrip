import '../../../core/data/json_reading.dart';
import '../domain/entities/interaction_event.dart';
import '../domain/entities/interaction_type.dart';

/// Serializa eventos con las columnas de `user_interactions_log`.
abstract final class InteractionEventJsonMapper {
  static JsonMap toJson(InteractionEvent event) => <String, Object?>{
        'event_id': event.eventId,
        'user_id': event.userId,
        'place_id': event.placeId,
        'session_id': event.sessionId,
        'channel': event.channel.wireName,
        'interaction_type': event.type.wireName,
        'dwell_ms': event.dwellInMilliseconds,
        'signal_weight': event.signalWeight,
        'match_score_at_time': event.matchScoreAtTime,
        'context_snapshot': event.contextSnapshot,
        'occurred_at': event.occurredAt.toUtc().toIso8601String(),
      };

  static InteractionEvent fromJson(JsonMap json) => InteractionEvent.restore(
        eventId: json.read<String>('event_id'),
        userId: json.read<String>('user_id'),
        placeId: json.read<String>('place_id'),
        sessionId: json.read<String>('session_id'),
        type:
            InteractionType.fromWireName(json.read<String>('interaction_type')),
        signalWeight: json.readDouble('signal_weight'),
        occurredAt: DateTime.parse(json.read<String>('occurred_at')),
        dwellInMilliseconds: json.readOptional<int>('dwell_ms'),
        matchScoreAtTime: json.readOptionalDouble('match_score_at_time'),
        contextSnapshot: json.readOptional<JsonMap>('context_snapshot') ??
            const <String, Object?>{},
      );
}
