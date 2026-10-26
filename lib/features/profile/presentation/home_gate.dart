import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../recommendation/presentation/feed_screen.dart';
import 'onboarding_screen.dart';
import 'user_profile_controller.dart';

/// Muestra el onboarding hasta que el usuario lo complete; luego el feed.
class HomeGate extends ConsumerWidget {
  const HomeGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(userProfileControllerProvider).when(
          data: (profile) => profile.hasCompletedOnboarding
              ? const FeedScreen()
              : const OnboardingScreen(),
          loading: () => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stackTrace) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => ref.invalidate(userProfileControllerProvider),
                child: const Text('Reintentar'),
              ),
            ),
          ),
        );
  }
}
