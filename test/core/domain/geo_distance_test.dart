import 'package:flutter_test/flutter_test.dart';
import 'package:vibetrip/core/domain/context_types.dart';
import 'package:vibetrip/core/domain/geo_distance.dart';

void main() {
  group('computeHaversineDistanceInMeters', () {
    const GeoPoint plazaDeArmasCusco = GeoPoint(
      latitude: -13.5167,
      longitude: -71.9788,
    );

    test('es cero para el mismo punto', () {
      expect(
        computeHaversineDistanceInMeters(plazaDeArmasCusco, plazaDeArmasCusco),
        0,
      );
    });

    test('un grado de latitud mide R·π/180 ≈ 111 195 m', () {
      final double distanceInMeters = computeHaversineDistanceInMeters(
        const GeoPoint(latitude: 0, longitude: 0),
        const GeoPoint(latitude: 1, longitude: 0),
      );
      expect(distanceInMeters, closeTo(111195.08, 0.01));
    });

    test('es simétrica', () {
      const GeoPoint sacsayhuaman = GeoPoint(
        latitude: -13.5089,
        longitude: -71.9822,
      );
      expect(
        computeHaversineDistanceInMeters(plazaDeArmasCusco, sacsayhuaman),
        closeTo(
          computeHaversineDistanceInMeters(sacsayhuaman, plazaDeArmasCusco),
          1e-9,
        ),
      );
    });

    test('igualdad por valor de GeoPoint', () {
      expect(
        const GeoPoint(latitude: 1, longitude: 2),
        const GeoPoint(latitude: 1, longitude: 2),
      );
      expect(
        const GeoPoint(latitude: 1, longitude: 2).hashCode,
        const GeoPoint(latitude: 1, longitude: 2).hashCode,
      );
      expect(
        const GeoPoint(latitude: 1, longitude: 2).toString(),
        'GeoPoint(1.0, 2.0)',
      );
    });
  });

  group('context_types', () {
    test('TimeBucket.fromDateTime respeta las franjas del Entregable 1', () {
      const Map<int, TimeBucket> expectedBucketByHour = <int, TimeBucket>{
        5: TimeBucket.night,
        6: TimeBucket.morning,
        11: TimeBucket.morning,
        12: TimeBucket.afternoon,
        17: TimeBucket.afternoon,
        18: TimeBucket.evening,
        21: TimeBucket.evening,
        22: TimeBucket.night,
      };
      expectedBucketByHour.forEach((hour, expectedBucket) {
        final DateTime localDateTime = DateTime(2026, 1, 1, hour, 30);
        expect(TimeBucket.fromDateTime(localDateTime), expectedBucket);
      });
    });

    test('fromWireName traduce los ENUM de PostgreSQL', () {
      expect(TimeBucket.fromWireName('evening'), TimeBucket.evening);
      expect(CompanionType.fromWireName('family'), CompanionType.family);
      expect(WeatherCondition.fromWireName('rain'), WeatherCondition.rain);
      expect(
        WeatherCondition.fromWireName('granizo'),
        WeatherCondition.unknown,
      );
    });

    test('PriceLevel valida el rango 1-4', () {
      expect(PriceLevel.isValid(1), isTrue);
      expect(PriceLevel.isValid(5), isFalse);
      expect(PriceLevel.toSymbols(3), r'$$$');
    });
  });
}
