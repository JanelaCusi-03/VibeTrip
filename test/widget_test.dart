import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:vibetrip/app.dart';

import 'helpers/app_harness.dart';

void main() {
  setUp(() {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  Future<void> skipOnboarding(WidgetTester tester) async {
    await tester.tap(find.text('Saltar'));
    await tester.pumpAndSettle();
  }

  testWidgets('la app usa Material 3 y abre en el onboarding', (tester) async {
    await pumpVibeTrip(tester);

    final MaterialApp materialApp = tester.widget(find.byType(MaterialApp));
    expect(materialApp.theme?.useMaterial3, isTrue);
    expect(materialApp.title, VibeTripApp.applicationTitle);
    expect(find.text('¿Qué vibe buscas en tu viaje?'), findsOneWidget);
    expect(find.text('Saltar'), findsOneWidget);
  });

  testWidgets('saltar el onboarding lleva al feed con % de match (RF-02)', (
    tester,
  ) async {
    await pumpVibeTrip(tester);
    await skipOnboarding(tester);

    expect(find.text('¿Qué plan buscas hoy?'), findsOneWidget);
    expect(find.textContaining('% match'), findsWidgets);
    expect(find.text('Atardecer · Despejado · Tu ubicación'), findsOneWidget);
  });

  testWidgets('onboarding completo: vibes, 12 cartas, 3 dilemas y ajustes', (
    tester,
  ) async {
    await pumpVibeTrip(tester);

    await tester.tap(find.textContaining('Relax'));
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();

    for (int cardNumber = 1; cardNumber <= 12; cardNumber++) {
      expect(find.textContaining('($cardNumber/12)'), findsOneWidget);
      await tester.tap(find.byTooltip('Me gusta'));
      await tester.pumpAndSettle();
    }

    for (int dilemma = 0; dilemma < 3; dilemma++) {
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();
    }

    expect(find.text('Último paso'), findsOneWidget);
    await tester.tap(find.text('Ver mis recomendaciones'));
    await tester.pumpAndSettle();

    expect(find.text('¿Qué plan buscas hoy?'), findsOneWidget);
  });

  testWidgets('el filtro «Económico» oculta lugares caros (RF-06)', (
    tester,
  ) async {
    await pumpVibeTrip(tester);
    await skipOnboarding(tester);
    expect(find.text('Restaurante caro'), findsOneWidget);

    await tester.tap(find.text('Económico'));
    await tester.pumpAndSettle();

    expect(find.text('Restaurante caro'), findsNothing);
    expect(find.text('Mirador de prueba'), findsOneWidget);
  });

  testWidgets('favorito desde la tarjeta cambia el ícono (RF-11)', (
    tester,
  ) async {
    await pumpVibeTrip(tester);
    await skipOnboarding(tester);

    await tester.tap(find.byTooltip('Guardar en favoritos').first);
    await tester.pumpAndSettle();

    expect(find.byTooltip('Quitar de favoritos'), findsOneWidget);
  });

  testWidgets('«No me interesa» quita el lugar del feed (RF-12)', (
    tester,
  ) async {
    await pumpVibeTrip(tester);
    await skipOnboarding(tester);

    await tester.tap(find.text('Bar de prueba'));
    await tester.pumpAndSettle();
    expect(find.text('Cómo llegar'), findsOneWidget);
    expect(find.text('¿Por qué este puntaje?'), findsOneWidget);

    await tester.tap(find.text('No me interesa'));
    await tester.pumpAndSettle();

    expect(find.text('¿Qué plan buscas hoy?'), findsOneWidget);
    expect(find.text('Bar de prueba'), findsNothing);
  });

  testWidgets('eliminar datos vuelve al onboarding (RF-16)', (tester) async {
    await pumpVibeTrip(tester);
    await skipOnboarding(tester);

    await tester.tap(find.byTooltip('Mi perfil y privacidad'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar todos mis datos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();

    expect(find.text('¿Qué vibe buscas en tu viaje?'), findsOneWidget);
  });
}
