import 'package:flutter_test/flutter_test.dart';
import 'package:vibetrip/core/domain/tag_catalog.dart';
import 'package:vibetrip/core/domain/tag_vector.dart';
import 'package:vibetrip/core/domain/vector_math.dart';

void main() {
  group('vector_math', () {
    test('dotProduct suma los productos componente a componente', () {
      expect(dotProduct(<double>[1, 2, 3], <double>[4, 5, 6]), 32);
    });

    test('dotProduct rechaza dimensiones distintas', () {
      expect(
        () => dotProduct(<double>[1], <double>[1, 2]),
        throwsArgumentError,
      );
    });

    test('cosineSimilarity reproduce el ejemplo del Entregable 2 §3.4', () {
      final double similarity = cosineSimilarity(
        <double>[0.8, 0, 0.6],
        <double>[0.9, 0.1, 1.0],
      );
      expect(similarity, closeTo(0.9784, 1e-4));
    });

    test('cosineSimilarity es 0 para vectores ortogonales o nulos', () {
      expect(cosineSimilarity(<double>[1, 0], <double>[0, 1]), 0);
      expect(cosineSimilarity(<double>[0, 0], <double>[0, 1]), 0);
    });

    test('normalizeL2 deja norma 1 y conserva el vector nulo', () {
      expect(l2Norm(normalizeL2(<double>[3, 4])), closeTo(1, 1e-12));
      expect(normalizeL2(<double>[0, 0]), <double>[0, 0]);
    });

    test('clipComponents recorta a [-1, 1]', () {
      expect(clipComponents(<double>[-3, 0.5, 2]), <double>[-1, 0.5, 1]);
    });
  });

  group('TagCatalog', () {
    test('tiene 48 etiquetas en 6 grupos de 8, en el orden del seed SQL', () {
      expect(TagCatalog.all, hasLength(48));
      expect(TagCatalog.byIndex(0).slug, 'tranquilo');
      expect(TagCatalog.byIndex(8).group, TagGroup.actividad);
      expect(TagCatalog.byIndex(47).slug, 'mercado');
      for (final TagGroup group in TagGroup.values) {
        expect(
          TagCatalog.all.where((tag) => tag.group == group),
          hasLength(TagCatalog.tagsPerGroup),
        );
      }
    });

    test('bySlug encuentra etiquetas y rechaza las desconocidas', () {
      expect(TagCatalog.bySlug('aire_libre').vectorIndex, 8);
      expect(TagCatalog.contains('inexistente'), isFalse);
      expect(() => TagCatalog.bySlug('inexistente'), throwsArgumentError);
    });
  });

  group('TagVector', () {
    test('se construye desde pesos por slug y vuelve a ellos', () {
      final TagVector vector = TagVector.fromTagWeights(<String, double>{
        'tranquilo': 0.8,
        'aire_libre': 0.6,
      });
      expect(vector[0], 0.8);
      expect(vector[8], 0.6);
      expect(vector.toTagWeights(), <String, double>{
        'tranquilo': 0.8,
        'aire_libre': 0.6,
      });
      expect(vector.norm, closeTo(1, 1e-12));
    });

    test('rechaza dimensiones distintas de 48', () {
      expect(() => TagVector(<double>[1, 2]), throwsArgumentError);
    });

    test('operaciones aritméticas, recorte y normalización', () {
      final TagVector base = TagVector.fromTagWeights(<String, double>{
        'bar': 0.9,
      });
      final TagVector sum = base + base;
      expect(sum[26], 1.8);
      expect(sum.clipped()[26], 1);
      expect((sum - base)[26], closeTo(0.9, 1e-12));
      expect(base.scaled(-2)[26], -1.8);
      expect(sum.normalized().norm, closeTo(1, 1e-12));
      expect(base.dot(base), closeTo(0.81, 1e-12));
      expect(base.cosineSimilarity(sum), closeTo(1, 1e-12));
    });

    test('igualdad por valor y vector cero', () {
      expect(TagVector.zero(), TagVector.zero());
      expect(TagVector.zero().hashCode, TagVector.zero().hashCode);
      expect(TagVector.zero().isZero, isTrue);
      expect(
        TagVector.fromTagWeights(<String, double>{'arte': 1}),
        isNot(TagVector.zero()),
      );
      expect(TagVector.zero().toString(), 'TagVector({})');
    });
  });
}
