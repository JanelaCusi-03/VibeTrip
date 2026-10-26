import 'dart:math' as math;

import 'scoring_strategy.dart';

/// `G(dist) = 2^(−dist / d½)`, con `d½ = radio / 2` (Entregable 2 §3.2).
///
/// Sin ubicación conocida devuelve [unknownLocationScore] para todos los
/// lugares, de modo que el factor no altera el orden relativo.
class ProximityScoringStrategy implements ScoringStrategy {
  const ProximityScoringStrategy({this.weight = defaultWeight});

  static const double defaultWeight = 0.20;
  static const double unknownLocationScore = 0.5;

  @override
  final double weight;

  @override
  String get factorName => 'proximity';

  @override
  double score(ScoringInput input) {
    final double? distanceInMeters = input.distanceInMeters;
    if (distanceInMeters == null) return unknownLocationScore;
    final double halfLifeDistanceInMeters =
        input.context.searchRadiusInMeters / 2;
    return math.pow(2, -distanceInMeters / halfLifeDistanceInMeters).toDouble();
  }
}
