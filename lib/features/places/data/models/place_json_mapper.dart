import '../../../../core/data/json_reading.dart';
import '../../../../core/domain/context_types.dart';
import '../../../../core/domain/geo_distance.dart';
import '../../../../core/domain/tag_vector.dart';
import '../../domain/entities/place.dart';
import '../../domain/entities/place_category.dart';

/// Traduce entre filas de `places` (JSON) y la entidad [Place].
///
/// Acepta la categoría como `category_slug` (seed y caché) o como objeto
/// anidado `categories: {slug}` (respuesta de PostgREST con *join*).
abstract final class PlaceJsonMapper {
  static Place fromJson(JsonMap json) {
    final String categorySlug = json['category_slug'] is String
        ? json.read<String>('category_slug')
        : json.readMap('categories').read<String>('slug');

    return Place(
      id: json.read<String>('id'),
      name: json.read<String>('name'),
      description: json.readOptional<String>('description') ?? '',
      address: json.readOptional<String>('address'),
      category: PlaceCategoryCatalog.bySlug(categorySlug),
      location: GeoPoint(
        latitude: json.readDouble('latitude'),
        longitude: json.readDouble('longitude'),
      ),
      priceLevel: json.read<int>('price_level'),
      estimatedCostInSoles: json.readOptionalDouble('estimated_cost'),
      isOutdoor: json.readOptional<bool>('is_outdoor') ?? false,
      bestTimeBuckets: json
          .readStringList('best_time_buckets')
          .map(TimeBucket.fromWireName)
          .toSet(),
      companionFit: json
          .readStringList('companion_fit')
          .map(CompanionType.fromWireName)
          .toSet(),
      ratingAverage: json.readOptionalDouble('rating_average'),
      ratingCount: json.readOptional<int>('rating_count') ?? 0,
      imageUrls: json.readStringList('image_urls'),
      tagVector: TagVector.fromTagWeights(json.readWeightMap('tag_weights')),
      isActive: json.readOptional<bool>('is_active') ?? true,
    );
  }

  static JsonMap toJson(Place place) => <String, Object?>{
        'id': place.id,
        'category_slug': place.category.slug,
        'name': place.name,
        'description': place.description,
        'address': place.address,
        'latitude': place.location.latitude,
        'longitude': place.location.longitude,
        'price_level': place.priceLevel,
        'estimated_cost': place.estimatedCostInSoles,
        'is_outdoor': place.isOutdoor,
        'best_time_buckets': <String>[
          for (final TimeBucket bucket in place.bestTimeBuckets)
            bucket.wireName,
        ],
        'companion_fit': <String>[
          for (final CompanionType companion in place.companionFit)
            companion.wireName,
        ],
        'rating_average': place.ratingAverage,
        'rating_count': place.ratingCount,
        'image_urls': place.imageUrls,
        'tag_weights': place.tagVector.toTagWeights(),
        'is_active': place.isActive,
      };
}
