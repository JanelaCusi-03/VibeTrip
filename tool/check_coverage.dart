// Quality gate de cobertura para CI (RNF-12).
//
// Uso:
//   dart run tool/check_coverage.dart <lcov.info> <umbral%> [patrón ...]
//
// Solo se cuentan los archivos cuya ruta contiene alguno de los patrones
// (por ejemplo `/domain/`). Termina con código 1 si la cobertura de líneas
// de esos archivos es menor que el umbral.
import 'dart:io';

void main(List<String> arguments) {
  if (arguments.length < 2) {
    stderr.writeln(
      'Uso: dart run tool/check_coverage.dart <lcov.info> <umbral> [patrón ...]',
    );
    exit(2);
  }

  final File lcovFile = File(arguments[0]);
  final double minimumCoveragePercent = double.parse(arguments[1]);
  final List<String> includedPathPatterns = arguments.skip(2).toList();

  if (!lcovFile.existsSync()) {
    stderr.writeln('No existe el archivo de cobertura: ${lcovFile.path}');
    exit(2);
  }

  final List<FileCoverage> fileCoverages = parseLcov(lcovFile.readAsLinesSync())
      .where(
        (coverage) => matchesAnyPattern(coverage.path, includedPathPatterns),
      )
      .toList();

  if (fileCoverages.isEmpty) {
    stdout.writeln(
      'Sin archivos que coincidan con $includedPathPatterns; gate omitido.',
    );
    return;
  }

  int totalFoundLines = 0;
  int totalHitLines = 0;
  for (final FileCoverage coverage in fileCoverages) {
    totalFoundLines += coverage.foundLines;
    totalHitLines += coverage.hitLines;
    stdout.writeln(
      '${coverage.percent.toStringAsFixed(1).padLeft(6)} %  ${coverage.path}',
    );
  }

  final double totalPercent =
      totalFoundLines == 0 ? 100 : totalHitLines * 100 / totalFoundLines;
  stdout.writeln(
    'Cobertura total: ${totalPercent.toStringAsFixed(2)} % '
    '($totalHitLines/$totalFoundLines líneas). Umbral: $minimumCoveragePercent %',
  );

  if (totalPercent < minimumCoveragePercent) {
    stderr.writeln('Quality gate FALLIDO.');
    exit(1);
  }
  stdout.writeln('Quality gate OK.');
}

class FileCoverage {
  FileCoverage(this.path, this.foundLines, this.hitLines);

  final String path;
  final int foundLines;
  final int hitLines;

  double get percent => foundLines == 0 ? 100 : hitLines * 100 / foundLines;
}

List<FileCoverage> parseLcov(List<String> lcovLines) {
  final List<FileCoverage> coverages = <FileCoverage>[];
  String? currentPath;
  int foundLines = 0;
  int hitLines = 0;

  for (final String line in lcovLines) {
    if (line.startsWith('SF:')) {
      currentPath = line.substring(3).replaceAll(r'\', '/');
      foundLines = 0;
      hitLines = 0;
    } else if (line.startsWith('LF:')) {
      foundLines = int.parse(line.substring(3));
    } else if (line.startsWith('LH:')) {
      hitLines = int.parse(line.substring(3));
    } else if (line == 'end_of_record' && currentPath != null) {
      coverages.add(FileCoverage(currentPath, foundLines, hitLines));
      currentPath = null;
    }
  }
  return coverages;
}

bool matchesAnyPattern(String path, List<String> patterns) =>
    patterns.isEmpty || patterns.any(path.contains);
