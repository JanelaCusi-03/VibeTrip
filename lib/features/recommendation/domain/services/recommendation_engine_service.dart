import '../../../../core/domain/geo_distance.dart';
import '../../../places/domain/entities/place.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../entities/recommendation_context.dart';
import '../entities/recommendation_result.dart';
import 'recommendation_explainer.dart';
import 'scoring/affinity_scoring_strategy.dart';
import 'scoring/context_scoring_strategy.dart';
import 'scoring/proximity_scoring_strategy.dart';
import 'scoring/scoring_strategy.dart';

/// Motor de recomendación híbrido (Entregable 2 §3).
///
/// `S = Σ wᵢ · scoreᵢ / Σ wᵢ` con afinidad (0.60), proximidad (0.20) y
/// contexto (0.20); `matchScore = round(100 · S)`.
class RecommendationEngineService {
  RecommendationEngineService({
    List<ScoringStrategy>? scoringStrategies,
    this.explainer = const RecommendationExplainer(),
  }) : scoringStrategies = List<ScoringStrategy>.unmodifiable(
          scoringStrategies ?? defaultScoringStrategies,
        ) {
    if (_totalWeight <= 0) {
      throw ArgumentError('La suma de pesos de las estrategias debe ser > 0');
    }
  }

  static const List<ScoringStrategy> defaultScoringStrategies =
      <ScoringStrategy>[
    AffinityScoringStrategy(),
    ProximityScoringStrategy(),
    ContextScoringStrategy(),
  ];

  final List<ScoringStrategy> scoringStrategies;
  final RecommendationExplainer explainer;

  double get _totalWeight => scoringStrategies.fold<double>(
        0,
        (sum, strategy) => sum + strategy.weight,
      );

  /// Devuelve los candidatos elegibles ordenados de mayor a menor afinidad.
  ///
  /// Excluye lugares inactivos, descartados (RF-12), fuera del radio y por
  /// encima de [RecommendationContext.maximumPriceLevel].
  List<RecommendationResult> rank({
    required UserProfile profile,
    required List<Place> candidatePlaces,
    required RecommendationContext context,
    int? limit,
  }) {
    final double totalWeight = _totalWeight;
    final List<_ScoredResult> scoredResults = <_ScoredResult>[];

    for (final Place place in candidatePlaces) {
      if (!_isEligible(place, profile, context)) continue;

      final double? distanceInMeters = context.userLocation == null
          ? null
          : computeHaversineDistanceInMeters(
              context.userLocation!,
              place.location,
            );
      if (distanceInMeters != null &&
          distanceInMeters > context.searchRadiusInMeters) {
        continue;
      }

      final ScoringInput input = ScoringInput(
        userVector: profile.currentVector,
        place: place,
        context: context,
        distanceInMeters: distanceInMeters,
      );
      final Map<String, double> factorScores = <String, double>{
        for (final ScoringStrategy strategy in scoringStrategies)
          strategy.factorName: strategy.score(input),
      };
      final double hybridScore = scoringStrategies.fold<double>(
            0,
            (sum, strategy) =>
                sum + strategy.weight * factorScores[strategy.factorName]!,
          ) /
          totalWeight;

      scoredResults.add(
        _ScoredResult(
          hybridScore: hybridScore,
          result: RecommendationResult(
            place: place,
            matchScore: (hybridScore * 100).round().clamp(0, 100),
            distanceInMeters: distanceInMeters,
            factorScores: factorScores,
            explanation: explainer.explain(
              userVector: profile.currentVector,
              place: place,
              context: context,
              distanceInMeters: distanceInMeters,
            ),
          ),
        ),
      );
    }

    scoredResults.sort(_compareScoredResults);
    final Iterable<RecommendationResult> rankedResults =
        scoredResults.map((scored) => scored.result);
    return (limit == null ? rankedResults : rankedResults.take(limit)).toList();
  }

  bool _isEligible(
    Place place,
    UserProfile profile,
    RecommendationContext context,
  ) {
    if (!place.isActive || profile.isDiscarded(place.id)) return false;
    final int? maximumPriceLevel = context.maximumPriceLevel;
    return maximumPriceLevel == null || place.priceLevel <= maximumPriceLevel;
  }

  /// Mayor puntaje exacto primero; empate: más cercano y luego por nombre.
  static int _compareScoredResults(_ScoredResult left, _ScoredResult right) {
    final int byScore = right.hybridScore.compareTo(left.hybridScore);
    if (byScore != 0) return byScore;
    final int byDistance = (left.result.distanceInMeters ?? 0).compareTo(
      right.result.distanceInMeters ?? 0,
    );
    if (byDistance != 0) return byDistance;
    return left.result.place.name.compareTo(right.result.place.name);
  }
}

class _ScoredResult {
  const _ScoredResult({required this.hybridScore, required this.result});

  /// `S` sin redondear, para ordenar con toda la precisión.
  final double hybridScore;
  final RecommendationResult result;
}
