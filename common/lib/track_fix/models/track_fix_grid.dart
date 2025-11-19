import 'dart:math';

import 'package:collection/collection.dart';

final _random = Random();

class Grid {
  final int rowCount;
  final int columnCount;
  final int minimumSegmentLength; // = 4;
  final int maximumSegmentLength; // = 8;
  final int expectedSegmentsCount; // = 9;

  int get cellCount => rowCount * columnCount;

  final List<Tile> _tiles;

  final List<PathSegment> _pathSegments;
  bool get allSegmentsAreFixed => _pathSegments.every((s) => s.isComplete);

  Map<String, dynamic> serialize() => {
        'rows': rowCount,
        'cols': columnCount,
        'minimum_segment_length': minimumSegmentLength,
        'maximum_segment_length': maximumSegmentLength,
        'expected_segments_count': expectedSegmentsCount,
        'tiles': _tiles.map((tile) => tile.serialize()).toList(),
        'path_segments':
            _pathSegments.map((segment) => segment.serialize()).toList(),
      };

  static Grid deserialize(Map<String, dynamic> json) {
    return Grid(
      rowCount: json['rows'] as int,
      columnCount: json['cols'] as int,
      minimumSegmentLength: json['minimum_segment_length'] as int,
      maximumSegmentLength: json['maximum_segment_length'] as int,
      expectedSegmentsCount: json['expected_segments_count'] as int,
      tiles: (json['tiles'] as List)
          .map((tile) => Tile.deserialize(tile))
          .toList(growable: false),
      pathSegments: (json['path_segments'] as List)
          .map((segment) => PathSegment.fromSerialized(segment))
          .toList(),
    );
  }

  Grid({
    required this.rowCount,
    required this.columnCount,
    required this.minimumSegmentLength,
    required this.maximumSegmentLength,
    required this.expectedSegmentsCount,
    List<Tile>? tiles,
    List<PathSegment>? pathSegments,
  })  : _tiles = tiles ?? [],
        _pathSegments = pathSegments ?? [] {
    if (tiles != null && tiles.length != cellCount) {
      throw ArgumentError(
          'The number of tiles must be equal to rowCount * columnCount');
    }

    if (pathSegments != null && pathSegments.length != expectedSegmentsCount) {
      throw ArgumentError(
          'The number of path segments must be equal to expectedSegmentsCount');
    }
  }

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
  /// Attempt to fix a segment with the given [word]
  /// Returns true if the segment was successfully fixed
  bool tryFixSegment(String word) {
    final segment =
        _pathSegments.firstWhereOrNull((segment) => segment.isNotComplete);
    if (segment == null) return false; // No more segments to fix

    // The word must have the correct length
    if (word.length != segment.length) return false;

    // Check that pre-existing letters match the provided word
    for (int i = 0; i < segment.length; i++) {
      final tile = tileOfSegmentAt(segment: segment, index: i);
      if (tile == null) return false;
      if (tile.hasLetter && tile.letter != word[i]) return false;
    }

    for (final segment in _pathSegments) {
      // The word must be unique among fixed segments
      if (segment.isComplete && segment.word == word) return false;
    }

    // All checks passed, fix the segment
    segment.word = word;
    for (int i = 0; i < segment.length; i++) {
      final tile = tileOfSegmentAt(segment: segment, index: i);
      if (tile == null) return false;
      tile.letter = word[i];
    }

    return true;
  }

