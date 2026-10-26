import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/data/json_reading.dart';

/// Destino de los lotes de eventos (POST /v1/me/interactions).
abstract interface class InteractionRemoteDataSource {
  Future<void> sendBatch(List<JsonMap> eventRows);
}

/// Inserta en `user_interactions_log` ignorando `event_id` repetidos, de modo
/// que reintentar un lote nunca duplica filas (RNF-06).
class SupabaseInteractionRemoteDataSource
    implements InteractionRemoteDataSource {
  const SupabaseInteractionRemoteDataSource(this._client);

  final SupabaseClient _client;

  @override
  Future<void> sendBatch(List<JsonMap> eventRows) => _client
      .from('user_interactions_log')
      .upsert(eventRows, onConflict: 'event_id', ignoreDuplicates: true);
}

/// Modo local (sin backend): los eventos ya se aplicaron al vector en el
/// dispositivo, así que el envío se da por completado.
class LocalOnlyInteractionRemoteDataSource
    implements InteractionRemoteDataSource {
  const LocalOnlyInteractionRemoteDataSource();

  @override
  Future<void> sendBatch(List<JsonMap> eventRows) async {}
}
