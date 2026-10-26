import '../../../../core/domain/tag_catalog.dart';
import '../../../../core/domain/tag_vector.dart';
import '../../../places/domain/entities/place.dart';
import '../entities/recommendation_context.dart';

typedef _TagContribution = ({TagDefinition tag, double contribution});

/// Genera la explicación textual de una recomendación (RF-08, E2 §3.5).
///
/// Formato: `Recomendado porque te gusta: Tranquilo y Aire libre · a 1.2 km ·
/// ideal para esta hora`.
class RecommendationExplainer {
  const RecommendationExplainer({
    this.minimumTagContribution = 0.05,
    this.maximumExplainedTags = 2,
  });

  /// Umbral de `cᵢ = uᵢ · pᵢ` para mencionar una etiqueta.
  final double minimumTagContribution;
  final int maximumExplainedTags;

  String explain({
    required TagVector userVector,
    required Place place,
    required RecommendationContext context,
    double? distanceInMeters,
  }) {
    final List<String> topTagNames = topContributingTags(userVector, place)
        .map((tag) => tag.displayName)
        .toList();

    final List<String> parts = <String>[
      if (topTagNames.isEmpty)
        'Recomendado por tu contexto'
      else
        'Recomendado porque te gusta: ${_joinWithAnd(topTagNames)}',
      if (distanceInMeters != null) formatDistance(distanceInMeters),
      if (place.bestTimeBuckets.contains(context.timeBucket))
        'ideal para esta hora'
      else if (place.priceLevel <= context.budgetLevel)
        'dentro de tu presupuesto',
    ];
    return parts.join(' · ');
  }

  /// Etiquetas con mayor contribución positiva al producto punto.
  List<TagDefinition> topContributingTags(TagVector userVector, Place place) {
    final List<_TagContribution> contributions = <_TagContribution>[
      for (final TagDefinition tag in TagCatalog.all)
        (
          tag: tag,
          contribution:
              userVector[tag.vectorIndex] * place.tagVector[tag.vectorIndex],
        ),
    ]
      ..removeWhere((entry) => entry.contribution < minimumTagContribution)
      ..sort((left, right) => right.contribution.compareTo(left.contribution));
    return contributions
        .take(maximumExplainedTags)
        .map((entry) => entry.tag)
        .toList();
  }

  /// `a 650 m` (redondeado a decenas) o `a 1.2 km`.
  static String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      final int roundedMeters = (distanceInMeters / 10).round() * 10;
      return 'a $roundedMeters m';
    }
    return 'a ${(distanceInMeters / 1000).toStringAsFixed(1)} km';
  }

  static String _joinWithAnd(List<String> names) => names.length == 1
      ? names.single
      : '${names.sublist(0, names.length - 1).join(', ')} y ${names.last}';
}