  ///
  /// Generate a new grid with random paths
  /// [rowCount] Number of rows in the grid
  /// [columnCount] Number of columns in the grid
  /// [minimumSegmentLength] Minimum length of each path segment
  /// [maximumSegmentLength] Maximum length of each path segment
  /// [expectedSegmentsCount] Expected number of path segments (must be odd)
  Grid.random({
    required this.rowCount,
    required this.columnCount,
    required this.minimumSegmentLength,
    required this.maximumSegmentLength,
    required this.expectedSegmentsCount,
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
            isPath: false,
            letter: null));
      }

      try {
        final isSuccess = _pathGeneration();
        if (isSuccess) break;
      } catch (e) {
        // If it failed for some reason, just restart the process
        continue;
      }
    }
    print('Grid generated after $countAttempts attempts');
  }

  bool _pathGeneration() {
    if (expectedSegmentsCount % 2 == 0) {
      throw ArgumentError('expectedSegmentsCount must be odd');
    }

    _pathSegments.clear();

    var startingTile = tileAt(index: _random.nextInt(columnCount));
    startingTile!.letter = String.fromCharCode(_random.nextInt(26) + 65);
    var direction = PathDirection.horizontal;
    int safetyCount = 0;
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

      // Check for final conditions that should stop the algorithm
      safetyCount++;
      direction = direction.next();
      if (direction == PathDirection.horizontal &&
          startingTile.row == rowCount - 1) {
        // Only accept paths that generate the expected number of words
        return _pathSegments.length == expectedSegmentsCount;
      }

      // Adjust the length if it does not fit
      final PathSegment? currentPathSegment = _generatePathSegment(
          startingTile: startingTile, direction: direction);
      if (currentPathSegment == null) return false;
      _pathSegments.add(currentPathSegment);

      // Mark the path tiles as path
      for (var i = 0; i < currentPathSegment.length; i++) {
        final currentTile =
            tileOfSegmentAt(segment: currentPathSegment, index: i);
        if (currentTile == null) return false;
        currentTile._isPath = true;
      }

      // Move to cursor to the end (or beginning) of the word
      startingTile = tileAt(index: currentPathSegment.anchorTileIndex);
    }
  }

  PathSegment? _generatePathSegment({
    required Tile? startingTile,
    required PathDirection direction,
  }) {
    if (startingTile == null) return null;

    // Choose a length for the next word between 4 and 8 letters
    var lettersCount =
        _random.nextInt(maximumSegmentLength - minimumSegmentLength + 1) +
            minimumSegmentLength;

    switch (direction) {
      case PathDirection.horizontal:
        {
          bool fromStart = startingTile.col < columnCount ~/ 2;
          final maxLength =
              fromStart ? columnCount - startingTile.col : startingTile.col;
          if (lettersCount > maxLength) lettersCount = maxLength;

          if (!fromStart) {
            startingTile = tileAt(
                row: startingTile.row,
                col: startingTile.col - lettersCount + 1);
            if (startingTile == null) return null;
          }
          final lastTile = tileAt(
              row: startingTile.row,
              col: startingTile.col + (lettersCount - 1));
          if (lastTile == null) return null;

          return PathSegment(
            startingTileIndex: startingTile.index,
            anchorTileIndex: (fromStart ? lastTile : startingTile).index,
            length: lettersCount,
            direction: direction,
            word: null,
          );
        }
      case PathDirection.vertical:
        {
          // Make sure the word fits in the column
          final maxLength = rowCount - startingTile.row;
          if (lettersCount > maxLength) lettersCount = maxLength;
          final lastTile = tileAt(
              row: startingTile.row + (lettersCount - 1),
              col: startingTile.col);
          if (lastTile == null) return null;

          return PathSegment(
            startingTileIndex: startingTile.index,
            anchorTileIndex: lastTile.index,
            length: lettersCount,
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
  bool _isPath;
  bool get isPath => _isPath;

  String? letter;
  bool get hasLetter => letter != null;

  Tile({
    required this.index,
    required this.row,
    required this.col,
    required bool isPath,
    required this.letter,
  }) : _isPath = isPath;

  Map<String, dynamic> serialize() => {
        'index': index,
        'row': row,
        'col': col,
        'is_path': isPath,
        'letter': letter,
      };

  static Tile deserialize(Map<String, dynamic> data) {
    return Tile(
      index: data['index'] as int,
      row: data['row'] as int,
      col: data['col'] as int,
      isPath: data['isPath'] as bool,
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
        'word': word,
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
