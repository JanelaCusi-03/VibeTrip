import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:vibetrip/features/telemetry/presentation/user_behavior_tracker.dart';

void main() {
  late DateTime fakeNow;
  late List<Duration> reportedDurations;

  Widget buildTracker() => MaterialApp(
        home: UserBehaviorTracker(
          trackingId: 'mirador',
          clock: () => fakeNow,
          onViewEnded: reportedDurations.add,
          child: const SizedBox(width: 300, height: 200),
        ),
      );

  setUp(() {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    fakeNow = DateTime.utc(2026, 10, 24, 20);
    reportedDurations = <Duration>[];
  });

  testWidgets('reporta el tiempo visible al salir de pantalla', (tester) async {
    await tester.pumpWidget(buildTracker());
    await tester.pump();

    fakeNow = fakeNow.add(const Duration(seconds: 5));
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await tester.pump();

    expect(reportedDurations, <Duration>[const Duration(seconds: 5)]);
  });

  testWidgets('cierra el período cuando la app pasa a segundo plano', (
    tester,
  ) async {
    await tester.pumpWidget(buildTracker());
    await tester.pump();

    fakeNow = fakeNow.add(const Duration(seconds: 3));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    expect(reportedDurations, <Duration>[const Duration(seconds: 3)]);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    fakeNow = fakeNow.add(const Duration(seconds: 2));
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await tester.pump();

    expect(reportedDurations.last, const Duration(seconds: 2));
  });
}
