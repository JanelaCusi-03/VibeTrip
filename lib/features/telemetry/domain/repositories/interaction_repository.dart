import '../entities/interaction_event.dart';

/// Contrato de la telemetría: cola local con envío por lotes (RF-15, RNF-06).
abstract interface class InteractionRepository {
  /// Guarda el evento en la cola local; ignora `event_id` repetidos.
  Future<void> enqueue(InteractionEvent event);

  Future<int> pendingCount();

  /// Envía los eventos pendientes por lotes y devuelve cuántos se entregaron.
  /// Si falla la red, los eventos quedan en la cola para el siguiente intento.
  Future<int> flush();

  /// Borra la cola local (RF-16).
  Future<void> clear();
}
