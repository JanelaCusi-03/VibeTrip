import 'dart:math' as math;

import '../../../../core/domain/tag_vector.dart';
import '../../../profile/domain/entities/user_profile.dart';

/// Aprendizaje en línea del vector de gustos (Entregable 2 §4).
class PreferenceVectorUpdater {
  const PreferenceVectorUpdater({
    this.learningRate = defaultLearningRate,
    this.sessionSignalCap = defaultSessionSignalCap,
    this.decayHalfLife = defaultDecayHalfLife,
  });

  /// `η`
  static const double defaultLearningRate = 0.15;

  /// Tope de `|Σs|` por (usuario, lugar, sesión).
  static const double defaultSessionSignalCap = 1.5;

  /// `H`: vida media del olvido temporal.
  static const Duration defaultDecayHalfLife = Duration(days: 30);

  final double learningRate;
  final double sessionSignalCap;
  final Duration decayHalfLife;

  /// `u ← clip(u + η · s · p)`.
  TagVector applySignal({
    required TagVector currentVector,
    required TagVector placeVector,
    required double signalWeight,
  }) =>
      (currentVector + placeVector.scaled(learningRate * signalWeight))
          .clipped();

  /// Recorta [signalWeight] para que `|accumulated + s| ≤ cap` y devuelve la
  /// señal que realmente se puede aplicar (0 si ya se alcanzó el tope).
  double capSessionSignal({
    required double accumulatedSignal,
    required double signalWeight,
  }) {
    final double cappedTotal = (accumulatedSignal + signalWeight)
        .clamp(-sessionSignalCap, sessionSignalCap);
    return cappedTotal - accumulatedSignal;
  }

  /// `Δ ← Δ · 2^(−Δt/H)`, `u ← clip(u₀ + Δ)`, con `Δ = u − u₀`.
  ///
  /// La primera vez solo registra la fecha; después atenúa la deriva
  /// aprendida según el tiempo transcurrido desde `lastDecayAppliedAt`.
  UserProfile applyTemporalDecay(UserProfile profile, DateTime now) {
    final DateTime? lastDecayAppliedAt = profile.lastDecayAppliedAt;
    if (lastDecayAppliedAt == null || !now.isAfter(lastDecayAppliedAt)) {
      return profile.copyWith(lastDecayAppliedAt: lastDecayAppliedAt ?? now);
    }
    final double elapsedHalfLives =
        now.difference(lastDecayAppliedAt).inMilliseconds /
            decayHalfLife.inMilliseconds;
    final double decayFactor = math.pow(2, -elapsedHalfLives).toDouble();
    final TagVector learnedDrift =
        profile.currentVector - profile.explicitVector;
    return profile.copyWith(
      currentVector:
          (profile.explicitVector + learnedDrift.scaled(decayFactor)).clipped(),
      lastDecayAppliedAt: now,
    );
  }
}
