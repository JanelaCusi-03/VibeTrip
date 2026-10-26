import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibetrip/core/data/json_reading.dart';
import 'package:vibetrip/core/domain/context_types.dart';
import 'package:vibetrip/core/domain/tag_catalog.dart';
import 'package:vibetrip/features/places/data/datasources/place_local_cache_data_source.dart';
import 'package:vibetrip/features/places/data/datasources/place_remote_data_source.dart';
import 'package:vibetrip/features/places/data/models/place_json_mapper.dart';
import 'package:vibetrip/features/places/data/repositories/cached_place_repository.dart';
import 'package:vibetrip/features/places/data/repositories/remote_place_repository.dart';
import 'package:vibetrip/features/places/domain/entities/place.dart';
import 'package:vibetrip/features/places/domain/repositories/place_repository.dart';

import '../../helpers/fixtures.dart';

class MockPlaceRepository extends Mock implements PlaceRepository {}

Future<String> loadSeedFromDisk() =>
    File(SeedPlaceDataSource.assetPath).readAsString();

void main() {
  group('Seed de lugares (assets/seed/places.json)', () {
    late List<Place> seedPlaces;

    setUpAll(() async {
      seedPlaces = await const RemotePlaceRepository(
        SeedPlaceDataSource(loadSeedFromDisk),
      ).getActivePlaces();
    });

    test('tiene al menos 10 lugares con ids únicos', () {
      expect(seedPlaces.length, greaterThanOrEqualTo(10));
      expect(
        seedPlaces.map((place) => place.id).toSet(),
        hasLength(
          seedPlaces.length,
        ),
      );
    });

    test('cubre las cuatro categorías raíz del producto', () {
      final Set<String> parentSlugs = seedPlaces
          .map((place) => place.category.parentSlug ?? place.category.slug)
          .toSet();
      expect(parentSlugs, <String>{
        'turismo_cultura',
        'gastronomia',
        'actividades',
        'entretenimiento',
      });
    });

    test('cada lugar tiene etiquetas válidas con pesos en [0, 1]', () {
      for (final Place place in seedPlaces) {
        expect(place.tagVector.isZero, isFalse, reason: place.name);
        for (final double component in place.tagVector.components) {
          expect(component, inInclusiveRange(0, 1), reason: place.name);
        }
        expect(place.bestTimeBuckets, isNotEmpty, reason: place.name);
        expect(place.companionFit, isNotEmpty, reason: place.name);
      }
    });

    test('los lugares están en el centro de Cusco (radio ≤ 5 km)', () {
      for (final Place place in seedPlaces) {
        expect(place.location.latitude, closeTo(-13.52, 0.05));
        expect(place.location.longitude, closeTo(-71.98, 0.05));
      }
    });

    test('getPlaceById encuentra lugares existentes', () async {
      const RemotePlaceRepository repository = RemotePlaceRepository(
        SeedPlaceDataSource(loadSeedFromDisk),
      );
      final Place? qorikancha = await repository.getPlaceById(
        'a1000000-0000-4000-8000-000000000001',
      );
      expect(qorikancha?.name, 'Qorikancha');
      expect(await repository.getPlaceById('no-existe'), isNull);
    });
  });

  group('PlaceJsonMapper', () {
    test('ida y vuelta conserva todos los campos', () {
      final Place original = buildPlace(
        tagWeights: <String, double>{'bar': 0.9, 'terraza': 1},
        isOutdoor: true,
        bestTimeBuckets: <TimeBucket>{TimeBucket.night},
        companionFit: <CompanionType>{CompanionType.friends},
        priceLevel: 3,
      );
      final Place restored = PlaceJsonMapper.fromJson(
        PlaceJsonMapper.toJson(original),
      );
      expect(restored, original);
      expect(restored.tagVector, original.tagVector);
      expect(restored.bestTimeBuckets, <TimeBucket>{TimeBucket.night});
      expect(restored.companionFit, <CompanionType>{CompanionType.friends});
      expect(restored.isOutdoor, isTrue);
      expect(restored.priceLevel, 3);
    });

    test('acepta la categoría anidada de PostgREST y enteros como double', () {
      final Place place = PlaceJsonMapper.fromJson(<String, Object?>{
        'id': 'p9',
        'name': 'Bar',
        'categories': <String, Object?>{'slug': 'bar'},
        'latitude': -13,
        'longitude': -72,
        'price_level': 2,
        'tag_weights': <String, Object?>{'bar': 1},
      });
      expect(place.category.slug, 'bar');
      expect(place.location.latitude, -13.0);
      expect(place.tagVector[TagCatalog.bySlug('bar').vectorIndex], 1.0);
    });

    test('lanza FormatException con campos inválidos', () {
      expect(
        () => PlaceJsonMapper.fromJson(<String, Object?>{'id': 1}),
        throwsFormatException,
      );
      expect(
        () => <String, Object?>{'x': 'texto'}.readOptional<int>('x'),
        throwsFormatException,
      );
    });
  });

  group('CachedPlaceRepository (Decorator Offline-First)', () {
    late MockPlaceRepository decoratedRepository;
    late PlaceLocalCacheDataSource localCache;
    late DateTime now;

    CachedPlaceRepository buildRepository() => CachedPlaceRepository(
          decoratedRepository: decoratedRepository,
          localCache: localCache,
          clock: () => now,
        );

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      decoratedRepository = MockPlaceRepository();
      localCache = PlaceLocalCacheDataSource(
        await SharedPreferences.getInstance(),
      );
      now = DateTime.utc(2026, 10, 24, 12);
    });

    test('con red devuelve datos frescos y los guarda en disco', () async {
      when(() => decoratedRepository.getActivePlaces(forceRefresh: true))
          .thenAnswer((_) async => <Place>[buildPlace()]);
      final CachedPlaceRepository repository = buildRepository();

      final List<Place> places = await repository.getActivePlaces();

      expect(places, hasLength(1));
      expect(repository.isServingStaleData, isFalse);
      expect(localCache.readPlaceRows()?.placeRows, hasLength(1));
    });

    test('reutiliza la lista en memoria salvo forceRefresh', () async {
      when(() => decoratedRepository.getActivePlaces(forceRefresh: true))
          .thenAnswer((_) async => <Place>[buildPlace()]);
      final CachedPlaceRepository repository = buildRepository();

      await repository.getActivePlaces();
      await repository.getActivePlaces();
      verify(() => decoratedRepository.getActivePlaces(forceRefresh: true))
          .called(1);

      await repository.getActivePlaces(forceRefresh: true);
      verify(() => decoratedRepository.getActivePlaces(forceRefresh: true))
          .called(1);
      expect(await repository.getPlaceById('place-1'), isNotNull);
      expect(await repository.getPlaceById('otro'), isNull);
    });

    test('sin red usa la caché de hasta 24 h (RNF-05)', () async {
      await localCache.savePlaceRows(
        <JsonMap>[PlaceJsonMapper.toJson(buildPlace())],
        now.subtract(const Duration(hours: 23)),
      );
      when(() => decoratedRepository.getActivePlaces(forceRefresh: true))
          .thenThrow(const SocketException('sin red'));
      final CachedPlaceRepository repository = buildRepository();

      final List<Place> places = await repository.getActivePlaces();

      expect(places.single.id, 'place-1');
      expect(repository.isServingStaleData, isTrue);
    });

    test('sin red y caché vencida lanza PlacesUnavailableException', () async {
      await localCache.savePlaceRows(
        <JsonMap>[PlaceJsonMapper.toJson(buildPlace())],
        now.subtract(const Duration(hours: 25)),
      );
      when(() => decoratedRepository.getActivePlaces(forceRefresh: true))
          .thenThrow(const SocketException('sin red'));

      expect(
        buildRepository().getActivePlaces(),
        throwsA(isA<PlacesUnavailableException>()),
      );
    });

    test('sin red y sin caché lanza PlacesUnavailableException', () async {
      when(() => decoratedRepository.getActivePlaces(forceRefresh: true))
          .thenThrow(const SocketException('sin red'));

      await expectLater(
        buildRepository().getActivePlaces(),
        throwsA(
          isA<PlacesUnavailableException>().having(
            (exception) => exception.toString(),
            'mensaje',
            contains('sin red'),
          ),
        ),
      );
    });

    test('una caché corrupta se trata como inexistente', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        PlaceLocalCacheDataSource.storageKey: '{no es json',
      });
      final PlaceLocalCacheDataSource corruptCache = PlaceLocalCacheDataSource(
        await SharedPreferences.getInstance(),
      );
      expect(corruptCache.readPlaceRows(), isNull);
      await corruptCache.clear();
      expect(corruptCache.readPlaceRows(), isNull);
    });
  });
}
