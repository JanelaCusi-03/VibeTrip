/// Tipos del contexto en tiempo real (Entregable 1 §1.4).
///
/// Los valores de [wireName] coinciden con los ENUM de PostgreSQL
/// (`time_bucket`, `companion_type`) para serializar sin traducciones.
library;

/// Franja horaria: morning 06-11, afternoon 12-17, evening 18-21, night 22-05.
enum TimeBucket {
  morning('morning', 'Mañana'),
  afternoon('afternoon', 'Tarde'),
  evening('evening', 'Atardecer'),
  night('night', 'Noche');

  const TimeBucket(this.wireName, this.displayName);

  final String wireName;
  final String displayName;

  static TimeBucket fromDateTime(DateTime localDateTime) {
    final int hour = localDateTime.hour;
    if (hour >= 6 && hour <= 11) return TimeBucket.morning;
    if (hour >= 12 && hour <= 17) return TimeBucket.afternoon;
    if (hour >= 18 && hour <= 21) return TimeBucket.evening;
    return TimeBucket.night;
  }

  static TimeBucket fromWireName(String wireName) =>
      values.firstWhere((bucket) => bucket.wireName == wireName);
}

/// Compañía declarada por el usuario para la sesión.
enum CompanionType {
  solo('solo', 'Solo'),
  couple('couple', 'En pareja'),
  friends('friends', 'Con amigos'),
  family('family', 'En familia');

  const CompanionType(this.wireName, this.displayName);

  final String wireName;
  final String displayName;

  static CompanionType fromWireName(String wireName) =>
      values.firstWhere((companion) => companion.wireName == wireName);
}

/// Condición climática simplificada a partir de Open-Meteo.
enum WeatherCondition {
  clear('clear', 'Despejado'),
  cloudy('cloudy', 'Nublado'),
  rain('rain', 'Lluvia'),
  cold('cold', 'Frío'),
  hot('hot', 'Calor'),
  unknown('unknown', 'Sin datos');

  const WeatherCondition(this.wireName, this.displayName);

  final String wireName;
  final String displayName;

  static WeatherCondition fromWireName(String wireName) => values.firstWhere(
        (condition) => condition.wireName == wireName,
        orElse: () => WeatherCondition.unknown,
      );
}

/// Nivel de precio de 1 (económico) a 4 (premium), igual que `price_level`.
abstract final class PriceLevel {
  static const int minimum = 1;
  static const int maximum = 4;

  static bool isValid(int priceLevel) =>
      priceLevel >= minimum && priceLevel <= maximum;

  static String toSymbols(int priceLevel) => r'$' * priceLevel;
}
