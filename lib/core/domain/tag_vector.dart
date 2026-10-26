import 'tag_catalog.dart';
import 'vector_math.dart' as vector_math;

/// Vector inmutable de [TagCatalog.dimension] componentes.
///
/// Representa tanto el vector de un lugar (`p`, componentes en [0, 1])
/// como el de gustos de un usuario (`u`, componentes en [-1, 1]).
class TagVector {
  TagVector(List<double> components)
      : components = List<double>.unmodifiable(components) {
    if (components.length != TagCatalog.dimension) {
      throw ArgumentError(
        'Se esperaban ${TagCatalog.dimension} componentes y '
        'llegaron ${components.length}',
      );
    }
  }

  factory TagVector.zero() =>
      TagVector(List<double>.filled(TagCatalog.dimension, 0));

  /// Construye el vector a partir de pesos por slug (`{"tranquilo": 0.9}`).
  factory TagVector.fromTagWeights(Map<String, double> weightsBySlug) {
    final List<double> components = List<double>.filled(
      TagCatalog.dimension,
      0,
    );
    weightsBySlug.forEach((slug, weight) {
      components[TagCatalog.bySlug(slug).vectorIndex] = weight;
    });
    return TagVector(components);
  }

  final List<double> components;

  double operator [](int vectorIndex) => components[vectorIndex];

  bool get isZero => components.every((value) => value == 0);

  double get norm => vector_math.l2Norm(components);

  double dot(TagVector other) =>
      vector_math.dotProduct(components, other.components);

  double cosineSimilarity(TagVector other) =>
      vector_math.cosineSimilarity(components, other.components);

  TagVector operator +(TagVector other) => TagVector(<double>[
        for (int index = 0; index < components.length; index++)
          components[index] + other.components[index],
      ]);

  TagVector operator -(TagVector other) => TagVector(<double>[
        for (int index = 0; index < components.length; index++)
          components[index] - other.components[index],
      ]);

  TagVector scaled(double factor) => TagVector(<double>[
        for (final double value in components) value * factor,
      ]);

  TagVector normalized() => TagVector(vector_math.normalizeL2(components));

  /// Recorta al rango de gustos del usuario [-1, 1].
  TagVector clipped() => TagVector(vector_math.clipComponents(components));

  /// Pesos distintos de cero indexados por slug (vista legible `tag_weights`).
  Map<String, double> toTagWeights() => <String, double>{
        for (final TagDefinition tag in TagCatalog.all)
          if (components[tag.vectorIndex] != 0)
            tag.slug: components[tag.vectorIndex],
      };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TagVector) return false;
    for (int index = 0; index < components.length; index++) {
      if (components[index] != other.components[index]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(components);

  @override
  String toString() => 'TagVector(${toTagWeights()})';
}
