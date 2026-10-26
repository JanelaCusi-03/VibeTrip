# Línea base: ranking de 500 candidatos (RNF-01)

**Fecha:** 2026-10-26 · **Commit:** rama `feat/entregable-5`
**Prueba:** `test/evaluation/recommender_evaluation_test.dart`

| Métrica | Valor | Requisito |
|---|---|---|
| p50 | 1.8 ms | — |
| p95 | 3.6 ms | ≤ 150 ms |

- **Entorno:** `flutter test` (VM de Dart, JIT) en la PC de desarrollo con Windows 11; 100 corridas tras 5 de calentamiento; 500 lugares sintéticos con semilla `Random(42)`.
- **Decisión:** el requisito se cumple con amplio margen, así que **no se optimiza** (criterio de optimización del README: solo se optimiza si un requisito falla).
- **Pendiente:** repetir la medición en un celular con `flutter run --profile` y DevTools, y anotarla aquí como «después».
