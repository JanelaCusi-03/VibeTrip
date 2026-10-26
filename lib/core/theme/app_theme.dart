import 'package:flutter/material.dart';

/// Tema Material 3 de VibeTrip.
///
/// Las áreas táctiles mínimas de 48 dp (RNF-13) vienen de
/// `MaterialTapTargetSize.padded`, el valor por defecto en móviles.
abstract final class AppTheme {
  static const Color seedColor = Color(0xFF00897B);

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );
    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      cardTheme: const CardThemeData(
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      chipTheme: const ChipThemeData(showCheckmark: false),
    );
  }
}
