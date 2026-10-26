import 'package:vibetrip/core/domain/context_types.dart';
import 'package:vibetrip/core/domain/geo_distance.dart';
import 'package:vibetrip/core/domain/tag_vector.dart';
import 'package:vibetrip/features/places/domain/entities/place.dart';
import 'package:vibetrip/features/places/domain/entities/place_category.dart';
import 'package:vibetrip/features/profile/domain/entities/user_profile.dart';

/// Plaza de Armas del Cusco: punto de referencia de las pruebas.
const GeoPoint plazaDeArmas = GeoPoint(latitude: -13.5167, longitude: -71.9788);

Place buildPlace({
  String id = 'place-1',
  String name = 'Lugar de prueba',
  String categorySlug = 'mirador',
  GeoPoint location = plazaDeArmas,
  int priceLevel = 1,
  Map<String, double> tagWeights = const <String, double>{'tranquilo': 1},
  bool isOutdoor = false,
  Set<TimeBucket> bestTimeBuckets = const <TimeBucket>{},
  Set<CompanionType> companionFit = const <CompanionType>{},
  bool isActive = true,
}) =>
    Place(
      id: id,
      name: name,
      category: PlaceCategoryCatalog.bySlug(categorySlug),
      location: location,
      priceLevel: priceLevel,
      tagVector: TagVector.fromTagWeights(tagWeights),
      isOutdoor: isOutdoor,
      bestTimeBuckets: bestTimeBuckets,
      companionFit: companionFit,
      isActive: isActive,
    );

UserProfile buildProfile({
  Map<String, double> preferences = const <String, double>{},
  bool hasTelemetryConsent = true,
}) {
  final TagVector vector = TagVector.fromTagWeights(preferences);
  return UserProfile(
    id: 'user-1',
    displayName: 'Ana',
    explicitVector: vector,
    currentVector: vector,
    hasTelemetryConsent: hasTelemetryConsent,
  );
}
