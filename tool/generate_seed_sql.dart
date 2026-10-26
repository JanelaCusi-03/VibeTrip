// Genera supabase/seed_places.sql a partir de assets/seed/places.json.
//
// Uso: dart run tool/generate_seed_sql.dart
//
// Así la base de Supabase y el modo local usan exactamente los mismos
// lugares. `place_tags` es la fuente de verdad: el trigger
// trg_place_tags_after_change recalcula `embedding` y `tag_weights`.
import 'dart:convert';
import 'dart:io';

const String seedJsonPath = 'assets/seed/places.json';
const String outputSqlPath = 'supabase/seed_places.sql';

void main() {
  final Map<String, Object?> seedDocument =
      jsonDecode(File(seedJsonPath).readAsStringSync()) as Map<String, Object?>;
  final List<Map<String, Object?>> places =
      (seedDocument['places']! as List<Object?>).cast<Map<String, Object?>>();

  final StringBuffer sql = StringBuffer()
    ..writeln('-- ARCHIVO GENERADO por tool/generate_seed_sql.dart; no editar.')
    ..writeln('-- Fuente: $seedJsonPath (${places.length} lugares).')
    ..writeln('-- Ejecutar después de seed.sql (requiere tags y categories).')
    ..writeln();

  for (final Map<String, Object?> place in places) {
    sql
      ..writeln('-- ${place['name']}')
      ..writeln(
        'INSERT INTO places (id, category_id, name, description, address, '
        'latitude, longitude, price_level, estimated_cost, is_outdoor, '
        'best_time_buckets, companion_fit, image_urls, is_active)',
      )
      ..writeln(
        'SELECT ${quote(place['id'])}, c.id, ${quote(place['name'])}, '
        '${quote(place['description'])}, ${quote(place['address'])}, '
        '${place['latitude']}, ${place['longitude']}, ${place['price_level']}, '
        '${place['estimated_cost'] ?? 'NULL'}, ${place['is_outdoor']}, '
        '${sqlArray(place['best_time_buckets'], 'time_bucket')}, '
        '${sqlArray(place['companion_fit'], 'companion_type')}, '
        '${sqlArray(place['image_urls'], 'text')}, ${place['is_active']}',
      )
      ..writeln(
        'FROM categories c WHERE c.slug = ${quote(place['category_slug'])};',
      );

    final Map<String, Object?> tagWeights =
        place['tag_weights']! as Map<String, Object?>;
    final String tagValues = tagWeights.entries
        .map((entry) => '(${quote(entry.key)}, ${entry.value})')
        .join(', ');
    sql
      ..writeln('INSERT INTO place_tags (place_id, tag_id, weight)')
      ..writeln('SELECT ${quote(place['id'])}, t.id, v.weight')
      ..writeln('FROM (VALUES $tagValues) AS v(slug, weight)')
      ..writeln('JOIN tags t ON t.slug = v.slug;')
      ..writeln();
  }

  File(outputSqlPath).writeAsStringSync(sql.toString());
  stdout.writeln('Generado $outputSqlPath con ${places.length} lugares.');
}

String quote(Object? value) =>
    value == null ? 'NULL' : "'${value.toString().replaceAll("'", "''")}'";

String sqlArray(Object? values, String elementType) {
  final List<Object?> items = (values as List<Object?>?) ?? const <Object?>[];
  if (items.isEmpty) return "'{}'::$elementType[]";
  return 'ARRAY[${items.map(quote).join(', ')}]::$elementType[]';
}
