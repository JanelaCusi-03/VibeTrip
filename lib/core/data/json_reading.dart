/// Lectura tipada de JSON decodificado (compatible con `strict-casts`).
library;

typedef JsonMap = Map<String, Object?>;

extension JsonReading on JsonMap {
  T read<T>(String key) {
    final Object? value = this[key];
    if (value is T) return value;
    throw FormatException(
      'Campo "$key" inválido: se esperaba $T y llegó $value',
    );
  }

  T? readOptional<T>(String key) {
    final Object? value = this[key];
    if (value is T) return value;
    if (value == null) return null;
    throw FormatException(
      'Campo "$key" inválido: se esperaba $T y llegó $value',
    );
  }

  /// Números JSON pueden llegar como `int` aunque representen `double`.
  double readDouble(String key) => read<num>(key).toDouble();

  double? readOptionalDouble(String key) => readOptional<num>(key)?.toDouble();

  List<String> readStringList(String key) =>
      (readOptional<List<Object?>>(key) ?? const <Object?>[])
          .cast<String>()
          .toList();

  JsonMap readMap(String key) => read<Map<String, Object?>>(key);

  /// Mapa `{"slug": peso}` con pesos numéricos.
  Map<String, double> readWeightMap(String key) => <String, double>{
        for (final MapEntry<String, Object?> entry
            in (readOptional<Map<String, Object?>>(key) ??
                    const <String, Object?>{})
                .entries)
          entry.key: (entry.value! as num).toDouble(),
      };
}
