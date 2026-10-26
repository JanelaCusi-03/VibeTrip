import 'package:flutter/material.dart';

import '../../../../core/domain/context_types.dart';
import '../../../../core/domain/tag_weight.dart';
import '../../../../core/presentation/category_style.dart';
import '../../../places/domain/entities/place.dart';
import '../../domain/entities/recommendation_result.dart';
import '../../domain/services/recommendation_explainer.dart';

/// Tarjeta del feed: categoría, porcentaje de *match* y explicación.
class PlaceRecommendationCard extends StatelessWidget {
  const PlaceRecommendationCard({
    required this.result,
    required this.isFavorite,
    required this.onTap,
    required this.onFavoriteToggled,
    super.key,
  });

  final RecommendationResult result;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggled;

  @override
  Widget build(BuildContext context) {
    final Place place = result.place;
    final ThemeData theme = Theme.of(context);
    final Color categoryColor = CategoryStyle.colorOf(place.category);
    final double? distanceInMeters = result.distanceInMeters;
    final String subtitle = <String>[
      place.category.name,
      PriceLevel.toSymbols(place.priceLevel),
      if (distanceInMeters != null)
        RecommendationExplainer.formatDistance(distanceInMeters),
    ].join(' · ');

    return Card(
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              height: 96,
              color: categoryColor.withValues(alpha: 0.85),
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(
                    CategoryStyle.iconOf(place.category),
                    color: Colors.white,
                    size: 40,
                  ),
                  const Spacer(),
                  _MatchBadge(matchScore: result.matchScore),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 4, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(place.name, style: theme.textTheme.titleMedium),
                        const SizedBox(height: 2),
                        Text(subtitle, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: isFavorite
                        ? 'Quitar de favoritos'
                        : 'Guardar en favoritos',
                    onPressed: onFavoriteToggled,
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                    ),
                    color: isFavorite ? Colors.redAccent : null,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(
                result.explanation,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: <Widget>[
                  for (final TagWeight tagWeight in place.topTagWeights())
                    Chip(
                      label: Text(tagWeight.tag.displayName),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchBadge extends StatelessWidget {
  const _MatchBadge({required this.matchScore});

  final int matchScore;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Afinidad $matchScore por ciento',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: ExcludeSemantics(
          child: Text(
            '$matchScore % match',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
          ),
        ),
      ),
    );
  }
}
