import 'dart:math';

import 'package:collection/collection.dart';
import 'package:common/generic/models/valuable_letter.dart';
import 'package:logging/logging.dart';

final _random = Random();
final _logging = Logger('FixTracksGrid');

class FixTracksGrid {
  final int rowCount;
  final int columnCount;

  int get cellCount => rowCount * columnCount;

  final List<Tile?> _tiles;

  final List<PathSegment> _pathSegments;
  List<PathSegment> get segments => List.unmodifiable(_pathSegments);
  bool get allSegmentsAreFixed => _pathSegments.every((s) => s.isComplete);
  PathSegment? get nextEmptySegment =>
      _pathSegments.firstWhereOrNull((s) => s.isNotComplete);

  Map<String, dynamic> serialize() => {
        'rows': rowCount,
        'cols': columnCount,
        'tiles': _tiles
            .map((tile) => tile?.serialize())
            .whereNot((tile) => tile == null)
            .toList(),
        'path_segments':
            _pathSegments.map((segment) => segment.serialize()).toList(),
      };

  static FixTracksGrid deserialize(Map<String, dynamic> json) {
    final rowCount = json['rows'] as int;
    final colCount = json['cols'] as int;
    final tiles = List<Tile?>.filled(rowCount * colCount, null);
    for (var tileData in (json['tiles'] as List)) {
      final tile = Tile.deserialize(tileData);
      tiles[tile.index] = tile;
    }

    return FixTracksGrid._(
      rowCount: rowCount,
      columnCount: colCount,
      tiles: tiles,
      pathSegments: (json['path_segments'] as List)
          .map((segment) => PathSegment.fromSerialized(segment))
          .toList(),
    );
  }

  FixTracksGrid._({
    required this.rowCount,
    required this.columnCount,
    List<Tile?>? tiles,
    List<PathSegment>? pathSegments,
  })  : _tiles = tiles ?? [],
        _pathSegments = pathSegments ?? [];

  Tile? tileAt({int? row, int? col, int? index}) {
    if ((row == null && col == null && index == null) ||
        (row != null && col != null && index != null) ||
        (index != null && (row != null || col != null)) ||
        (row != null && col == null || col != null && row == null)) {
      throw ArgumentError(
          'You must provide either a row and a column or an index');
    }

    if (row != null && col != null) {
      if (row < 0 || col < 0 || row >= rowCount || col >= columnCount) {
        return null;
      }
      index = row * columnCount + col;
    }

    if (index! < 0 || index >= cellCount) {
      return null;
    }
    return _tiles[index];
  }

  ///
  /// Generate a new grid with random paths
  /// [rowCount] Number of rows in the grid
  /// [columnCount] Number of columns in the grid
  /// [minimumSegmentLength] Minimum length of each path segment
  /// [maximumSegmentLength] Maximum length of each path segment
  /// [segmentCount] Expected number of path segments (must be odd)
  FixTracksGrid.random({
    required this.rowCount,
    required this.columnCount,
    required int minimumSegmentLength,
    required int maximumSegmentLength,
    required int segmentCount,
    required int segmentsWithLetterCount,
  })  : _tiles = [],
        _pathSegments = [] {
    int countAttempts = 0;
    while (true) {
      countAttempts++;
      if (countAttempts > 100) {
        throw Exception('Failed to generate a valid grid after 100 attempts');
      }
      // Create an empty grid
      _tiles.clear();
      for (var i = 0; i < cellCount; i++) {
        _tiles.add(Tile(
            index: i,
            row: i ~/ columnCount,
            col: i % columnCount,
            letter: null));
      }

      try {
        final isSuccess = _pathGeneration(
          minimumSegmentLength: minimumSegmentLength,
          maximumSegmentLength: maximumSegmentLength,
          expectedSegmentCount: segmentCount,
          segmentsWithLetterCount: segmentsWithLetterCount,
        );
        if (isSuccess) break;
      } catch (e) {
        // If it failed for some reason, just restart the process
        continue;
      }
    }
    _logging.info('Grid generated after $countAttempts attempts');
  }

