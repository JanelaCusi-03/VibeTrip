import 'package:flutter/widgets.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../domain/services/dwell_stopwatch.dart';

/// Envuelve una tarjeta o pantalla de detalle y mide cuánto tiempo se ve
/// (RF-04). Cada período de visualización cerrado se publica en
/// [onViewEnded]; quien escucha decide qué hacer (patrón Observer), por lo
/// que el widget no conoce el servicio de telemetría.
class UserBehaviorTracker extends StatefulWidget {
  const UserBehaviorTracker({
    required this.trackingId,
    required this.onViewEnded,
    required this.child,
    this.clock = DateTime.now,
    this.minimumVisibleFraction = 0.5,
    super.key,
  });

  /// Identificador estable del elemento (por ejemplo, el id del lugar).
  final String trackingId;
  final ValueChanged<Duration> onViewEnded;
  final Widget child;
  final DateTime Function() clock;
  final double minimumVisibleFraction;

  @override
  State<UserBehaviorTracker> createState() => _UserBehaviorTrackerState();
}

class _UserBehaviorTrackerState extends State<UserBehaviorTracker>
    with WidgetsBindingObserver {
  late final DwellStopwatch _stopwatch = DwellStopwatch(
    minimumVisibleFraction: widget.minimumVisibleFraction,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _report(
      _stopwatch.onAppLifecycleChanged(
        isInForeground: state == AppLifecycleState.resumed,
        now: widget.clock(),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _report(_stopwatch.stop(widget.clock()));
    super.dispose();
  }

  void _report(Duration? viewDuration) {
    if (viewDuration != null) widget.onViewEnded(viewDuration);
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: ValueKey<String>('behavior-tracker-${widget.trackingId}'),
      onVisibilityChanged: (visibilityInfo) {
        if (!mounted) return;
        _report(
          _stopwatch.onVisibilityChanged(
            visibilityInfo.visibleFraction,
            widget.clock(),
          ),
        );
      },
      child: widget.child,
    );
  }
}
