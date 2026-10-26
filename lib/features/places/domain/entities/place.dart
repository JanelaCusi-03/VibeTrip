import '../../../../core/domain/context_types.dart';
import '../../../../core/domain/geo_distance.dart';
import '../../../../core/domain/tag_vector.dart';
import '../../../../core/domain/tag_weight.dart';
import 'place_category.dart';

/// Lugar recomendable (tabla `places`). Inmutable; la identidad es [id].
class Place {
  Place({
    required this.id,
    required this.name,
    required this.category,
    required this.location,
    required this.priceLevel,
    required this.tagVector,
    this.description = '',
    this.address,
    this.estimatedCostInSoles,
    this.isOutdoor = false,
    Set<TimeBucket> bestTimeBuckets = const <TimeBucket>{},
    Set<CompanionType> companionFit = const <CompanionType>{},
    this.ratingAverage,
    this.ratingCount = 0,
    List<String> imageUrls = const <String>[],
    this.isActive = true,
  })  : bestTimeBuckets = Set<TimeBucket>.unmodifiable(bestTimeBuckets),
        companionFit = Set<CompanionType>.unmodifiable(companionFit),
        imageUrls = List<String>.unmodifiable(imageUrls) {
    if (!PriceLevel.isValid(priceLevel)) {
      throw ArgumentError.value(priceLevel, 'priceLevel', 'Debe estar en 1-4');
    }
  }

  final String id;
  final String name;
  final String description;
  final String? address;
  final PlaceCategory category;
  final GeoPoint location;
  final int priceLevel;
  final double? estimatedCostInSoles;
  final bool isOutdoor;
  final Set<TimeBucket> bestTimeBuckets;
  final Set<CompanionType> companionFit;
  final double? ratingAverage;
  final int ratingCount;
  final List<String> imageUrls;

  /// Vector `p` del lugar, componentes en [0, 1].
  final TagVector tagVector;
  final bool isActive;

  /// Las [count] etiquetas más fuertes del lugar, para chips en la UI.
  List<TagWeight> topTagWeights({int count = 3}) =>
      TagWeight.rankedFromVector(tagVector).take(count).toList();

  @override
  bool operator ==(Object other) => other is Place && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Place($id, $name)';
}
