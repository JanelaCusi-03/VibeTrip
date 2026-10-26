import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/context_types.dart';
import '../domain/entities/user_profile.dart';
import '../domain/onboarding/onboarding_catalog.dart';
import '../domain/onboarding/onboarding_vector_builder.dart';
import 'user_profile_controller.dart';

/// Onboarding gamificado (HU-01): vibes → deck swipe → dilemas A/B →
/// presupuesto y compañía. «Saltar» siempre está visible (RF-02).
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  static const int stepCount = 4;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _currentStep = 0;
  int _currentCardIndex = 0;
  int _currentDilemmaIndex = 0;
  bool _isSaving = false;

  final List<OnboardingVibe> _selectedVibes = <OnboardingVibe>[];
  final Map<OnboardingCard, SwipeVerdict> _swipeVerdicts =
      <OnboardingCard, SwipeVerdict>{};
  final Map<OnboardingDilemma, OnboardingCard> _dilemmaChoices =
      <OnboardingDilemma, OnboardingCard>{};
  int _budgetLevel = UserProfile.defaultBudget;
  CompanionType _companion = CompanionType.solo;
  bool _hasTelemetryConsent = false;

  void _goToNextStep() => setState(() => _currentStep++);

  void _toggleVibe(OnboardingVibe vibe) => setState(() {
        if (!_selectedVibes.remove(vibe) &&
            _selectedVibes.length < OnboardingCatalog.maximumSelectedVibes) {
          _selectedVibes.add(vibe);
        }
      });

  void _rateCard(SwipeVerdict verdict) => setState(() {
        _swipeVerdicts[OnboardingCatalog.swipeDeck[_currentCardIndex]] =
            verdict;
        _currentCardIndex++;
        if (_currentCardIndex == OnboardingCatalog.swipeDeck.length) {
          _currentStep++;
        }
      });

  void _chooseDilemmaOption(OnboardingCard chosenOption) => setState(() {
        _dilemmaChoices[OnboardingCatalog.dilemmas[_currentDilemmaIndex]] =
            chosenOption;
        _currentDilemmaIndex++;
        if (_currentDilemmaIndex == OnboardingCatalog.dilemmas.length) {
          _currentStep++;
        }
      });

  Future<void> _finish() async {
    setState(() => _isSaving = true);
    await ref.read(userProfileControllerProvider.notifier).completeOnboarding(
          answers: OnboardingAnswers(
            selectedVibes: List<OnboardingVibe>.of(_selectedVibes),
            swipeVerdicts: Map<OnboardingCard, SwipeVerdict>.of(_swipeVerdicts),
            dilemmaChoices:
                Map<OnboardingDilemma, OnboardingCard>.of(_dilemmaChoices),
          ),
          budgetLevel: _budgetLevel,
          companion: _companion,
          hasTelemetryConsent: _hasTelemetryConsent,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Tus gustos · paso ${_currentStep + 1} de ${OnboardingScreen.stepCount}',
        ),
        actions: <Widget>[
          if (_currentStep < OnboardingScreen.stepCount - 1)
            TextButton(
              onPressed: _isSaving ? null : _finish,
              child: const Text('Saltar'),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_currentStep + 1) / OnboardingScreen.stepCount,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: switch (_currentStep) {
            0 => _VibeStep(
                selectedVibes: _selectedVibes,
                onVibeToggled: _toggleVibe,
                onNext: _goToNextStep,
              ),
            1 => _SwipeStep(
                card: OnboardingCatalog.swipeDeck[_currentCardIndex],
                cardNumber: _currentCardIndex + 1,
                onRated: _rateCard,
              ),
            2 => _DilemmaStep(
                dilemma: OnboardingCatalog.dilemmas[_currentDilemmaIndex],
                onOptionChosen: _chooseDilemmaOption,
              ),
            _ => _PreferencesStep(
                budgetLevel: _budgetLevel,
                companion: _companion,
                hasTelemetryConsent: _hasTelemetryConsent,
                isSaving: _isSaving,
                onBudgetChanged: (level) =>
                    setState(() => _budgetLevel = level),
                onCompanionChanged: (companion) =>
                    setState(() => _companion = companion),
                onConsentChanged: (hasConsent) =>
                    setState(() => _hasTelemetryConsent = hasConsent),
                onFinish: _finish,
              ),
          },
        ),
      ),
    );
  }
}

class _VibeStep extends StatelessWidget {
  const _VibeStep({
    required this.selectedVibes,
    required this.onVibeToggled,
    required this.onNext,
  });

