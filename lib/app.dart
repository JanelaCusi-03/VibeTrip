import 'package:flutter/material.dart';

/// Raíz de la aplicación VibeTrip.
///
/// Es un esqueleto: en el Entregable 2 se reemplaza por la configuración
/// con Riverpod y go_router.
class VibeTripApp extends StatelessWidget {
  const VibeTripApp({super.key});

  static const String applicationTitle = 'VibeTrip';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: applicationTitle,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Text(applicationTitle),
        ),
      ),
    );
  }
}
