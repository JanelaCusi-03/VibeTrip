import '../../../places/domain/entities/place.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../../../profile/domain/repositories/user_profile_repository.dart';
import '../../../recommendation/domain/entities/recommendation_context.dart';
import '../entities/interaction_event.dart';
import '../entities/interaction_type.dart';
import '../repositories/interaction_repository.dart';
import 'preference_vector_updater.dart';

/// Orquesta la telemetría de una sesión (RF-04, RF-09, RF-11, RF-12, RF-16).
///
/// Por cada interacción: respeta el consentimiento, aplica el tope por
/// sesión, actualiza el vector de gustos, persiste el perfil y encola el
/// evento; al llegar a [flushThreshold] eventos pendientes envía el lote.
class TelemetryService {
  TelemetryService({
    required UserProfileRepository profileRepository,
    required InteractionRepository interactionRepository,
    required String Function() generateEventId,
    required DateTime Function() clock,
    required this.sessionId,
    this.vectorUpdater = const PreferenceVectorUpdater(),
    this.flushThreshold = 10,
  })  : _profileRepository = profileRepository,
        _interactionRepository = interactionRepository,
        _generateEventId = generateEventId,
        _clock = clock;

  final UserProfileRepository _profileRepository;
  final InteractionRepository _interactionRepository;
  final String Function() _generateEventId;
  final DateTime Function() _clock;
  final String sessionId;
  final PreferenceVectorUpdater vectorUpdater;
  final int flushThreshold;

  final Map<String, double> _accumulatedSignalByPlaceId = <String, double>{};

  /// Interacción discreta: favorito, descarte, detalle, «cómo llegar», etc.
  Future<UserProfile> recordInteraction({
    required UserProfile profile,
    required Place place,
    required InteractionType type,
    RecommendationContext? context,
    int? matchScore,
  }) =>
      _process(
        profile,
        place,
        InteractionEvent.create(
          eventId: _generateEventId(),
          userId: profile.id,
          placeId: place.id,
          sessionId: sessionId,
          type: type,
          occurredAt: _clock(),
          matchScoreAtTime: matchScore?.toDouble(),
          contextSnapshot: context?.toSnapshot() ?? const <String, Object?>{},
        ),
      );

  /// Período de visualización de una tarjeta (dwell o impression_skip).
  Future<UserProfile> recordViewDuration({
    required UserProfile profile,
    required Place place,
    required Duration visibleDuration,
    RecommendationContext? context,
    int? matchScore,
  }) =>
      _process(
        profile,
        place,
        InteractionEvent.fromViewDuration(
          eventId: _generateEventId(),
          userId: profile.id,
          placeId: place.id,
          sessionId: sessionId,
          visibleDuration: visibleDuration,
          occurredAt: _clock(),
          matchScoreAtTime: matchScore?.toDouble(),
          contextSnapshot: context?.toSnapshot() ?? const <String, Object?>{},
        ),
      );

  Future<int> flush() => _interactionRepository.flush();

  Future<UserProfile> _process(
    UserProfile profile,
    Place place,
    InteractionEvent event,
  ) async {
    // RNF-09: sin consentimiento, las señales implícitas no se procesan.
    if (event.type.isImplicit && !profile.hasTelemetryConsent) return profile;

    final double accumulatedSignal = _accumulatedSignalByPlaceId[place.id] ?? 0;
    final double appliedSignal = vectorUpdater.capSessionSignal(
      accumulatedSignal: accumulatedSignal,
      signalWeight: event.signalWeight,
    );
    _accumulatedSignalByPlaceId[place.id] = accumulatedSignal + appliedSignal;

    final UserProfile updatedProfile = profile.copyWith(
      currentVector: vectorUpdater.applySignal(
        currentVector: profile.currentVector,
        placeVector: place.tagVector,
        signalWeight: appliedSignal,
      ),
      interactionCount: profile.interactionCount + 1,
      version: profile.version + 1,
      favoritePlaceIds: _updatedFavorites(profile, place.id, event.type),
      discardedPlaceIds: event.type == InteractionType.discard
          ? <String>{...profile.discardedPlaceIds, place.id}
          : null,
    );

    await _profileRepository.saveProfile(updatedProfile);
    await _interactionRepository.enqueue(event);
    if (await _interactionRepository.pendingCount() >= flushThreshold) {
      await _interactionRepository.flush();
    }
    return updatedProfile;
  }

  static Set<String>? _updatedFavorites(
    UserProfile profile,
    String placeId,
    InteractionType type,
  ) =>
      switch (type) {
        InteractionType.favoriteAdd => <String>{
            ...profile.favoritePlaceIds,
            placeId,
          },
        InteractionType.favoriteRemove => <String>{
            ...profile.favoritePlaceIds,
          }..remove(placeId),
        _ => null,
      };
}
