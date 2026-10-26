import '../../../core/data/json_reading.dart';
import '../../../core/domain/context_types.dart';
import '../../../core/domain/tag_vector.dart';
import '../domain/entities/user_profile.dart';

/// Serializa [UserProfile] con los nombres de columna de `users` y
/// `user_preference_vectors` para facilitar la sincronización con Supabase.
abstract final class UserProfileJsonMapper {
  static JsonMap toJson(UserProfile profile) => <String, Object?>{
        'id': profile.id,
        'display_name': profile.displayName,
        'default_budget_level': profile.defaultBudgetLevel,
        'default_companion': profile.defaultCompanion.wireName,
        'search_radius_m': profile.searchRadiusInMeters,
        'telemetry_consent': profile.hasTelemetryConsent,
        'onboarding_completed_at':
            profile.onboardingCompletedAt?.toUtc().toIso8601String(),
        'explicit_vector': profile.explicitVector.components,
        'current_vector': profile.currentVector.components,
        'selected_vibes': profile.selectedVibes,
        'interaction_count': profile.interactionCount,
        'version': profile.version,
        'last_decay_applied_at':
            profile.lastDecayAppliedAt?.toUtc().toIso8601String(),
        'favorite_place_ids': profile.favoritePlaceIds.toList(),
        'discarded_place_ids': profile.discardedPlaceIds.toList(),
      };

  static UserProfile fromJson(JsonMap json) => UserProfile(
        id: json.read<String>('id'),
        displayName: json.read<String>('display_name'),
        defaultBudgetLevel: json.read<int>('default_budget_level'),
        defaultCompanion:
            CompanionType.fromWireName(json.read<String>('default_companion')),
        searchRadiusInMeters: json.read<int>('search_radius_m'),
        hasTelemetryConsent: json.read<bool>('telemetry_consent'),
        onboardingCompletedAt:
            _readOptionalDateTime(json, 'onboarding_completed_at'),
        explicitVector: _readVector(json, 'explicit_vector'),
        currentVector: _readVector(json, 'current_vector'),
        selectedVibes: json.readStringList('selected_vibes'),
        interactionCount: json.read<int>('interaction_count'),
        version: json.read<int>('version'),
        lastDecayAppliedAt:
            _readOptionalDateTime(json, 'last_decay_applied_at'),
        favoritePlaceIds: json.readStringList('favorite_place_ids').toSet(),
        discardedPlaceIds: json.readStringList('discarded_place_ids').toSet(),
      );

  static TagVector _readVector(JsonMap json, String key) => TagVector(<double>[
        for (final Object? component in json.read<List<Object?>>(key))
          (component! as num).toDouble(),
      ]);

  static DateTime? _readOptionalDateTime(JsonMap json, String key) {
    final String? encoded = json.readOptional<String>(key);
    return encoded == null ? null : DateTime.parse(encoded);
  }
}
