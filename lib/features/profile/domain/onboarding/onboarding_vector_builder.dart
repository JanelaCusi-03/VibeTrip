import '../../../../core/domain/tag_vector.dart';
import 'onboarding_catalog.dart';

/// Respuesta del usuario a una carta del deck: `rᵢ ∈ {−1, +1, +2}`.
enum SwipeVerdict {
  dislike(-1),
  like(1),
  superlike(2);

  const SwipeVerdict(this.rating);

  final int rating;
}

/// Respuestas de los pasos A a C del onboarding.
class OnboardingAnswers {
  const OnboardingAnswers({
    this.selectedVibes = const <OnboardingVibe>[],
    this.swipeVerdicts = const <OnboardingCard, SwipeVerdict>{},
    this.dilemmaChoices = const <OnboardingDilemma, OnboardingCard>{},
  });

  final List<OnboardingVibe> selectedVibes;
  final Map<OnboardingCard, SwipeVerdict> swipeVerdicts;

  /// Opción elegida en cada dilema (A o B).
  final Map<OnboardingDilemma, OnboardingCard> dilemmaChoices;
}

/// Construye el vector inicial `u₀` (Entregable 2 §2):
///
/// `u₀ = clip(normalizar(α·p̂ + β·ŝ + γ·δ̂))`, con α = 0.30, β = 0.50, γ = 0.20.
class OnboardingVectorBuilder {
  const OnboardingVectorBuilder({
    this.vibePriorWeight = 0.30,
    this.swipeSignalWeight = 0.50,
    this.dilemmaContrastWeight = 0.20,
  });

  /// α
  final double vibePriorWeight;

  /// β
  final double swipeSignalWeight;

  /// γ
  final double dilemmaContrastWeight;

  TagVector build(OnboardingAnswers answers) {
    final TagVector combined =
        vibePrior(answers).normalized().scaled(vibePriorWeight) +
            swipeSignal(answers).normalized().scaled(swipeSignalWeight) +
            dilemmaContrast(answers).normalized().scaled(dilemmaContrastWeight);
    return combined.normalized().clipped();
  }

  /// `p = (1/|V|) · Σ π_v`
  TagVector vibePrior(OnboardingAnswers answers) {
    if (answers.selectedVibes.isEmpty) return TagVector.zero();
    return answers.selectedVibes
        .fold<TagVector>(TagVector.zero(), (sum, vibe) => sum + vibe.prior)
        .scaled(1 / answers.selectedVibes.length);
  }

  /// `s = Σ rᵢ · eᵢ`
  TagVector swipeSignal(OnboardingAnswers answers) =>
      answers.swipeVerdicts.entries.fold<TagVector>(
        TagVector.zero(),
        (sum, entry) =>
            sum + entry.key.tagVector.scaled(entry.value.rating.toDouble()),
      );

  /// `δ = Σ (e_elegida − e_descartada)`
  TagVector dilemmaContrast(OnboardingAnswers answers) =>
      answers.dilemmaChoices.entries.fold<TagVector>(
        TagVector.zero(),
        (sum, entry) {
          final OnboardingDilemma dilemma = entry.key;
          final OnboardingCard chosen = entry.value;
          final OnboardingCard rejected = identical(chosen, dilemma.optionA)
              ? dilemma.optionB
              : dilemma.optionA;
          return sum + chosen.tagVector - rejected.tagVector;
        },
      );
}
