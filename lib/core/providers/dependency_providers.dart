import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../features/places/data/datasources/place_local_cache_data_source.dart';
import '../../features/places/data/datasources/place_remote_data_source.dart';
import '../../features/places/data/repositories/cached_place_repository.dart';
import '../../features/places/data/repositories/remote_place_repository.dart';
import '../../features/places/domain/repositories/place_repository.dart';
import '../../features/profile/data/local_user_profile_repository.dart';
import '../../features/profile/domain/repositories/user_profile_repository.dart';
import '../../features/recommendation/data/device_context_sensor.dart';
import '../../features/recommendation/data/open_meteo_weather_source.dart';
import '../../features/recommendation/domain/services/recommendation_context_builder.dart';
import '../../features/recommendation/domain/services/recommendation_engine_service.dart';
import '../../features/telemetry/data/interaction_remote_data_source.dart';
import '../../features/telemetry/data/local_interaction_queue.dart';
import '../../features/telemetry/data/queued_interaction_repository.dart';
import '../../features/telemetry/domain/repositories/interaction_repository.dart';
import '../../features/telemetry/domain/services/telemetry_service.dart';
import '../config/app_config.dart';
import 'core_providers.dart';

/// Composición de dependencias (Dependency Injection con Riverpod).
///
/// Aquí, y solo aquí, se decide qué implementación concreta usa la app:
/// Supabase si está configurado, o el modo local con el seed.

final Provider<Uuid> uuidProvider = Provider<Uuid>((ref) => const Uuid());

/// Un `session_id` nuevo por cada arranque de la app.
final Provider<String> sessionIdProvider =
    Provider<String>((ref) => ref.watch(uuidProvider).v4());

final Provider<PlaceRepository> placeRepositoryProvider =
    Provider<PlaceRepository>((ref) {
  final PlaceRemoteDataSource remoteDataSource = AppConfig.isSupabaseConfigured
      ? SupabasePlaceDataSource(Supabase.instance.client)
      : SeedPlaceDataSource(
          () => rootBundle.loadString(SeedPlaceDataSource.assetPath),
        );
  return CachedPlaceRepository(
    decoratedRepository: RemotePlaceRepository(remoteDataSource),
    localCache: PlaceLocalCacheDataSource(ref.watch(sharedPreferencesProvider)),
    clock: ref.watch(clockProvider),
  );
});

final Provider<UserProfileRepository> userProfileRepositoryProvider =
    Provider<UserProfileRepository>(
  (ref) => LocalUserProfileRepository(ref.watch(sharedPreferencesProvider)),
);

final Provider<InteractionRepository> interactionRepositoryProvider =
    Provider<InteractionRepository>(
  (ref) => QueuedInteractionRepository(
    queue: LocalInteractionQueue(ref.watch(sharedPreferencesProvider)),
    remoteDataSource: AppConfig.isSupabaseConfigured
        ? SupabaseInteractionRemoteDataSource(Supabase.instance.client)
        : const LocalOnlyInteractionRemoteDataSource(),
  ),
);

final Provider<TelemetryService> telemetryServiceProvider =
    Provider<TelemetryService>(
  (ref) => TelemetryService(
    profileRepository: ref.watch(userProfileRepositoryProvider),
    interactionRepository: ref.watch(interactionRepositoryProvider),
    generateEventId: ref.watch(uuidProvider).v4,
    clock: ref.watch(clockProvider),
    sessionId: ref.watch(sessionIdProvider),
  ),
);

final Provider<RecommendationEngineService> recommendationEngineProvider =
    Provider<RecommendationEngineService>(
  (ref) => RecommendationEngineService(),
);

final Provider<ContextSensor> contextSensorProvider = Provider<ContextSensor>(
  (ref) => DeviceContextSensor(
    weatherSource: OpenMeteoWeatherSource(
      httpClient: ref.watch(httpClientProvider),
      clock: ref.watch(clockProvider),
    ),
  ),
);
