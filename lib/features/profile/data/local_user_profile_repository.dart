import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/data/json_reading.dart';
import '../domain/entities/user_profile.dart';
import '../domain/repositories/user_profile_repository.dart';
import 'user_profile_json_mapper.dart';

/// Perfil guardado en el dispositivo. Con Supabase configurado se sincroniza
/// mediante PUT /v1/me/preferences usando [UserProfile.version] (`If-Match`).
class LocalUserProfileRepository implements UserProfileRepository {
  const LocalUserProfileRepository(this._preferences);

  static const String storageKey = 'profile.v1';

  final SharedPreferences _preferences;

  @override
  Future<UserProfile?> loadProfile() async {
    final String? encoded = _preferences.getString(storageKey);
    if (encoded == null) return null;
    try {
      return UserProfileJsonMapper.fromJson(jsonDecode(encoded) as JsonMap);
    } on FormatException {
      return null;
    } on ArgumentError {
      return null;
    }
  }

  @override
  Future<void> saveProfile(UserProfile profile) => _preferences.setString(
        storageKey,
        jsonEncode(UserProfileJsonMapper.toJson(profile)),
      );

  @override
  Future<void> deleteProfile() => _preferences.remove(storageKey);
}
