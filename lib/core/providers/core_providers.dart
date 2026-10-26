import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Almacenamiento local. Se sobrescribe en `main()` con la instancia ya
/// inicializada y en las pruebas con `SharedPreferences.setMockInitialValues`.
final Provider<SharedPreferences> sharedPreferencesProvider =
    Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(
    'sharedPreferencesProvider debe sobrescribirse en ProviderScope',
  ),
);

/// Reloj inyectable para que las pruebas controlen la fecha y hora.
final Provider<DateTime Function()> clockProvider =
    Provider<DateTime Function()>((ref) => DateTime.now);

/// Cliente HTTP compartido (Open-Meteo); se cierra al destruir el scope.
final Provider<http.Client> httpClientProvider = Provider<http.Client>((ref) {
  final http.Client client = http.Client();
  ref.onDispose(client.close);
  return client;
});
