import 'dart:math' as math;

import 'scoring_strategy.dart';

/// `A(u, p) = max(0, cos(u, p))` (Entregable 2 §3.1).
class AffinityScoringStrategy implements ScoringStrategy {
  const AffinityScoringStrategy({this.weight = defaultWeight});

  static const double defaultWeight = 0.60;

  @override
  final double weight;

  @override
  String get factorName => 'affinity';

  @override
  double score(ScoringInput input) =>
      math.max(0, input.userVector.cosineSimilarity(input.place.tagVector));
}
