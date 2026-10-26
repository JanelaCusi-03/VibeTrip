import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vibetrip/app.dart';

void main() {
  testWidgets('VibeTripApp muestra el título de la aplicación', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: VibeTripApp()));
    await tester.pumpAndSettle();

    expect(find.text(VibeTripApp.applicationTitle), findsOneWidget);
  });

  testWidgets('VibeTripApp usa Material 3', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: VibeTripApp()));

    final MaterialApp materialApp = tester.widget(find.byType(MaterialApp));
    expect(materialApp.theme?.useMaterial3, isTrue);
    expect(materialApp.title, VibeTripApp.applicationTitle);
  });
}
