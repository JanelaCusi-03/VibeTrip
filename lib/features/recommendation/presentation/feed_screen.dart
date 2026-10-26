import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/dependency_providers.dart';
import '../../../core/router/app_routes.dart';
import '../../places/data/repositories/cached_place_repository.dart';
import '../../places/domain/repositories/place_repository.dart';
import '../../profile/domain/entities/user_profile.dart';
import '../../profile/presentation/user_profile_controller.dart';
import '../../telemetry/presentation/user_behavior_tracker.dart';
import '../domain/entities/recommendation_result.dart';
import '../domain/services/recommendation_context_builder.dart';
import 'feed_providers.dart';
import 'widgets/place_recommendation_card.dart';

/// Home Feed inteligente (HU-02): filtros rápidos y tarjetas con *match*.
class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    try {
      await ref
          .read(placeRepositoryProvider)
          .getActivePlaces(forceRefresh: true);
    } on PlacesUnavailableException {
      // El estado de error lo muestra el propio feed.
    }
    ref
      ..invalidate(placesProvider)
      ..invalidate(feedContextProvider);
    await ref.read(feedProvider.future);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<RecommendationResult>> feed = ref.watch(feedProvider);
    final UserProfile? profile = ref.watch(userProfileControllerProvider).value;
    final UserProfileController profileController =
        ref.read(userProfileControllerProvider.notifier);
    final bool useDeviceLocation = ref.watch(useDeviceLocationProvider);
    final PlaceRepository placeRepository = ref.watch(placeRepositoryProvider);
    final bool isOffline = placeRepository is CachedPlaceRepository &&
        placeRepository.isServingStaleData;

    return Scaffold(
      appBar: AppBar(
        title: const Text('VibeTrip'),
        actions: <Widget>[
          IconButton(
            tooltip: useDeviceLocation
                ? 'Usar zona manual ($manualZoneLabel)'
                : 'Usar mi ubicación GPS',
            icon: Icon(
              useDeviceLocation ? Icons.my_location : Icons.location_city,
            ),
            onPressed: ref.read(useDeviceLocationProvider.notifier).toggle,
          ),
          IconButton(
            tooltip: 'Ver mapa',
            icon: const Icon(Icons.map_outlined),
            onPressed: () => context.push(AppRoutes.map),
          ),
          IconButton(
            tooltip: 'Mi perfil y privacidad',
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push(AppRoutes.profile),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _refresh(ref),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: <Widget>[
            SliverToBoxAdapter(
              child: _FeedHeader(isOffline: isOffline),
            ),
            ...feed.when(
              data: (results) {
                final List<RecommendationResult> visibleResults = results
                    .where(
                      (result) =>
                          !(profile?.isDiscarded(result.place.id) ?? false),
                    )
                    .toList();
                if (visibleResults.isEmpty) {
                  return <Widget>[
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyFeed(
                        canSwitchToManualZone: useDeviceLocation,
                        onSwitchToManualZone:
                            ref.read(useDeviceLocationProvider.notifier).toggle,
                      ),
                    ),
                  ];
                }
                return <Widget>[
                  SliverList.builder(
                    itemCount: visibleResults.length,
                    itemBuilder: (context, index) {
                      final RecommendationResult result = visibleResults[index];
                      return UserBehaviorTracker(
                        key: ValueKey<String>(result.place.id),
                        trackingId: result.place.id,
                        onViewEnded: (visibleDuration) => unawaited(
                          profileController.recordViewDuration(
                            place: result.place,
                            visibleDuration: visibleDuration,
                            matchScore: result.matchScore,
                          ),
                        ),
                        child: PlaceRecommendationCard(
                          result: result,
                          isFavorite:
                              profile?.isFavorite(result.place.id) ?? false,
                          onTap: () => context.push(
                            AppRoutes.placeDetail(result.place.id),
                          ),
                          onFavoriteToggled: () => unawaited(
                            profileController.toggleFavorite(result.place),
                          ),
                        ),
                      );
                    },
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ];
              },
              loading: () => <Widget>[
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
              error: (error, stackTrace) => <Widget>[
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _FeedError(onRetry: () => _refresh(ref)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedHeader extends ConsumerWidget {
  const _FeedHeader({required this.isOffline});

  final bool isOffline;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final QuickFilter? selectedFilter = ref.watch(quickFilterProvider);
    final FeedContext? feedContext = ref.watch(feedContextProvider).value;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (isOffline)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('Sin conexión: mostrando lugares guardados.'),
            ),
          Text('¿Qué plan buscas hoy?', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: <Widget>[
              for (final QuickFilter filter in QuickFilter.values)
                ChoiceChip(
                  label: Text(filter.label),
                  selected: filter == selectedFilter,
                  onSelected: (_) =>
                      ref.read(quickFilterProvider.notifier).select(filter),
                ),
            ],
          ),
          if (feedContext != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              <String>[
                feedContext.context.timeBucket.displayName,
                feedContext.context.weather.displayName,
                if (feedContext.locationSource == LocationSourceKind.deviceGps)
                  'Tu ubicación'
                else
                  '$manualZoneLabel (zona manual)',
              ].join(' · '),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyFeed extends StatelessWidget {
  const _EmptyFeed({
    required this.canSwitchToManualZone,
    required this.onSwitchToManualZone,
  });

  final bool canSwitchToManualZone;
  final VoidCallback onSwitchToManualZone;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Icon(Icons.travel_explore, size: 64),
          const SizedBox(height: 12),
          const Text(
            'No encontramos lugares para este plan cerca de ti.',
            textAlign: TextAlign.center,
          ),
          if (canSwitchToManualZone) ...<Widget>[
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: onSwitchToManualZone,
              child: const Text('Explorar el $manualZoneLabel'),
            ),
          ],
        ],
      ),
    );
  }
}

class _FeedError extends StatelessWidget {
  const _FeedError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Icon(Icons.cloud_off, size: 64),
          const SizedBox(height: 12),
          const Text(
            'Sin conexión y sin lugares guardados de las últimas 24 h.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}
