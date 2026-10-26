import '../entities/user_profile.dart';

/// Contrato de persistencia del perfil y el vector de gustos.
abstract interface class UserProfileRepository {
  /// `null` si el usuario aún no tiene perfil en este dispositivo.
  Future<UserProfile?> loadProfile();

  Future<void> saveProfile(UserProfile profile);

  /// Elimina todos los datos del usuario (RF-16, derecho de supresión).
  Future<void> deleteProfile();
}
