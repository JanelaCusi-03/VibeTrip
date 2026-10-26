import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/domain/geo_distance.dart';
import '../../../core/presentation/category_style.dart';
import '../../../core/router/app_routes.dart';
import '../../profile/domain/entities/user_profile.dart';
import '../../profile/presentation/user_profile_controller.dart';
import '../../recommendation/domain/entities/recommendation_result.dart';
import '../../recommendation/presentation/feed_providers.dart';
import '../domain/entities/place.dart';
import '../domain/entities/place_category.dart';

/// Mapa interactivo con pines personalizados por categoría (RF-13).
class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  static const String tileUrlTemplate =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String userAgentPackageName = 'pe.edu.unsaac.vibetrip';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Place> places = ref.watch(placesProvider).value ?? <Place>[];
    final UserProfile? profile = ref.watch(userProfileControllerProvider).value;
    final GeoPoint userLocation =
        ref.watch(feedContextProvider).value?.context.userLocation ??
            manualZoneLocation;
    final Map<String, RecommendationResult> resultsByPlaceId =
        <String, RecommendationResult>{
      for (final RecommendationResult result
          in ref.watch(feedProvider).value ?? <RecommendationResult>[])
        result.place.id: result,
    };
    final List<Place> visiblePlaces = places
        .where((place) => !(profile?.isDiscarded(place.id) ?? false))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Mapa')),
      body: Stack(
        children: <Widget>[
          FlutterMap(
            options: MapOptions(
              initialCenter: _toLatLng(userLocation),
              initialZoom: 14.5,
            ),
            children: <Widget>[
              TileLayer(
                urlTemplate: tileUrlTemplate,
                userAgentPackageName: userAgentPackageName,
              ),
              MarkerLayer(
                markers: <Marker>[
                  for (final Place place in visiblePlaces)
                    Marker(
                      point: _toLatLng(place.location),
                      width: 48,
                      height: 48,
                      child: _CategoryPin(
                        place: place,
                        onTap: () => _showPlaceSheet(
                          context,
                          place,
                          resultsByPlaceId[place.id],
                        ),
                      ),
                    ),
                  // Al final para que el punto quede encima de los pines.
                  Marker(
                    point: _toLatLng(userLocation),
                    width: 28,
                    height: 28,
                    child: const _UserLocationDot(),
                  ),
                ],
              ),
              const RichAttributionWidget(
                attributions: <SourceAttribution>[
                  TextSourceAttribution('OpenStreetMap contributors'),
                ],
              ),
            ],
          ),
          const Positioned(left: 8, right: 8, top: 8, child: _CategoryLegend()),
        ],
      ),
    );
  }

  static LatLng _toLatLng(GeoPoint point) =>
      LatLng(point.latitude, point.longitude);

  void _showPlaceSheet(
    BuildContext context,
    Place place,
    RecommendationResult? result,
  ) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              place.name,
              style: Theme.of(sheetContext).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(place.category.name),
            if (result != null) ...<Widget>[
              const SizedBox(height: 8),
              Text('${result.matchScore} % match · ${result.explanation}'),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                Navigator.of(sheetContext).pop();
                context.push(AppRoutes.placeDetail(place.id));
              },
              child: const Text('Ver detalle'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryPin extends StatelessWidget {
  const _CategoryPin({required this.place, required this.onTap});

  final Place place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${place.name}, ${place.category.name}',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: CategoryStyle.colorOf(place.category),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const <BoxShadow>[
              BoxShadow(blurRadius: 4, color: Colors.black26),
            ],
          ),
          child: Icon(
            CategoryStyle.iconOf(place.category),
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _UserLocationDot extends StatelessWidget {
  const _UserLocationDot();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Tu ubicación',
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
        ),
      ),
    );
  }
}

class _CategoryLegend extends StatelessWidget {
  const _CategoryLegend();

  @override
  Widget build(BuildContext context) {
    final List<PlaceCategory> rootCategories =
        PlaceCategoryCatalog.all.where((category) => category.isRoot).toList();
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: <Widget>[
        for (final PlaceCategory category in rootCategories)
          Chip(
            avatar: Icon(
              CategoryStyle.iconOf(category),
              color: CategoryStyle.colorOf(category),
              size: 18,
            ),
            label: Text(category.name),
            visualDensity: VisualDensity.compact,
          ),
      ],
    );
  }
}
