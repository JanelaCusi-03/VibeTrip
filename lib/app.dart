import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers/dependency_providers.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

/// Raíz de la aplicación VibeTrip: tema Material 3 y navegación go_router.
///
/// También programa el envío de la telemetría pendiente cada
/// [telemetryFlushInterval] y al pasar la app a segundo plano (E1 §1.3).
class VibeTripApp extends ConsumerStatefulWidget {
  const VibeTripApp({super.key});

  static const String applicationTitle = 'VibeTrip';
  static const Duration telemetryFlushInterval = Duration(seconds: 30);

  @override
  ConsumerState<VibeTripApp> createState() => _VibeTripAppState();
}

class _VibeTripAppState extends ConsumerState<VibeTripApp> {
  late final AppLifecycleListener _lifecycleListener;
  late final Timer _flushTimer;

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(onPause: _flushTelemetry);
    _flushTimer = Timer.periodic(
      VibeTripApp.telemetryFlushInterval,
      (_) => _flushTelemetry(),
    );
  }

  void _flushTelemetry() =>
      unawaited(ref.read(interactionRepositoryProvider).flush());

  @override
  void dispose() {
    _flushTimer.cancel();
    _lifecycleListener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: VibeTripApp.applicationTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
