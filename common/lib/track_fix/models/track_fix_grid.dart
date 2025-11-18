import 'dart:math';

import 'package:common/generic/models/serializable_game_state.dart';

final _random = Random();

enum _Direction {
  vertical,
  horizontal;

  _Direction next() {
    return _Direction.values[
        (_Direction.values.indexOf(this) + 1) % _Direction.values.length];
  }
}

class _Word {
  final int letterCount;
  final int startIndex;
  final _Direction direction;

  _Word({
    required this.letterCount,
    required this.startIndex,
    required this.direction,
  });
}

class Grid {
  final int rowCount;
  final int columnCount;
  int get cellCount => rowCount * columnCount;
  final int rewardsCount;

  final List<Tile> _tiles;

  Map<String, dynamic> serialize() => {
        'rows': rowCount,
        'cols': columnCount,
        'rewards_count': rewardsCount,
        'tiles': _tiles.map((tile) => tile.serialize()).toList(),
      };

  static Grid deserialize(Map<String, dynamic> json) {
    return Grid(
      rowCount: json['rows'] as int,
      columnCount: json['cols'] as int,
      rewardsCount: json['rewards_count'] as int,
      tiles: (json['tiles'] as List)
          .map((tile) => Tile.deserialize(tile))
          .toList(growable: false),
    );
  }

  Grid({
    required this.rowCount,
    required this.columnCount,
    required this.rewardsCount,
    List<Tile>? tiles,
  }) : _tiles = tiles ?? [] {
    if (tiles != null && tiles.length != cellCount) {
      throw ArgumentError(
          'The number of tiles must be equal to rowCount * columnCount');
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
  /// Generate a new grid with random paths
  Grid.random({
    required this.rowCount,
    required this.columnCount,
    required this.rewardsCount,
    SerializableLetterProblem? problem,
  }) : _tiles = [] {
    // First, choose a starting point and direction for the path on the top row
    final minimumLetterCount = 4;
    final maximumLetterCount = 8;
    final expectedWordsCount = 9; // Must be odd

    List<_Word>? words = <_Word>[];
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
        words = _pathGeneration(
            minimumLetterCount, maximumLetterCount, expectedWordsCount);
        if (words != null) break;
      } catch (e) {
        // If it failed for some reason, just restart the process
        continue;
      }
    }
    print('Grid generated after $countAttempts attempts');
  }

  List<_Word>? _pathGeneration(
      int minimumLetterCount, int maximumLetterCount, int expectedWordsCount) {
    if (expectedWordsCount % 2 == 0) {
      throw ArgumentError('expectedWordsCount must be odd');
    }

    final words = <_Word>[];

    var startingTile = tileAt(index: _random.nextInt(columnCount));
    startingTile!.letter = String.fromCharCode(_random.nextInt(26) + 65);
    var direction = _Direction.horizontal;
    int safetyCount = 0;
    while (true) {
      // Check for failing conditions that should trigger a restart of the algorithm
      if (safetyCount > rowCount) {
        return null;
      } else if (startingTile == null) {
        // We somehow got out of the grid
        return null;
      } else if (direction == _Direction.vertical &&
          startingTile.row >= rowCount - minimumLetterCount + 1 &&
          startingTile.row < rowCount - 1) {
        // Not enough space to continue vertically, but not at the end of the grid
        return null;
      }

      // Check for final conditions that should stop the algorithm
      safetyCount++;
      direction = direction.next();
      if (direction == _Direction.horizontal &&
          startingTile.row == rowCount - 1) {
        // Only accept paths that generate at least 6 words
        return words.length != expectedWordsCount ? null : words;
      }

      // Choose a length for the next word between 4 and 8 letters
      var lettersCount =
          _random.nextInt(maximumLetterCount - minimumLetterCount + 1) +
              minimumLetterCount;

      // Adjust the length if it does not fit
      bool fromStart = true;
      if (direction == _Direction.horizontal) {
        fromStart = startingTile.col < columnCount ~/ 2;
        final maxLength =
            fromStart ? columnCount - startingTile.col : startingTile.col;
        if (lettersCount > maxLength) lettersCount = maxLength;

        if (!fromStart) {
          startingTile = tileAt(
              row: startingTile.row, col: startingTile.col - lettersCount);
          if (startingTile == null) return null;
        }
      } else {
        // Make sure the word fits in the column
        final maxLength = rowCount - startingTile.row;
        if (lettersCount > maxLength) lettersCount = maxLength;
      }

      // Find a position that is valid for this direction and length
      var startingRow = startingTile.row;
      var startingCol = startingTile.col;
      words.add(_Word(
          letterCount: lettersCount,
          startIndex: startingTile.index,
          direction: direction));

      // Mark the path tiles as path
      Tile? currentTile = startingTile;
      for (var i = 0; i < lettersCount; i++) {
        currentTile = tileAt(
            row: switch (direction) {
              _Direction.horizontal => startingRow,
              _Direction.vertical => startingRow + i,
            },
            col: switch (direction) {
              _Direction.horizontal => startingCol + i,
              _Direction.vertical => startingCol,
            });
        if (currentTile == null) return null;
        currentTile._isPath = true;
      }

      // Move to cursor to the end (or beginning) of the word
      if (fromStart) startingTile = currentTile;
    }
  }

  ///
  /// Reveal a tile at the given index.
  Tile? revealAt({int? row, int? col, int? index, required String letter}) {
    // Start the recursive process of revealing all the required tiles
    final tile = tileAt(row: row, col: col, index: index);
    if (tile == null) return null;
    tile.letter = letter;
    return tile;
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
