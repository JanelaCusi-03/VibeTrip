import 'dart:math' as math;

/// Radio medio de la Tierra según la IUGG, en metros.
const double earthMeanRadiusInMeters = 6371008.8;

/// Punto geográfico en grados decimales (WGS 84).
class GeoPoint {
  const GeoPoint({required this.latitude, required this.longitude})
      : assert(latitude >= -90 && latitude <= 90),
        assert(longitude >= -180 && longitude <= 180);

  final double latitude;
  final double longitude;

  @override
  bool operator ==(Object other) =>
      other is GeoPoint &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);

  @override
  String toString() => 'GeoPoint($latitude, $longitude)';
}

/// Distancia geodésica por la fórmula de Haversine (Entregable 2 §3.2).
double computeHaversineDistanceInMeters(GeoPoint from, GeoPoint to) {
  final double fromLatitudeRadians = _toRadians(from.latitude);
  final double toLatitudeRadians = _toRadians(to.latitude);
  final double deltaLatitudeRadians = _toRadians(to.latitude - from.latitude);
  final double deltaLongitudeRadians =
      _toRadians(to.longitude - from.longitude);

  final double haversineTerm = math.pow(math.sin(deltaLatitudeRadians / 2), 2) +
      math.cos(fromLatitudeRadians) *
          math.cos(toLatitudeRadians) *
          math.pow(math.sin(deltaLongitudeRadians / 2), 2);

  final double centralAngle =
      2 * math.atan2(math.sqrt(haversineTerm), math.sqrt(1 - haversineTerm));
  return earthMeanRadiusInMeters * centralAngle;
}

double _toRadians(double degrees) => degrees * math.pi / 180;
