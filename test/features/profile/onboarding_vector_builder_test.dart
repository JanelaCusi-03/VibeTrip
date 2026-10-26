import 'package:flutter_test/flutter_test.dart';
import 'package:vibetrip/core/domain/tag_catalog.dart';
import 'package:vibetrip/core/domain/tag_vector.dart';
import 'package:vibetrip/features/profile/domain/onboarding/onboarding_catalog.dart';
import 'package:vibetrip/features/profile/domain/onboarding/onboarding_vector_builder.dart';

int indexOf(String slug) => TagCatalog.bySlug(slug).vectorIndex;

OnboardingCard cardById(String id) =>
    OnboardingCatalog.swipeDeck.firstWhere((card) => card.id == id);

OnboardingVibe vibeById(String id) =>
    OnboardingCatalog.vibes.firstWhere((vibe) => vibe.id == id);

void main() {
  const OnboardingVectorBuilder builder = OnboardingVectorBuilder();

  group('OnboardingCatalog', () {
    test('8 vibes, 12 cartas (2 por grupo) y 3 dilemas', () {
      expect(OnboardingCatalog.vibes, hasLength(8));
      expect(OnboardingCatalog.swipeDeck, hasLength(12));
      expect(OnboardingCatalog.dilemmas, hasLength(3));
      for (final TagGroup group in TagGroup.values) {
        expect(
          OnboardingCatalog.swipeDeck.where((card) => card.group == group),
          hasLength(2),
          reason: group.name,
        );
      }
    });
  });

  group('OnboardingVectorBuilder', () {
    test('sin respuestas devuelve el vector cero (saltar onboarding)', () {
      expect(builder.build(const OnboardingAnswers()).isZero, isTrue);
    });

    test('el resultado es unitario y está en [-1, 1]', () {
      final TagVector initialVector = builder.build(
        OnboardingAnswers(
          selectedVibes: <OnboardingVibe>[vibeById('cultura')],
          swipeVerdicts: <OnboardingCard, SwipeVerdict>{
            cardById('ruinas_incas'): SwipeVerdict.superlike,
            cardById('discoteca'): SwipeVerdict.dislike,
          },
          dilemmaChoices: <OnboardingDilemma, OnboardingCard>{
            OnboardingCatalog.dilemmas.first:
                OnboardingCatalog.dilemmas.first.optionA,
          },
        ),
      );
      expect(initialVector.norm, closeTo(1, 1e-9));
      for (final double component in initialVector.components) {
        expect(component, inInclusiveRange(-1, 1));
      }
      expect(initialVector[indexOf('historico')], greaterThan(0));
      expect(initialVector[indexOf('discoteca')], lessThan(0));
    });

    test('el prior promedia las vibes elegidas', () {
      final TagVector prior = builder.vibePrior(
        OnboardingAnswers(
          selectedVibes: <OnboardingVibe>[
            vibeById('relax'),
            vibeById('fiesta'),
          ],
        ),
      );
      expect(prior[indexOf('tranquilo')], 0.5);
      expect(prior[indexOf('vida_nocturna')], 0.5);
    });

    test('superlike pesa el doble que like', () {
      final TagVector signal = builder.swipeSignal(
        OnboardingAnswers(
          swipeVerdicts: <OnboardingCard, SwipeVerdict>{
            cardById('trekking'): SwipeVerdict.superlike,
            cardById('cafe_tranquilo'): SwipeVerdict.like,
          },
        ),
      );
      expect(signal[indexOf('aventura')], 2);
      expect(signal[indexOf('tranquilo')], 1);
    });

    test('el dilema suma la opción elegida y resta la descartada', () {
      final OnboardingDilemma nightDilemma = OnboardingCatalog.dilemmas.last;
      final TagVector contrast = builder.dilemmaContrast(
        OnboardingAnswers(
          dilemmaChoices: <OnboardingDilemma, OnboardingCard>{
            nightDilemma: nightDilemma.optionB,
          },
        ),
      );
      expect(contrast[indexOf('terraza')], 1);
      expect(contrast[indexOf('bar')], -1);
    });
  });
}
