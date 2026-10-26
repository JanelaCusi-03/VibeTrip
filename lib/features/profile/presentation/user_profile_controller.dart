import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/context_types.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/providers/dependency_providers.dart';
import '../../places/domain/entities/place.dart';
import '../../recommendation/domain/entities/recommendation_context.dart';
import '../../telemetry/domain/entities/interaction_type.dart';
import '../../telemetry/domain/services/preference_vector_updater.dart';
import '../../telemetry/domain/services/telemetry_service.dart';
import '../domain/entities/user_profile.dart';
import '../domain/onboarding/onboarding_vector_builder.dart';
import '../domain/repositories/user_profile_repository.dart';

final AsyncNotifierProvider<UserProfileController, UserProfile>
    userProfileControllerProvider =
    AsyncNotifierProvider<UserProfileController, UserProfile>(
  UserProfileController.new,
);

/// Estado del perfil del usuario y casos de uso que lo modifican.
class UserProfileController extends AsyncNotifier<UserProfile> {
  UserProfileRepository get _repository =>
      ref.read(userProfileRepositoryProvider);

  TelemetryService get _telemetryService => ref.read(telemetryServiceProvider);

  /// Carga el perfil (o crea uno nuevo) y aplica el olvido temporal.
  @override
  Future<UserProfile> build() async {
    final UserProfile storedProfile = await _repository.loadProfile() ??
        UserProfile.initial(id: ref.read(uuidProvider).v4());
    final UserProfile decayedProfile = const PreferenceVectorUpdater()
        .applyTemporalDecay(storedProfile, ref.read(clockProvider)());
    await _repository.saveProfile(decayedProfile);
    return decayedProfile;
  }

  UserProfile get _currentProfile => state.requireValue;

  /// Paso final del onboarding (HU-01): guarda `u₀` y los *defaults*.
  Future<void> completeOnboarding({
    required OnboardingAnswers answers,
    required int budgetLevel,
    required CompanionType companion,
    required bool hasTelemetryConsent,
  }) async {
    final initialVector = const OnboardingVectorBuilder().build(answers);
    await _save(
      _currentProfile.copyWith(
        explicitVector: initialVector,
        currentVector: initialVector,
        selectedVibes: answers.selectedVibes.map((vibe) => vibe.id).toList(),
        defaultBudgetLevel: budgetLevel,
        defaultCompanion: companion,
        hasTelemetryConsent: hasTelemetryConsent,
        onboardingCompletedAt: ref.read(clockProvider)(),
        version: _currentProfile.version + 1,
      ),
    );
  }

  Future<void> recordInteraction({
    required Place place,
    required InteractionType type,
    RecommendationContext? context,
    int? matchScore,
  }) async {
    final UserProfile updatedProfile =
        await _telemetryService.recordInteraction(
      profile: _currentProfile,
      place: place,
      type: type,
      context: context,
      matchScore: matchScore,
    );
    if (ref.mounted) state = AsyncData<UserProfile>(updatedProfile);
  }

  Future<void> recordViewDuration({
    required Place place,
    required Duration visibleDuration,
    RecommendationContext? context,
    int? matchScore,
  }) async {
    if (!state.hasValue) return;
    final UserProfile updatedProfile =
        await _telemetryService.recordViewDuration(
      profile: _currentProfile,
      place: place,
      visibleDuration: visibleDuration,
      context: context,
      matchScore: matchScore,
    );
    if (ref.mounted) state = AsyncData<UserProfile>(updatedProfile);
  }

  Future<void> toggleFavorite(Place place, {RecommendationContext? context}) =>
      recordInteraction(
        place: place,
        type: _currentProfile.isFavorite(place.id)
            ? InteractionType.favoriteRemove
            : InteractionType.favoriteAdd,
        context: context,
      );

  /// RF-16: consentimiento de telemetría implícita.
  Future<void> setTelemetryConsent({required bool hasConsent}) => _save(
        _currentProfile.copyWith(
          hasTelemetryConsent: hasConsent,
          version: _currentProfile.version + 1,
        ),
      );

  /// RF-17: reiniciar gustos y volver al onboarding.
  Future<void> resetPreferences() => _save(_currentProfile.resetPreferences());

  /// RF-16: eliminar todos los datos del dispositivo y empezar de cero.
  Future<void> deleteAllData() async {
    await _repository.deleteProfile();
    await ref.read(interactionRepositoryProvider).clear();
    ref.invalidateSelf();
  }

  /// Tras cada `await` se comprueba `ref.mounted`: el provider pudo
  /// destruirse mientras tanto (por ejemplo, al eliminar los datos).
  Future<void> _save(UserProfile profile) async {
    await _repository.saveProfile(profile);
    if (ref.mounted) state = AsyncData<UserProfile>(profile);
  }
}
