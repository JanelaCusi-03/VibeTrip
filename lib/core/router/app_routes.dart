/// Rutas de la aplicación (separadas del router para evitar importaciones
/// circulares entre pantallas y configuración).
abstract final class AppRoutes {
  static const String home = '/';
  static const String map = '/map';
  static const String profile = '/profile';
  static const String placeDetailPattern = '/places/:placeId';

  static String placeDetail(String placeId) => '/places/$placeId';
}
