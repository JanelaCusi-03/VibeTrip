import '../../../../../core/domain/tag_vector.dart';
import '../../../../places/domain/entities/place.dart';
import '../../entities/recommendation_context.dart';

/// Datos que recibe cada estrategia para puntuar un lugar.
class ScoringInput {
  const ScoringInput({
    required this.userVector,
    required this.place,
    required this.context,
    this.distanceInMeters,
  });

  final TagVector userVector;
  final Place place;
  final RecommendationContext context;

  /// `null` si no se conoce la ubicación del usuario.
  final double? distanceInMeters;
}

/// Un factor del puntaje híbrido (patrón Strategy, Entregable 2 §3).
///
/// Cada estrategia devuelve un valor en [0, 1] y declara su peso; el motor
/// combina `Σ wᵢ · scoreᵢ / Σ wᵢ`.
abstract interface class ScoringStrategy {
  /// Clave del factor en [RecommendationResult.factorScores].
  String get factorName;

  double get weight;

  double score(ScoringInput input);
}
