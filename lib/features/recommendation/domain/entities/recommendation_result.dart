import '../../../places/domain/entities/place.dart';

/// Lugar puntuado por el motor, listo para mostrar en el feed (RF-07, RF-08).
class RecommendationResult {
  const RecommendationResult({
    required this.place,
    required this.matchScore,
    required this.explanation,
    required this.factorScores,
    this.distanceInMeters,
  });

  final Place place;

  /// Afinidad total de 0 a 100 %.
  final int matchScore;
  final String explanation;

  /// `null` si no se conoce la ubicación del usuario.
  final double? distanceInMeters;

  /// Valor en [0, 1] de cada factor (`affinity`, `proximity`, `context`),
  /// útil para depurar y para la sustentación.
  final Map<String, double> factorScores;

  @override
  String toString() => 'RecommendationResult(${place.name}, $matchScore %)';
}
