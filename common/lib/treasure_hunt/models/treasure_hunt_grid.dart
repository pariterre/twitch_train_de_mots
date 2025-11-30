import 'dart:math';

import 'package:common/generic/models/serializable_game_state.dart';

final _random = Random();

enum TileValue {
  zero,
  one,
  two,
  three,
  four,
  five,
  six,
  seven,
  eight,
  treasure;

  int get value {
    switch (this) {
      case zero:
        return 0;
      case one:
        return 1;
      case two:
        return 2;
      case three:
        return 3;
      case four:
        return 4;
      case five:
        return 5;
      case six:
        return 6;
      case seven:
        return 7;
      case eight:
        return 8;
      case treasure:
        return -1;
    }
  }

  @override
  String toString() {
    switch (this) {
      case zero:
        return '';
      case one:
        return '1';
      case two:
        return '2';
      case three:
        return '3';
      case four:
        return '4';
      case five:
        return '5';
      case six:
        return '6';
      case seven:
        return '7';
      case eight:
        return '8';
      case treasure:
        return '';
    }
  }
}

class TreasureHuntGrid {
  final int rowCount;
  final int columnCount;
  int get cellCount => rowCount * columnCount;
  final int rewardCount;

  final List<Tile> _tiles;

  Map<String, dynamic> serialize() => {
        'rows': rowCount,
        'cols': columnCount,
        'rewards_count': rewardCount,
        'tiles': _tiles.map((tile) => tile.serialize()).toList(),
      };

  static TreasureHuntGrid deserialize(Map<String, dynamic> json) {
    return TreasureHuntGrid(
      rowCount: json['rows'] as int,
      columnCount: json['cols'] as int,
      rewardCount: json['rewards_count'] as int,
      tiles: (json['tiles'] as List)
          .map((tile) => Tile.deserialize(tile))
          .toList(growable: false),
    );
  }

