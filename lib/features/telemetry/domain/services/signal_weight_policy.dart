import 'dart:math' as math;

/// Ponderación de señales implícitas (Entregable 2 §4.1).
abstract final class SignalWeightPolicy {
  /// Por debajo de este tiempo la tarjeta cuenta como `impression_skip`.
  static const Duration impressionSkipThreshold = Duration(seconds: 1);

  /// `t_min`: el dwell empieza a sumar a partir de 2 s.
  static const int minimumDwellInMilliseconds = 2000;

  /// `w_max`: peso máximo alcanzable por dwell.
  static const double maximumDwellSignalWeight = 0.60;

  /// `τ`: constante de tiempo de la saturación exponencial.
  static const int dwellTimeConstantInMilliseconds = 6000;

  /// `w_dwell(t) = w_max · (1 − e^(−(t − t_min)/τ))` para `t ≥ t_min`.
  static double computeDwellSignalWeight(int dwellInMilliseconds) {
    if (dwellInMilliseconds < minimumDwellInMilliseconds) return 0;
    final double elapsedRatio =
        (dwellInMilliseconds - minimumDwellInMilliseconds) /
            dwellTimeConstantInMilliseconds;
    return maximumDwellSignalWeight * (1 - math.exp(-elapsedRatio));
  }
}
