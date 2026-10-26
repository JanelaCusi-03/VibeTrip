import '../../../../core/domain/context_types.dart';
import '../../../../core/domain/tag_vector.dart';

/// Perfil del usuario: tablas `users` + `user_preference_vectors` y
/// favoritos/descartes (`user_favorites` y eventos `discard`).
class UserProfile {
  UserProfile({
    required this.id,
    required this.displayName,
    required this.explicitVector,
    required this.currentVector,
    this.defaultBudgetLevel = defaultBudget,
    this.defaultCompanion = CompanionType.solo,
    this.searchRadiusInMeters = defaultSearchRadiusInMeters,
    this.hasTelemetryConsent = false,
    this.onboardingCompletedAt,
    List<String> selectedVibes = const <String>[],
    this.interactionCount = 0,
    this.version = 1,
    this.lastDecayAppliedAt,
    Set<String> favoritePlaceIds = const <String>{},
    Set<String> discardedPlaceIds = const <String>{},
  })  : selectedVibes = List<String>.unmodifiable(selectedVibes),
        favoritePlaceIds = Set<String>.unmodifiable(favoritePlaceIds),
        discardedPlaceIds = Set<String>.unmodifiable(discardedPlaceIds) {
    if (!PriceLevel.isValid(defaultBudgetLevel)) {
      throw ArgumentError.value(defaultBudgetLevel, 'defaultBudgetLevel');
    }
    if (searchRadiusInMeters < minimumSearchRadiusInMeters ||
        searchRadiusInMeters > maximumSearchRadiusInMeters) {
      throw ArgumentError.value(searchRadiusInMeters, 'searchRadiusInMeters');
    }
  }

  /// Perfil nuevo: vectores en cero y telemetría implícita desactivada (RNF-09).
  factory UserProfile.initial({
    required String id,
    String displayName = 'Viajero',
  }) =>
      UserProfile(
        id: id,
        displayName: displayName,
        explicitVector: TagVector.zero(),
        currentVector: TagVector.zero(),
      );

  static const int defaultBudget = 2;
  static const int defaultSearchRadiusInMeters = 3000;
  static const int minimumSearchRadiusInMeters = 500;
  static const int maximumSearchRadiusInMeters = 50000;

  final String id;
  final String displayName;

  /// `u₀`: semilla del onboarding.
  final TagVector explicitVector;

  /// `u`: vector efectivo que usa el motor.
  final TagVector currentVector;
  final int defaultBudgetLevel;
  final CompanionType defaultCompanion;
  final int searchRadiusInMeters;
  final bool hasTelemetryConsent;
  final DateTime? onboardingCompletedAt;
  final List<String> selectedVibes;
  final int interactionCount;

  /// Versión para concurrencia optimista (`If-Match` en PUT /me/preferences).
  final int version;
  final DateTime? lastDecayAppliedAt;
  final Set<String> favoritePlaceIds;
  final Set<String> discardedPlaceIds;

  bool get hasCompletedOnboarding => onboardingCompletedAt != null;

  bool isFavorite(String placeId) => favoritePlaceIds.contains(placeId);

  bool isDiscarded(String placeId) => discardedPlaceIds.contains(placeId);

  UserProfile copyWith({
    String? displayName,
    TagVector? explicitVector,
    TagVector? currentVector,
    int? defaultBudgetLevel,
    CompanionType? defaultCompanion,
    int? searchRadiusInMeters,
    bool? hasTelemetryConsent,
    DateTime? onboardingCompletedAt,
    List<String>? selectedVibes,
    int? interactionCount,
    int? version,
    DateTime? lastDecayAppliedAt,
    Set<String>? favoritePlaceIds,
    Set<String>? discardedPlaceIds,
  }) =>
      UserProfile(
        id: id,
        displayName: displayName ?? this.displayName,
        explicitVector: explicitVector ?? this.explicitVector,
        currentVector: currentVector ?? this.currentVector,
        defaultBudgetLevel: defaultBudgetLevel ?? this.defaultBudgetLevel,
        defaultCompanion: defaultCompanion ?? this.defaultCompanion,
        searchRadiusInMeters: searchRadiusInMeters ?? this.searchRadiusInMeters,
        hasTelemetryConsent: hasTelemetryConsent ?? this.hasTelemetryConsent,
        onboardingCompletedAt:
            onboardingCompletedAt ?? this.onboardingCompletedAt,
        selectedVibes: selectedVibes ?? this.selectedVibes,
        interactionCount: interactionCount ?? this.interactionCount,
        version: version ?? this.version,
        lastDecayAppliedAt: lastDecayAppliedAt ?? this.lastDecayAppliedAt,
        favoritePlaceIds: favoritePlaceIds ?? this.favoritePlaceIds,
        discardedPlaceIds: discardedPlaceIds ?? this.discardedPlaceIds,
      );

  /// Reinicia los gustos (RF-17) conservando preferencias de cuenta.
  UserProfile resetPreferences() => UserProfile(
        id: id,
        displayName: displayName,
        explicitVector: TagVector.zero(),
        currentVector: TagVector.zero(),
        defaultBudgetLevel: defaultBudgetLevel,
        defaultCompanion: defaultCompanion,
        searchRadiusInMeters: searchRadiusInMeters,
        hasTelemetryConsent: hasTelemetryConsent,
        version: version + 1,
        favoritePlaceIds: favoritePlaceIds,
      );

  @override
  bool operator ==(Object other) =>
      other is UserProfile && other.id == id && other.version == version;

  @override
  int get hashCode => Object.hash(id, version);

  @override
  String toString() => 'UserProfile($id, v$version)';
}
