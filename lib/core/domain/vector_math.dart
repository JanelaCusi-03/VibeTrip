/// Operaciones vectoriales del motor (Entregable 2 §1 y §3.1).
library;

import 'dart:math' as math;

double dotProduct(List<double> left, List<double> right) {
  _assertSameLength(left, right);
  double sum = 0;
  for (int index = 0; index < left.length; index++) {
    sum += left[index] * right[index];
  }
  return sum;
}

double l2Norm(List<double> vector) => math.sqrt(dotProduct(vector, vector));

/// Similitud del coseno; devuelve 0 si alguno de los vectores es nulo.
double cosineSimilarity(List<double> left, List<double> right) {
  final double normProduct = l2Norm(left) * l2Norm(right);
  if (normProduct == 0) return 0;
  return dotProduct(left, right) / normProduct;
}

/// Normalización L2 (`x̂ = x / ‖x‖₂`); el vector nulo se devuelve igual.
List<double> normalizeL2(List<double> vector) {
  final double norm = l2Norm(vector);
  if (norm == 0) return List<double>.of(vector);
  return <double>[for (final double value in vector) value / norm];
}

/// Recorta cada componente al intervalo [minimum, maximum].
List<double> clipComponents(
  List<double> vector, {
  double minimum = -1,
  double maximum = 1,
}) =>
    <double>[
      for (final double value in vector) value.clamp(minimum, maximum),
    ];

void _assertSameLength(List<double> left, List<double> right) {
  if (left.length != right.length) {
    throw ArgumentError(
      'Dimensiones distintas: ${left.length} y ${right.length}',
    );
  }
}
