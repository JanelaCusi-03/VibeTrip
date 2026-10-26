import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vibetrip/core/domain/context_types.dart';
import 'package:vibetrip/features/recommendation/data/open_meteo_weather_source.dart';
import 'package:vibetrip/features/recommendation/domain/entities/recommendation_context.dart';
import 'package:vibetrip/features/recommendation/domain/services/recommendation_context_builder.dart';
import 'package:vibetrip/features/recommendation/domain/services/recommendation_metrics.dart';

import '../../helpers/fixtures.dart';

void main() {
  group('RecommendationContextBuilder y QuickFilter (RF-05, RF-06)', () {
    final RecommendationContext baseContext =
        RecommendationContextBuilder.build(
      profile: buildProfile(),
      now: DateTime(2026, 10, 24, 20),
      userLocation: plazaDeArmas,
      weather: WeatherCondition.rain,
    );

    test('toma franja del reloj y defaults del perfil', () {
      expect(baseContext.timeBucket, TimeBucket.evening);
      expect(baseContext.budgetLevel, 2);
      expect(baseContext.companion, CompanionType.solo);
      expect(baseContext.searchRadiusInMeters, 3000);
      expect(baseContext.weather, WeatherCondition.rain);
    });

    test('cada filtro rápido modifica el contexto', () {
      expect(
        QuickFilter.friends.applyTo(baseContext).companion,
        CompanionType.friends,
      );
      expect(
        QuickFilter.solo
            .applyTo(baseContext.copyWith(companion: CompanionType.family))
            .companion,
        CompanionType.solo,
      );
      expect(QuickFilter.economic.applyTo(baseContext).maximumPriceLevel, 2);
      expect(
        QuickFilter.nearMe.applyTo(baseContext).searchRadiusInMeters,
        1000,
      );
    });

    test('build aplica el filtro indicado', () {
      final RecommendationContext nearMeContext =
          RecommendationContextBuilder.build(
        profile: buildProfile(),
        now: DateTime(2026, 10, 24, 9),
        quickFilter: QuickFilter.nearMe,
      );
      expect(nearMeContext.searchRadiusInMeters, 1000);
      expect(nearMeContext.weather, WeatherCondition.unknown);
    });
  });

  group('WeatherCodeMapper', () {
    WeatherCondition map(int code, double celsius) =>
        WeatherCodeMapper.toCondition(
          weatherCode: code,
          temperatureInCelsius: celsius,
        );

    test('precipitación tiene prioridad', () {
      expect(map(61, 30), WeatherCondition.rain);
    });

    test('temperaturas extremas', () {
      expect(map(0, 5), WeatherCondition.cold);
      expect(map(0, 30), WeatherCondition.hot);
    });

    test('despejado y nublado', () {
      expect(map(1, 18), WeatherCondition.clear);
      expect(map(3, 18), WeatherCondition.cloudy);
    });
  });

  group('OpenMeteoWeatherSource', () {
    test('lee el clima actual y lo guarda 30 minutos', () async {
      int requestCount = 0;
      DateTime now = DateTime.utc(2026, 10, 24, 20);
      final OpenMeteoWeatherSource source = OpenMeteoWeatherSource(
        httpClient: MockClient((request) async {
          requestCount++;
          expect(request.url.host, 'api.open-meteo.com');
          return http.Response(
            '{"current": {"temperature_2m": 16.5, "weather_code": 0}}',
            200,
          );
        }),
        clock: () => now,
      );

      expect(
        await source.readCurrentWeather(plazaDeArmas),
        WeatherCondition.clear,
      );
      await source.readCurrentWeather(plazaDeArmas);
      expect(requestCount, 1);

      now = now.add(const Duration(minutes: 31));
      await source.readCurrentWeather(plazaDeArmas);
      expect(requestCount, 2);
    });

    test('sin red o con error HTTP devuelve unknown (efecto neutro)', () async {
      final OpenMeteoWeatherSource failing = OpenMeteoWeatherSource(
        httpClient: MockClient((_) async => throw http.ClientException('x')),
        clock: DateTime.now,
      );
      expect(
        await failing.readCurrentWeather(plazaDeArmas),
        WeatherCondition.unknown,
      );

      final OpenMeteoWeatherSource serverError = OpenMeteoWeatherSource(
        httpClient: MockClient((_) async => http.Response('', 500)),
        clock: DateTime.now,
      );
      expect(
        await serverError.readCurrentWeather(plazaDeArmas),
        WeatherCondition.unknown,
      );
    });
  });

  group('RecommendationMetrics', () {
    test('Precision@K', () {
      expect(
        RecommendationMetrics.precisionAtK(
          <String>['a', 'b', 'c', 'd'],
          <String>{'a', 'c', 'z'},
          3,
        ),
        closeTo(2 / 3, 1e-12),
      );
      expect(
        RecommendationMetrics.precisionAtK(<String>['a'], <String>{'a'}, 2),
        0.5,
      );
      expect(
        () => RecommendationMetrics.precisionAtK(<String>[], <String>{}, 0),
        throwsArgumentError,
      );
    });

    test('media y percentiles por rango más cercano', () {
      expect(RecommendationMetrics.mean(<double>[1, 2, 3]), 2);
      expect(() => RecommendationMetrics.mean(<double>[]), throwsArgumentError);

      final List<Duration> samples = <Duration>[
        for (int milliseconds = 1; milliseconds <= 20; milliseconds++)
          Duration(milliseconds: milliseconds),
      ];
      expect(
        RecommendationMetrics.percentile(samples, 95),
        const Duration(milliseconds: 19),
      );
      expect(
        RecommendationMetrics.percentile(samples, 50),
        const Duration(milliseconds: 10),
      );
      expect(
        () => RecommendationMetrics.percentile(<Duration>[], 50),
        throwsArgumentError,
      );
      expect(
        () => RecommendationMetrics.percentile(samples, 0),
        throwsArgumentError,
      );
    });
  });
}
