import '../entities/place.dart';

/// Contrato de acceso a lugares (patrón Repository).
///
/// El dominio no sabe si los datos vienen de Supabase, del seed local o de
/// la caché: eso lo deciden las implementaciones de la capa Data.
abstract interface class PlaceRepository {
  /// Lugares activos. Con [forceRefresh] se ignora cualquier caché en memoria.
  Future<List<Place>> getActivePlaces({bool forceRefresh = false});

  /// `null` si el lugar no existe o está inactivo.
  Future<Place?> getPlaceById(String placeId);
}

/// No hay red ni una caché vigente (≤ 24 h) desde la cual responder.
class PlacesUnavailableException implements Exception {
  const PlacesUnavailableException(this.cause);

  final Object cause;

  @override
  String toString() => 'PlacesUnavailableException: $cause';
}
