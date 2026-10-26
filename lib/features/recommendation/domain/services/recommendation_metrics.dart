/// Métricas offline del recomendador para la sustentación (Entregable 5).
abstract final class RecommendationMetrics {
  /// `Precision@K = |relevantes ∩ top-K| / K`.
  ///
  /// Si la lista tiene menos de [k] elementos, el denominador sigue siendo
  /// [k] (los huecos cuentan como no relevantes).
  static double precisionAtK(
    List<String> rankedIds,
    Set<String> relevantIds,
    int k,
  ) {
    if (k <= 0) throw ArgumentError.value(k, 'k', 'Debe ser > 0');
    final int relevantInTopK =
        rankedIds.take(k).where(relevantIds.contains).length;
    return relevantInTopK / k;
  }

  static double mean(Iterable<double> values) {
    if (values.isEmpty) throw ArgumentError('Lista vacía');
    return values.reduce((sum, value) => sum + value) / values.length;
  }

  /// Percentil por el método del rango más cercano (p ∈ (0, 100]).
  static Duration percentile(List<Duration> samples, double percentileRank) {
    if (samples.isEmpty) throw ArgumentError('Sin muestras');
    if (percentileRank <= 0 || percentileRank > 100) {
      throw ArgumentError.value(percentileRank, 'percentileRank');
    }
    final List<Duration> sortedSamples = List<Duration>.of(samples)..sort();
    final int rank = (percentileRank / 100 * sortedSamples.length).ceil();
    return sortedSamples[rank - 1];
  }
}
