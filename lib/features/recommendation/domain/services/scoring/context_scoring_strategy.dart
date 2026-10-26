import 'dart:math' as math;

import '../../../../../core/domain/context_types.dart';
import '../../../../places/domain/entities/place.dart';
import 'scoring_strategy.dart';

/// `C = (T + B + K + W) / 4` (Entregable 2 §3.3).
class ContextScoringStrategy implements ScoringStrategy {
  const ContextScoringStrategy({this.weight = defaultWeight});

  static const double defaultWeight = 0.20;

  static const double matchScore = 1.0;
  static const double unknownTimeOrCompanionScore = 0.6;
  static const double timeMismatchScore = 0.2;
  static const double companionMismatchScore = 0.3;

  @override
  final double weight;

  @override
  String get factorName => 'context';

  @override
  double score(ScoringInput input) {
    final Place place = input.place;
    final double timeScore = scoreTimeBucket(place, input.context.timeBucket);
    final double budgetScore = scoreBudget(place, input.context.budgetLevel);
    final double companionScore =
        scoreCompanion(place, input.context.companion);
    final double weatherScore = scoreWeather(place, input.context.weather);
    return (timeScore + budgetScore + companionScore + weatherScore) / 4;
  }

  /// T: 1.0 si la franja coincide, 0.6 sin dato, 0.2 en otro caso.
  static double scoreTimeBucket(Place place, TimeBucket currentTimeBucket) {
    if (place.bestTimeBuckets.isEmpty) return unknownTimeOrCompanionScore;
    return place.bestTimeBuckets.contains(currentTimeBucket)
        ? matchScore
        : timeMismatchScore;
  }

  /// B: 1.0 dentro del presupuesto; `2^−(precio − presupuesto)` si lo excede.
  static double scoreBudget(Place place, int budgetLevel) {
    final int levelsOverBudget = place.priceLevel - budgetLevel;
    if (levelsOverBudget <= 0) return matchScore;
    return math.pow(2, -levelsOverBudget).toDouble();
  }

  /// K: 1.0 si la compañía encaja, 0.6 sin dato, 0.3 en otro caso.
  static double scoreCompanion(Place place, CompanionType companion) {
    if (place.companionFit.isEmpty) return unknownTimeOrCompanionScore;
    return place.companionFit.contains(companion)
        ? matchScore
        : companionMismatchScore;
  }

  /// W: tabla de clima según el lugar sea al aire libre o bajo techo.
  static double scoreWeather(Place place, WeatherCondition weather) {
    if (place.isOutdoor) {
      return switch (weather) {
        WeatherCondition.clear => 1.0,
        WeatherCondition.cloudy => 0.8,
        WeatherCondition.hot => 0.7,
        WeatherCondition.cold => 0.4,
        WeatherCondition.rain => 0.2,
        WeatherCondition.unknown => 0.8,
      };
    }
    return switch (weather) {
      WeatherCondition.rain || WeatherCondition.cold => 1.0,
      _ => 0.8,
    };
  }
}