  TreasureHuntGrid({
    required this.rowCount,
    required this.columnCount,
    required this.rewardCount,
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
  /// Generate a new grid with randomly positionned rewards
  TreasureHuntGrid.random({
    required this.rowCount,
    required this.columnCount,
    required this.rewardCount,
    SerializableLetterProblem? problem,
  }) : _tiles = [] {
    // Create an empty grid
    for (var i = 0; i < cellCount; i++) {
      _tiles.add(Tile(
        index: i,
        row: i ~/ columnCount,
        col: i % columnCount,
        value: TileValue.zero,
        isConcealed: true,
        isMysteryLetter: false,
      ));
    }

    // Populate it with rewards
    for (var i = 0; i < rewardCount; i++) {
      var rewardIndex = -1;
      do {
        rewardIndex = _random.nextInt(cellCount);
        // Make sure it this tile does not already have a reward
      } while (_tiles[rewardIndex].hasReward);

      if (i < (problem?.letters.length ?? -1)) {
        _tiles[rewardIndex].addLetter(
            letter: problem!.letters[i],
            letterIndex: i,
            isMystery:
                problem.uselessLetterStatuses[i] == LetterStatus.revealed);
      } else {
        _tiles[rewardIndex].addTreasure();
      }
    }

    // Recalculate the value of each tile based on number of rewards around it
    for (var i = 0; i < cellCount; i++) {
      final currentTile = _tiles[i];
      // Do not recompute tile with a reward in it
      if (currentTile.hasReward) continue;

      var rewardCountAroundTile = 0;

      // Check the previous row to next row
      for (var j = -1; j <= 1; j++) {
        // Check the previous col to next col
        for (var k = -1; k <= 1; k++) {
          // Do not check itself
          if (j == 0 && k == 0) continue;

          // Find the current checked tile
          final checkedTile =
              tileAt(row: currentTile.row + j, col: currentTile.col + k);
          if (checkedTile == null) continue;

          // If there is a rewared, add it to the counter
          if (checkedTile.hasReward) rewardCountAroundTile++;
        }
      }

      // Store the number in the tile
      _tiles[i]._value = TileValue.values[rewardCountAroundTile];
    }
  }

  ///
  /// Reveal a tile at the given index. If it is a zero, it is recursively called to all its
  /// neighbourhood so it automatically reveals all the surroundings. Returns the tile
  /// that was revealed, if any.
  Tile? revealAt({int? row, int? col, int? index}) {
    // Start the recursive process of revealing all the required tiles
    final tile = tileAt(row: row, col: col, index: index);
    if (tile == null || tile.isRevealed) return null;

    if (tile.hasReward) _adjustSurroundingHints(tile);

    // Start the recursive process of revealing all the surronding tiles
    _revealSurrondingTiles(tile);

    return tile;
  }

  ///
  /// Reveal a tile. If it is a zero, it is recursively called to all its
  /// neighbourhood so it automatically reveals all the surroundings
  void _revealSurrondingTiles(Tile tile, {List<bool>? isChecked}) {
    // For each zeros encountered, we must check around if it is another zero
    // so it can be reveal. We must make sure we don't recheck a previously
    // checked tile though so we don't go in an infinite loop of checking.
    isChecked ??= List.filled(cellCount, false); // If first time

    // If it is already revealed, do nothing
    if (isChecked[tile.index]) return;
    isChecked[tile.index] = true;

    // Reveal the current tile
    tile.reveal();

    // If the current tile is not zero, stop revealing, otherwise reveal the tiles around
    if (tile.value != TileValue.zero) return;

    for (var j = -1; j <= 1; j++) {
      for (var k = -1; k <= 1; k++) {
        // Do not reveal itself
        if (j == 0 && k == 0) continue;

        // Do not try to reveal tile outside of the grid
        final newTile = tileAt(row: tile.row + j, col: tile.col + k);
        if (newTile == null) continue;

        // If current tile is a reward, only reveal new zeros
        if (tile.hasReward && newTile.value == TileValue.zero) continue;

        // Reveal the tile if it was not already revealed
        _revealSurrondingTiles(newTile, isChecked: isChecked);
      }
    }
  }

  ///
  /// When a reward is found, lower all the surronding numbers
  void _adjustSurroundingHints(Tile tile) {
    for (var j = -1; j <= 1; j++) {
      // Check the previous col to next col
      for (var k = -1; k <= 1; k++) {
        // Do not check itself
        if (j == 0 && k == 0) continue;

        final nextTile = tileAt(row: tile.row + j, col: tile.col + k);
        if (nextTile == null) continue;
        // If this is not a reward, reduce that tile by one
        nextTile.decrement();
      }
    }
  }

  ///
  /// Get the number of rewards that were found
  int get revealedRewardCount => _tiles.fold(
      0, (prev, tile) => prev + (tile.isRevealed && tile.hasReward ? 1 : 0));
}

class Tile {
  final int index;
  final int row;
  final int col;

  TileValue _value;
  TileValue get value => _value;

  String? _letter;
  String? get letter => _letter;
  int? _letterIndex;
  int? get letterIndex => _letterIndex;

  bool _isConcealed;
  bool get isConcealed => _isConcealed;
  bool get isRevealed => !_isConcealed;

  ///
  /// If a letter is mystery, it means it is not possible to reveal it at all
  bool _isMysteryLetter;
  bool get isMysteryLetter => _isMysteryLetter;

  Tile(
      {required this.index,
      required this.row,
      required this.col,
      required TileValue value,
      required bool isConcealed,
      required bool isMysteryLetter})
      : _value = value,
        _isConcealed = isConcealed,
        _isMysteryLetter = isMysteryLetter;

  void addTreasure() => _value = TileValue.treasure;
  void addLetter(
      {required String letter,
      required int letterIndex,
      required bool isMystery}) {
    _letter = letter;
    _letterIndex = letterIndex;
    _value = TileValue.treasure;
    _isMysteryLetter = isMystery;
  }

  bool get isTreasure => value == TileValue.treasure && _letter == null;
  bool get isLetter =>
      value == TileValue.treasure && _letter != null && !_isMysteryLetter;
  bool get hasReward => value == TileValue.treasure;
  bool get hasNoReward => !hasReward;

  void decrement() {
    if (hasReward) return;
    if (value == TileValue.zero) return;

    _value = TileValue.values[value.value - 1];
  }

  void reveal() => _isConcealed = false;

  Map<String, dynamic> serialize() => {
        'index': index,
        'row': row,
        'col': col,
        'value': value.index,
        'is_concealed': isConcealed,
        'is_mystery': isMysteryLetter,
      };

  static Tile deserialize(Map<String, dynamic> data) {
    return Tile(
      index: data['index'] as int,
      row: data['row'] as int,
      col: data['col'] as int,
      value: TileValue.values[data['value'] as int],
      isConcealed: data['is_concealed'] as bool,
      isMysteryLetter: data['is_mystery'] as bool,
    );
  }
}
