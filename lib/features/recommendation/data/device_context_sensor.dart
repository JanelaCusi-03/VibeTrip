import 'package:geolocator/geolocator.dart';

import '../../../core/domain/context_types.dart';
import '../../../core/domain/geo_distance.dart';
import '../domain/services/recommendation_context_builder.dart';
import 'open_meteo_weather_source.dart';

/// Sensor real: GPS con `geolocator` y clima con Open-Meteo.
///
/// Fallback de ubicación (E1 §1.4): posición actual → última conocida →
/// `null` (la UI ofrece la zona manual).
class DeviceContextSensor implements ContextSensor {
  const DeviceContextSensor({
    required OpenMeteoWeatherSource weatherSource,
    this.locationTimeout = const Duration(seconds: 8),
  }) : _weatherSource = weatherSource;

  final OpenMeteoWeatherSource _weatherSource;
  final Duration locationTimeout;

  @override
  Future<GeoPoint?> readLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: locationTimeout,
        ),
      );
      return GeoPoint(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } on Exception {
      final Position? lastKnownPosition =
          await Geolocator.getLastKnownPosition();
      return lastKnownPosition == null
          ? null
          : GeoPoint(
              latitude: lastKnownPosition.latitude,
              longitude: lastKnownPosition.longitude,
            );
    }
  }

  @override
  Future<WeatherCondition> readWeather(GeoPoint location) =>
      _weatherSource.readCurrentWeather(location);
}