  bool _pathGeneration({
    required int minimumSegmentLength,
    required int maximumSegmentLength,
    required int expectedSegmentCount,
    required int segmentsWithLetterCount,
  }) {
    if (expectedSegmentCount % 2 == 0) {
      throw ArgumentError('Expected segment count must be odd');
    }

    _pathSegments.clear();

    var startingTile = tileAt(index: _random.nextInt(columnCount));
    var direction = PathDirection.horizontal;
    int safetyCount = 0;
    List<bool> isTileAPath = List.filled(_tiles.length, false);
    while (true) {
      // Check for failing conditions that should trigger a restart of the algorithm
      if (safetyCount > rowCount) {
        return false;
      } else if (startingTile == null) {
        // We somehow got out of the grid
        return false;
      } else if (direction == PathDirection.vertical &&
          startingTile.row >= rowCount - minimumSegmentLength + 1 &&
          startingTile.row < rowCount - 1) {
        // Not enough space to continue vertically, but not at the end of the grid
        return false;
      }

      // Check for STOP conditions that should stop the algorithm
      safetyCount++;
      direction = direction.next();
      if (direction == PathDirection.horizontal &&
          startingTile.row == rowCount - 1) {
        // Only accept paths that generate the expected number of words
        if (_pathSegments.length != expectedSegmentCount) return false;
        break;
      }

      // Adjust the length if it does not fit
      final PathSegment? currentPathSegment = _generatePathSegment(
        startingTile: startingTile,
        direction: direction,
        minimumSegmentLength: minimumSegmentLength,
        maximumSegmentLength: maximumSegmentLength,
      );
      if (currentPathSegment == null) return false;
      _pathSegments.add(currentPathSegment);

      // Mark the path tiles as path and add random letters
      for (var i = 0; i < currentPathSegment.length; i++) {
        final currentTile =
            tileOfSegmentAt(segment: currentPathSegment, index: i);
        // If any tile is outside of the grid, reject the word
        if (currentTile == null) return false;
        isTileAPath[currentTile.index] = true;
      }

      // Move to cursor to the end (or beginning) of the word
      startingTile = tileAt(index: currentPathSegment.anchorTileIndex);
    }

    // Add a letter randomly to the segments (with the very first segment always with a letter)
    final segmentsToNotAddLetters =
        List.generate(expectedSegmentCount - 1, (int i) => i + 1);
    for (int i = 0; i < segmentsWithLetterCount - 1; i++) {
      // -1 to account for always having a letter in the first segment
      segmentsToNotAddLetters
          .removeAt(_random.nextInt(segmentsToNotAddLetters.length));
    }
    for (int i = 0; i < _pathSegments.length; i++) {
      if (segmentsToNotAddLetters.contains(i)) continue;
      final segment = _pathSegments[i];

      // Choose a random index in the segment to add a letter which is not the first or last letter,
      // except for the first segment which must have a letter at the start
      int letterIndex = i == 0 ? 0 : _random.nextInt(segment.length - 2) + 1;
      final tile = tileOfSegmentAt(segment: segment, index: letterIndex);
      if (tile == null) return false;
      tile.letter = ValuableLetter.getRandom(maxValue: 3);
    }

    // Now, simply remove all the non-path tiles in the grid as they are not useful
    for (int i = 0; i < _tiles.length; i++) {
      if (!isTileAPath[i]) _tiles[i] = null;
    }
    return true;
  }

  PathSegment? _generatePathSegment({
    required Tile? startingTile,
    required PathDirection direction,
    required int minimumSegmentLength,
    required int maximumSegmentLength,
  }) {
    if (startingTile == null) return null;

    // Choose a length for the next word between 4 and 8 letters
    var letterCount =
        _random.nextInt(maximumSegmentLength - minimumSegmentLength + 1) +
            minimumSegmentLength;

    switch (direction) {
      case PathDirection.horizontal:
        {
          bool fromStart = startingTile.col < columnCount ~/ 2;
          final maxLength =
              fromStart ? columnCount - startingTile.col : startingTile.col;
          if (letterCount > maxLength) letterCount = maxLength;

          if (!fromStart) {
            startingTile = tileAt(
                row: startingTile.row, col: startingTile.col - letterCount + 1);
            if (startingTile == null) return null;
          }
          final lastTile = tileAt(
              row: startingTile.row, col: startingTile.col + (letterCount - 1));
          if (lastTile == null) return null;

          return PathSegment(
            startingTileIndex: startingTile.index,
            anchorTileIndex: (fromStart ? lastTile : startingTile).index,
            length: letterCount,
            direction: direction,
            word: null,
          );
        }
      case PathDirection.vertical:
        {
          // Make sure the word fits in the column
          final maxLength = rowCount - startingTile.row;
          if (letterCount > maxLength) letterCount = maxLength;
          final lastTile = tileAt(
              row: startingTile.row + (letterCount - 1), col: startingTile.col);
          if (lastTile == null) return null;

          return PathSegment(
            startingTileIndex: startingTile.index,
            anchorTileIndex: lastTile.index,
            length: letterCount,
            direction: direction,
            word: null,
          );
        }
    }
  }

  Tile? tileOfSegmentAt({required PathSegment segment, required int index}) {
    final startingTile = tileAt(index: segment.startingTileIndex)!;
    return tileAt(
        row: switch (segment.direction) {
          PathDirection.horizontal => startingTile.row,
          PathDirection.vertical => startingTile.row + index,
        },
        col: switch (segment.direction) {
          PathDirection.horizontal => startingTile.col + index,
          PathDirection.vertical => startingTile.col,
        });
  }
}

class Tile {
  final int index;
  final int row;
  final int col;

  String? letter;
  bool get hasLetter => letter != null;

  Tile({
    required this.index,
    required this.row,
    required this.col,
    required this.letter,
  });

  Map<String, dynamic> serialize() => {
        'index': index,
        'row': row,
        'col': col,
        if (letter != null) 'letter': letter,
      };

  static Tile deserialize(Map<String, dynamic> data) {
    return Tile(
      index: data['index'] as int,
      row: data['row'] as int,
      col: data['col'] as int,
      letter: data['letter'] as String?,
    );
  }
}

enum PathDirection {
  vertical,
  horizontal;

  PathDirection next() {
    return PathDirection.values[
        (PathDirection.values.indexOf(this) + 1) % PathDirection.values.length];
  }
}

class PathSegment {
  final int length;
  final int startingTileIndex;
  final int anchorTileIndex;
  final PathDirection direction;

  String? word;
  bool get isComplete => word != null;
  bool get isNotComplete => !isComplete;

  PathSegment({
    required this.length,
    required this.startingTileIndex,
    required this.anchorTileIndex,
    required this.direction,
    required this.word,
  });

  Map<String, dynamic> serialize() => {
        'length': length,
        'starting_tile_index': startingTileIndex,
        'anchor_tile_index': anchorTileIndex,
        'direction': direction.index,
        if (word != null) 'word': word,
      };

  static PathSegment fromSerialized(Map<String, dynamic> data) {
    return PathSegment(
      length: data['length'] as int,
      startingTileIndex: data['starting_tile_index'] as int,
      anchorTileIndex: data['anchor_tile_index'] as int,
      direction: PathDirection.values[data['direction'] as int],
      word: data['word'] as String?,
    );
  }
}
