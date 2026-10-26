import 'tag_catalog.dart';
import 'tag_vector.dart';

/// Peso de una etiqueta del catálogo (fila de `place_tags` o componente de `u`).
class TagWeight {
  const TagWeight({required this.tag, required this.weight});

  final TagDefinition tag;
  final double weight;

  /// Etiquetas con peso distinto de cero, ordenadas de mayor a menor peso.
  static List<TagWeight> rankedFromVector(TagVector vector) {
    final List<TagWeight> tagWeights = <TagWeight>[
      for (final TagDefinition tag in TagCatalog.all)
        if (vector[tag.vectorIndex] != 0)
          TagWeight(tag: tag, weight: vector[tag.vectorIndex]),
    ];
    tagWeights.sort((left, right) => right.weight.compareTo(left.weight));
    return tagWeights;
  }

  @override
  bool operator ==(Object other) =>
      other is TagWeight &&
      other.tag.slug == tag.slug &&
      other.weight == weight;

  @override
  int get hashCode => Object.hash(tag.slug, weight);

  @override
  String toString() => 'TagWeight(${tag.slug}: $weight)';
}
