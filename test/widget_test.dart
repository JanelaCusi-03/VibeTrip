import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vibetrip/app.dart';

void main() {
  testWidgets('VibeTripApp muestra el título de la aplicación', (tester) async {
    await tester.pumpWidget(const VibeTripApp());

    expect(find.text(VibeTripApp.applicationTitle), findsOneWidget);
  });

  testWidgets('VibeTripApp usa Material 3', (tester) async {
    await tester.pumpWidget(const VibeTripApp());

    final MaterialApp materialApp = tester.widget(find.byType(MaterialApp));
    expect(materialApp.theme?.useMaterial3, isTrue);
  });
}
