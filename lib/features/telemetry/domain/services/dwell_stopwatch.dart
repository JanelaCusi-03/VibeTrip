/// Cronómetro de permanencia de una tarjeta (Entregable 1 §1.3).
///
/// Solo corre mientras la tarjeta está visible al menos un
/// [minimumVisibleFraction] **y** la app está en primer plano. Cada vez que
/// una de las dos condiciones deja de cumplirse se cierra un período de
/// visualización y se devuelve su duración.
///
/// Es Dart puro: el widget `UserBehaviorTracker` solo le reenvía eventos.
class DwellStopwatch {
  DwellStopwatch({this.minimumVisibleFraction = 0.5});

  final double minimumVisibleFraction;

  double _visibleFraction = 0;
  bool _isAppInForeground = true;
  DateTime? _viewStartedAt;

  bool get isRunning => _viewStartedAt != null;

  /// Devuelve la duración si este cambio cerró un período de visualización.
  Duration? onVisibilityChanged(double visibleFraction, DateTime now) {
    _visibleFraction = visibleFraction;
    return _update(now);
  }

  Duration? onAppLifecycleChanged({
    required bool isInForeground,
    required DateTime now,
  }) {
    _isAppInForeground = isInForeground;
    return _update(now);
  }

  /// Cierra el período en curso (por ejemplo, al destruir el widget).
  Duration? stop(DateTime now) {
    final DateTime? viewStartedAt = _viewStartedAt;
    _viewStartedAt = null;
    return viewStartedAt == null ? null : now.difference(viewStartedAt);
  }

  Duration? _update(DateTime now) {
    final bool shouldRun =
        _isAppInForeground && _visibleFraction >= minimumVisibleFraction;
    if (shouldRun && !isRunning) {
      _viewStartedAt = now;
      return null;
    }
    if (!shouldRun && isRunning) return stop(now);
    return null;
  }
}
