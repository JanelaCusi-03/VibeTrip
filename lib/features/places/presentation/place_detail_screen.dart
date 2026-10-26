import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/domain/context_types.dart';
import '../../../core/domain/tag_weight.dart';
import '../../../core/presentation/category_style.dart';
import '../../profile/domain/entities/user_profile.dart';
import '../../profile/presentation/user_profile_controller.dart';
import '../../recommendation/domain/entities/recommendation_result.dart';
import '../../recommendation/presentation/feed_providers.dart';
import '../../telemetry/domain/entities/interaction_type.dart';
import '../../telemetry/presentation/user_behavior_tracker.dart';
import '../domain/entities/place.dart';

/// Detalle de un lugar (RF-10) con favoritos, «Cómo llegar» y descarte.
class PlaceDetailScreen extends ConsumerStatefulWidget {
  const PlaceDetailScreen({required this.placeId, super.key});

  final String placeId;

  @override
  ConsumerState<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends ConsumerState<PlaceDetailScreen> {
  bool _hasRecordedDetailView = false;

  /// Se obtiene en [initState] porque el tracker reporta el tiempo de vista
  /// durante `dispose`, cuando ya no es seguro usar `ref`.
  late final UserProfileController _profileController;

  @override
  void initState() {
    super.initState();
    _profileController = ref.read(userProfileControllerProvider.notifier);
  }

  void _recordDetailViewOnce(Place place, RecommendationResult? result) {
    if (_hasRecordedDetailView) return;
    _hasRecordedDetailView = true;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => unawaited(
        _profileController.recordInteraction(
          place: place,
          type: InteractionType.viewDetail,
          matchScore: result?.matchScore,
        ),
      ),
    );
  }

  Future<void> _openDirections(Place place) async {
    unawaited(
      _profileController.recordInteraction(
        place: place,
        type: InteractionType.directionsClick,
      ),
    );
    final Uri directionsUri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '${place.location.latitude},${place.location.longitude}',
    });
    final bool isLaunched = await launchUrl(
      directionsUri,
      mode: LaunchMode.externalApplication,
    );
    if (!isLaunched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir la app de mapas.')),
      );
    }
  }

  Future<void> _discard(Place place) async {
    await _profileController.recordInteraction(
      place: place,
      type: InteractionType.discard,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('No volverás a ver «${place.name}».')),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Place>> places = ref.watch(placesProvider);
    final List<RecommendationResult> feedResults =
        ref.watch(feedProvider).value ?? const <RecommendationResult>[];
    final UserProfile? profile = ref.watch(userProfileControllerProvider).value;

    return places.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('No se pudo cargar el lugar.')),
      ),
      data: (loadedPlaces) {
        final Place? place = loadedPlaces
            .where((candidate) => candidate.id == widget.placeId)
            .firstOrNull;
        if (place == null) {
          return Scaffold(
            appBar: AppBar(),
            body:
                const Center(child: Text('Este lugar ya no está disponible.')),
          );
        }
        final RecommendationResult? result = feedResults
            .where((candidate) => candidate.place.id == place.id)
            .firstOrNull;
        if (profile != null) _recordDetailViewOnce(place, result);

        return UserBehaviorTracker(
          trackingId: 'detail-${place.id}',
          onViewEnded: (visibleDuration) => unawaited(
            _profileController.recordViewDuration(
              place: place,
              visibleDuration: visibleDuration,
              matchScore: result?.matchScore,
            ),
          ),
          child: _PlaceDetailView(
            place: place,
            result: result,
            isFavorite: profile?.isFavorite(place.id) ?? false,
            onFavoriteToggled: () =>
                unawaited(_profileController.toggleFavorite(place)),
            onDirections: () => _openDirections(place),
            onDiscard: () => _discard(place),
          ),
        );
      },
    );
  }
}

class _PlaceDetailView extends StatelessWidget {
  const _PlaceDetailView({
    required this.place,
    required this.result,
    required this.isFavorite,
    required this.onFavoriteToggled,
    required this.onDirections,
    required this.onDiscard,
  });

  final Place place;
  final RecommendationResult? result;
  final bool isFavorite;
  final VoidCallback onFavoriteToggled;
  final VoidCallback onDirections;
  final VoidCallback onDiscard;

  static const Map<String, String> _factorLabels = <String, String>{
    'affinity': 'Afinidad con tus gustos',
    'proximity': 'Cercanía',
    'context': 'Momento, presupuesto y compañía',
  };

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final RecommendationResult? recommendation = result;

    return Scaffold(
      appBar: AppBar(
        title: Text(place.name),
        backgroundColor: CategoryStyle.colorOf(place.category),
        foregroundColor: Colors.white,
        actions: <Widget>[
          IconButton(
            tooltip:
                isFavorite ? 'Quitar de favoritos' : 'Guardar en favoritos',
            icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
            onPressed: onFavoriteToggled,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                CategoryStyle.iconOf(place.category),
                color: CategoryStyle.colorOf(place.category),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${place.category.name} · '
                  '${PriceLevel.toSymbols(place.priceLevel)}'
                  '${place.isOutdoor ? ' · Al aire libre' : ''}',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          if (recommendation != null) ...<Widget>[
            const SizedBox(height: 16),
            Text(
              '${recommendation.matchScore} % match',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(recommendation.explanation),
            const SizedBox(height: 12),
            Text('¿Por qué este puntaje?', style: theme.textTheme.titleSmall),
            for (final MapEntry<String, double> factor
                in recommendation.factorScores.entries)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '${_factorLabels[factor.key] ?? factor.key}: '
                      '${(factor.value * 100).round()} %',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(value: factor.value),
                  ],
                ),
              ),
          ],
          const SizedBox(height: 16),
          Text(place.description, style: theme.textTheme.bodyLarge),
          if (place.address != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(place.address!, style: theme.textTheme.bodySmall),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              for (final TagWeight tagWeight in place.topTagWeights(count: 6))
                Chip(label: Text(tagWeight.tag.displayName)),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onDirections,
            icon: const Icon(Icons.directions),
            label: const Text('Cómo llegar'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onDiscard,
            icon: const Icon(Icons.thumb_down_alt_outlined),
            label: const Text('No me interesa'),
          ),
        ],
      ),
    );
  }
}
