import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/data/json_reading.dart';
import '../../../core/domain/context_types.dart';
import '../../../core/domain/geo_distance.dart';

/// Clima actual desde Open-Meteo (sin API key) con caché de 30 minutos.
class OpenMeteoWeatherSource {
  OpenMeteoWeatherSource({
    required http.Client httpClient,
    required DateTime Function() clock,
    this.cacheDuration = const Duration(minutes: 30),
    this.requestTimeout = const Duration(seconds: 5),
  })  : _httpClient = httpClient,
        _clock = clock;

  final http.Client _httpClient;
  final DateTime Function() _clock;
  final Duration cacheDuration;
  final Duration requestTimeout;

  WeatherCondition? _cachedCondition;
  DateTime? _cachedAt;

  Future<WeatherCondition> readCurrentWeather(GeoPoint location) async {
    final DateTime now = _clock();
    final DateTime? cachedAt = _cachedAt;
    final WeatherCondition? cachedCondition = _cachedCondition;
    if (cachedCondition != null &&
        cachedAt != null &&
        now.difference(cachedAt) < cacheDuration) {
      return cachedCondition;
    }

    final Uri uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': location.latitude.toStringAsFixed(4),
      'longitude': location.longitude.toStringAsFixed(4),
      'current': 'temperature_2m,weather_code',
    });
    try {
      final http.Response response =
          await _httpClient.get(uri).timeout(requestTimeout);
      if (response.statusCode != 200) return WeatherCondition.unknown;
      final JsonMap current =
          (jsonDecode(response.body) as JsonMap).readMap('current');
      final WeatherCondition condition = WeatherCodeMapper.toCondition(
        weatherCode: current.read<int>('weather_code'),
        temperatureInCelsius: current.readDouble('temperature_2m'),
      );
      _cachedCondition = condition;
      _cachedAt = now;
      return condition;
    } on Exception {
      return WeatherCondition.unknown;
    }
  }
}

/// Traduce el código WMO de Open-Meteo y la temperatura a [WeatherCondition].
abstract final class WeatherCodeMapper {
  static const double coldThresholdInCelsius = 8;
  static const double hotThresholdInCelsius = 27;

  /// Prioridad: precipitación > temperatura extrema > nubosidad.
  static WeatherCondition toCondition({
    required int weatherCode,
    required double temperatureInCelsius,
  }) {
    final bool hasPrecipitation = weatherCode >= 51;
    if (hasPrecipitation) return WeatherCondition.rain;
    if (temperatureInCelsius < coldThresholdInCelsius) {
      return WeatherCondition.cold;
    }
    if (temperatureInCelsius > hotThresholdInCelsius) {
      return WeatherCondition.hot;
    }
    return weatherCode <= 1 ? WeatherCondition.clear : WeatherCondition.cloudy;
  }
}
