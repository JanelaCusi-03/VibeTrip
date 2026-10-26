import '../../domain/entities/place.dart';
import '../../domain/repositories/place_repository.dart';
import '../datasources/place_local_cache_data_source.dart';
import '../models/place_json_mapper.dart';

/// Decorator (GoF) que agrega Offline-First a cualquier [PlaceRepository].
///
/// Política *network-first con respaldo*:
/// 1. Si hay lista en memoria y no se pide [forceRefresh], se devuelve.
/// 2. Se consulta el repositorio decorado y se guarda una copia en disco.
/// 3. Si falla, se usa la copia en disco mientras tenga ≤ [maximumCacheAge]
///    (24 h, RNF-05); si no hay copia vigente se lanza
///    [PlacesUnavailableException].
class CachedPlaceRepository implements PlaceRepository {
  CachedPlaceRepository({
    required PlaceRepository decoratedRepository,
    required PlaceLocalCacheDataSource localCache,
    required DateTime Function() clock,
    this.maximumCacheAge = const Duration(hours: 24),
  })  : _decoratedRepository = decoratedRepository,
        _localCache = localCache,
        _clock = clock;

  final PlaceRepository _decoratedRepository;
  final PlaceLocalCacheDataSource _localCache;
  final DateTime Function() _clock;
  final Duration maximumCacheAge;

  List<Place>? _placesInMemory;

  /// `true` si la última respuesta salió de la caché en disco (sin red).
  bool isServingStaleData = false;

  @override
  Future<List<Place>> getActivePlaces({bool forceRefresh = false}) async {
    final List<Place>? placesInMemory = _placesInMemory;
    if (placesInMemory != null && !forceRefresh) return placesInMemory;

    try {
      final List<Place> freshPlaces =
          await _decoratedRepository.getActivePlaces(forceRefresh: true);
      await _localCache.savePlaceRows(
        freshPlaces.map(PlaceJsonMapper.toJson).toList(),
        _clock(),
      );
      isServingStaleData = false;
      return _placesInMemory = freshPlaces;
    } on Exception catch (error) {
      final CachedPlaceRows? cachedRows = _localCache.readPlaceRows();
      final bool isCacheFresh = cachedRows != null &&
          _clock().difference(cachedRows.savedAt) <= maximumCacheAge;
      if (!isCacheFresh) throw PlacesUnavailableException(error);

      isServingStaleData = true;
      return _placesInMemory =
          cachedRows.placeRows.map(PlaceJsonMapper.fromJson).toList();
    }
  }

  @override
  Future<Place?> getPlaceById(String placeId) async {
    for (final Place place in await getActivePlaces()) {
      if (place.id == placeId) return place;
    }
    return null;
  }
}