  final List<OnboardingVibe> selectedVibes;
  final ValueChanged<OnboardingVibe> onVibeToggled;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          '¿Qué vibe buscas en tu viaje?',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        const Text('Elige hasta 3.'),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final OnboardingVibe vibe in OnboardingCatalog.vibes)
              FilterChip(
                label: Text('${vibe.emoji} ${vibe.label}'),
                selected: selectedVibes.contains(vibe),
                onSelected: (_) => onVibeToggled(vibe),
              ),
          ],
        ),
        const Spacer(),
        FilledButton(onPressed: onNext, child: const Text('Siguiente')),
      ],
    );
  }
}

class _SwipeStep extends StatelessWidget {
  const _SwipeStep({
    required this.card,
    required this.cardNumber,
    required this.onRated,
  });

  final OnboardingCard card;
  final int cardNumber;
  final ValueChanged<SwipeVerdict> onRated;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          '¿Te gusta este plan? ($cardNumber/${OnboardingCatalog.swipeDeck.length})',
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        const Text('Desliza a la derecha si te gusta, a la izquierda si no.'),
        const SizedBox(height: 16),
        Expanded(
          child: Dismissible(
            key: ValueKey<String>(card.id),
            onDismissed: (direction) => onRated(
              direction == DismissDirection.startToEnd
                  ? SwipeVerdict.like
                  : SwipeVerdict.dislike,
            ),
            child: Card(
              color: theme.colorScheme.primaryContainer,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(card.emoji, style: const TextStyle(fontSize: 72)),
                      const SizedBox(height: 16),
                      Text(
                        card.title,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            IconButton.filledTonal(
              tooltip: 'No me gusta',
              iconSize: 32,
              onPressed: () => onRated(SwipeVerdict.dislike),
              icon: const Icon(Icons.close),
            ),
            IconButton.filledTonal(
              tooltip: 'Me encanta',
              iconSize: 32,
              onPressed: () => onRated(SwipeVerdict.superlike),
              icon: const Icon(Icons.star),
            ),
            IconButton.filled(
              tooltip: 'Me gusta',
              iconSize: 32,
              onPressed: () => onRated(SwipeVerdict.like),
              icon: const Icon(Icons.favorite),
            ),
          ],
        ),
      ],
    );
  }
}

class _DilemmaStep extends StatelessWidget {
  const _DilemmaStep({required this.dilemma, required this.onOptionChosen});

  final OnboardingDilemma dilemma;
  final ValueChanged<OnboardingCard> onOptionChosen;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          dilemma.question,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        const Text('Toca la opción que prefieras.'),
        const SizedBox(height: 16),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (final OnboardingCard option in <OnboardingCard>[
                dilemma.optionA,
                dilemma.optionB,
              ])
                Expanded(
                  child: Card(
                    child: InkWell(
                      onTap: () => onOptionChosen(option),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              option.emoji,
                              style: const TextStyle(fontSize: 56),
                            ),
                            const SizedBox(height: 12),
                            Text(option.title, textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PreferencesStep extends StatelessWidget {
  const _PreferencesStep({
    required this.budgetLevel,
    required this.companion,
    required this.hasTelemetryConsent,
    required this.isSaving,
    required this.onBudgetChanged,
    required this.onCompanionChanged,
    required this.onConsentChanged,
    required this.onFinish,
  });

  final int budgetLevel;
  final CompanionType companion;
  final bool hasTelemetryConsent;
  final bool isSaving;
  final ValueChanged<int> onBudgetChanged;
  final ValueChanged<CompanionType> onCompanionChanged;
  final ValueChanged<bool> onConsentChanged;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return ListView(
      children: <Widget>[
        Text('Último paso', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 16),
        Text(
          'Presupuesto: ${PriceLevel.toSymbols(budgetLevel)}',
          style: theme.textTheme.titleMedium,
        ),
        Slider(
          value: budgetLevel.toDouble(),
          min: PriceLevel.minimum.toDouble(),
          max: PriceLevel.maximum.toDouble(),
          divisions: PriceLevel.maximum - PriceLevel.minimum,
          label: PriceLevel.toSymbols(budgetLevel),
          onChanged: (value) => onBudgetChanged(value.round()),
        ),
        const SizedBox(height: 16),
        Text('¿Con quién viajas?', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        SegmentedButton<CompanionType>(
          segments: <ButtonSegment<CompanionType>>[
            for (final CompanionType type in CompanionType.values)
              ButtonSegment<CompanionType>(
                value: type,
                label: Text(type.displayName),
              ),
          ],
          selected: <CompanionType>{companion},
          onSelectionChanged: (selection) =>
              onCompanionChanged(selection.first),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Aprender de cómo uso la app'),
          subtitle: const Text(
            'Usa el tiempo que miras cada lugar para mejorar tus '
            'recomendaciones. Puedes desactivarlo cuando quieras.',
          ),
          value: hasTelemetryConsent,
          onChanged: onConsentChanged,
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: isSaving ? null : onFinish,
          child: const Text('Ver mis recomendaciones'),
        ),
      ],
    );
  }
}
