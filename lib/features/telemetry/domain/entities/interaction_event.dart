import '../services/signal_weight_policy.dart';
import 'interaction_type.dart';

/// Evento de interacción (fila de `user_interactions_log`).
///
/// Se crea solo mediante sus *factories* (patrón Factory), que centralizan
/// la validación y el cálculo del peso de la señal.
class InteractionEvent {
  InteractionEvent._({
    required this.eventId,
    required this.userId,
    required this.placeId,
    required this.sessionId,
    required this.type,
    required this.signalWeight,
    required this.occurredAt,
    this.dwellInMilliseconds,
    this.matchScoreAtTime,
    Map<String, Object?> contextSnapshot = const <String, Object?>{},
  }) : contextSnapshot = Map<String, Object?>.unmodifiable(contextSnapshot) {
    if (signalWeight < -1 || signalWeight > 1) {
      throw ArgumentError.value(
        signalWeight,
        'signalWeight',
        'Fuera de [-1, 1]',
      );
    }
    if (type == InteractionType.dwell && dwellInMilliseconds == null) {
      throw ArgumentError('Un evento dwell requiere dwellInMilliseconds');
    }
  }

  /// Evento discreto (favorito, descarte, «cómo llegar», etc.).
  factory InteractionEvent.create({
    required String eventId,
    required String userId,
    required String placeId,
    required String sessionId,
    required InteractionType type,
    required DateTime occurredAt,
    double? matchScoreAtTime,
    Map<String, Object?> contextSnapshot = const <String, Object?>{},
  }) {
    if (type == InteractionType.dwell) {
      throw ArgumentError('Usa InteractionEvent.fromViewDuration para dwell');
    }
    return InteractionEvent._(
      eventId: eventId,
      userId: userId,
      placeId: placeId,
      sessionId: sessionId,
      type: type,
      signalWeight: type.baseSignalWeight,
      occurredAt: occurredAt,
      matchScoreAtTime: matchScoreAtTime,
      contextSnapshot: contextSnapshot,
    );
  }

  /// Convierte el tiempo visible de una tarjeta en `impression_skip` (< 1 s)
  /// o en `dwell` con peso por saturación exponencial.
  factory InteractionEvent.fromViewDuration({
    required String eventId,
    required String userId,
    required String placeId,
    required String sessionId,
    required Duration visibleDuration,
    required DateTime occurredAt,
    double? matchScoreAtTime,
    Map<String, Object?> contextSnapshot = const <String, Object?>{},
  }) {
    final int dwellInMilliseconds = visibleDuration.inMilliseconds;
    final bool isImpressionSkip =
        visibleDuration < SignalWeightPolicy.impressionSkipThreshold;
    return InteractionEvent._(
      eventId: eventId,
      userId: userId,
      placeId: placeId,
      sessionId: sessionId,
      type: isImpressionSkip
          ? InteractionType.impressionSkip
          : InteractionType.dwell,
      signalWeight: isImpressionSkip
          ? InteractionType.impressionSkip.baseSignalWeight
          : SignalWeightPolicy.computeDwellSignalWeight(dwellInMilliseconds),
      occurredAt: occurredAt,
      dwellInMilliseconds: dwellInMilliseconds,
      matchScoreAtTime: matchScoreAtTime,
      contextSnapshot: contextSnapshot,
    );
  }

  /// Reconstrucción desde almacenamiento (cola local o servidor).
  factory InteractionEvent.restore({
    required String eventId,
    required String userId,
    required String placeId,
    required String sessionId,
    required InteractionType type,
    required double signalWeight,
    required DateTime occurredAt,
    int? dwellInMilliseconds,
    double? matchScoreAtTime,
    Map<String, Object?> contextSnapshot = const <String, Object?>{},
  }) =>
      InteractionEvent._(
        eventId: eventId,
        userId: userId,
        placeId: placeId,
        sessionId: sessionId,
        type: type,
        signalWeight: signalWeight,
        occurredAt: occurredAt,
        dwellInMilliseconds: dwellInMilliseconds,
        matchScoreAtTime: matchScoreAtTime,
        contextSnapshot: contextSnapshot,
      );

  /// UUID v4 generado en el cliente: clave de idempotencia (RNF-06).
  final String eventId;
  final String userId;
  final String placeId;
  final String sessionId;
  final InteractionType type;
  final double signalWeight;
  final DateTime occurredAt;
  final int? dwellInMilliseconds;
  final double? matchScoreAtTime;
  final Map<String, Object?> contextSnapshot;

  CaptureChannel get channel => type.channel;

  @override
  bool operator ==(Object other) =>
      other is InteractionEvent && other.eventId == eventId;

  @override
  int get hashCode => eventId.hashCode;

  @override
  String toString() =>
      'InteractionEvent(${type.wireName}, $placeId, $signalWeight)';
}
