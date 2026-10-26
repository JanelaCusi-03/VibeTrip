import '../../../../core/data/json_reading.dart';
import '../../domain/entities/place.dart';
import '../../domain/repositories/place_repository.dart';
import '../datasources/place_remote_data_source.dart';
import '../models/place_json_mapper.dart';

/// Repositorio que siempre consulta el origen remoto (sin caché).
class RemotePlaceRepository implements PlaceRepository {
  const RemotePlaceRepository(this._remoteDataSource);

  final PlaceRemoteDataSource _remoteDataSource;

  @override
  Future<List<Place>> getActivePlaces({bool forceRefresh = false}) async {
    final List<JsonMap> placeRows =
        await _remoteDataSource.fetchActivePlaceRows();
    return placeRows
        .map(PlaceJsonMapper.fromJson)
        .where((place) => place.isActive)
        .toList();
  }

  @override
  Future<Place?> getPlaceById(String placeId) async {
    for (final Place place in await getActivePlaces()) {
      if (place.id == placeId) return place;
    }
    return null;
  }
}
