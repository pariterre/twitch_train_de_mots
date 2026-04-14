import 'dart:math';

import 'package:common/generic/models/serializable_game_state.dart';

final _random = Random();

enum TileContent {
  empty,
  box,
  letter;
}

class WarehouseCleaningGrid {
  final int rowCount;
  final int columnCount;
  int get cellCount => rowCount * columnCount;

  final List<Tile> _tiles;

  Map<String, dynamic> serialize() => {
        'rows': rowCount,
        'cols': columnCount,
        'tiles': _tiles.map((tile) => tile.serialize()).toList(),
      };

  static WarehouseCleaningGrid deserialize(Map<String, dynamic> json) {
    return WarehouseCleaningGrid(
      rowCount: json['rows'] as int,
      columnCount: json['cols'] as int,
      tiles: (json['tiles'] as List)
          .map((tile) => Tile.deserialize(tile))
          .toList(growable: false),
    );
  }

  WarehouseCleaningGrid({
    required this.rowCount,
    required this.columnCount,
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
  /// Generate a new grid with randomly positionned letters
  WarehouseCleaningGrid.random({
    required this.rowCount,
    required this.columnCount,
    required int startingRow,
    required int startingCol,
    SerializableLetterProblem? problem,
  }) : _tiles = _MazeGenerator.generate(
            rowCount: rowCount,
            columnCount: columnCount,
            startingRow: startingRow,
            startingCol: startingCol) {
    // Add the letters in random positions of the grid
    if (problem != null) {
      for (int i = 0; i < problem.letters.length; i++) {
        final letter = problem.letters[i];
        final isMystery =
            problem.uselessLetterStatuses[i] == LetterStatus.revealed;
        while (true) {
          final row = _random.nextInt(rowCount);
          final col = _random.nextInt(columnCount);
          if (row == startingRow && col == startingCol) continue;

          final tile = tileAt(row: row, col: col);
          if (tile != null && tile.isEmpty) {
            tile.addLetter(
                letter: letter, letterIndex: i, isMystery: isMystery);
            break;
          }
        }
      }
    }
  }

  ///
  /// Reveal a tile at the given index. If it is a zero, it is recursively called to all its
  /// neighbourhood so it automatically reveals all the surroundings. Returns the tile
  /// that was revealed, if any.
  Tile? revealAt({int? row, int? col, int? index, bool propagate = true}) {
    // Start the recursive process of revealing all the required tiles
    final tile = tileAt(row: row, col: col, index: index);
    if (tile == null) return null;

    tile.reveal();
    // Reveal all the surrounding tiles
    if (propagate) {
      for (int j = -2; j <= 2; j++) {
        for (int k = -2; k <= 2; k++) {
          if (j == 0 && k == 0) continue;

          revealAt(row: tile.row + j, col: tile.col + k, propagate: false);
        }
      }
    }
    return tile;
  }

  ///
  /// Get the number of letters that were found
  int get revealedLetterCount => _tiles.fold(
      0, (prev, tile) => prev + (tile.isRevealed && tile.hasLetter ? 1 : 0));
}

class Tile {
  final int index;
  final int row;
  final int col;

  TileContent _content;
  TileContent get content => _content;

  String? _letter;
  String? get letter => _letter;
  int? _letterIndex;
  int? get letterIndex => _letterIndex;

  bool _isConcealed;
  bool get isConcealed => _isConcealed;
  bool get isRevealed => !_isConcealed;

  bool _isVisited = false;
  bool get isVisited => _isVisited;
  bool get isNotVisited => !isVisited;
  void markVisited() => _isVisited = true;

  ///
  /// If a letter is mystery, it means it is not possible to reveal it at all
  bool _isMysteryLetter;
  bool get isMysteryLetter => _isMysteryLetter;
  bool get isNotMysteryLetter => !isMysteryLetter;

  Tile({
    required this.index,
    required this.row,
    required this.col,
    required TileContent content,
    required bool isConcealed,
    required bool isMysteryLetter,
    bool isVisited = false,
  })  : _content = content,
        _isConcealed = isConcealed,
        _isMysteryLetter = isMysteryLetter,
        _isVisited = isVisited;

  void addTreasure() => _content = TileContent.letter;
  void addLetter({
    required String letter,
    required int letterIndex,
    required bool isMystery,
  }) {
    _letter = letter;
    _letterIndex = letterIndex;
    _content = TileContent.letter;
    _isMysteryLetter = isMystery;
  }

  bool get isLetter => content == TileContent.letter && _letter != null;
  bool get hasLetter => content == TileContent.letter;
  bool get isBox => content == TileContent.box;
  bool get isEmpty => content == TileContent.empty;

  void reveal() => _isConcealed = false;

  Map<String, dynamic> serialize() => {
        'index': index,
        'row': row,
        'col': col,
        'value': content.index,
        'is_concealed': isConcealed,
        'is_mystery': isMysteryLetter,
      };

  static Tile deserialize(Map<String, dynamic> data) {
    return Tile(
      index: data['index'] as int,
      row: data['row'] as int,
      col: data['col'] as int,
      content: TileContent.values[data['value'] as int],
      isConcealed: data['is_concealed'] as bool,
      isMysteryLetter: data['is_mystery'] as bool,
    );
  }
}

class _MazeGenerator {
  ///
  /// This function carves a perfect maze of TileContent.empty inside a grid of TileContent.box.
  /// This means the surronding of the maze will always be walls, and there will be a single path between any two points of the maze.
  ///
  static List<Tile> generate({
    required int rowCount,
    required int columnCount,
    required int startingRow,
    required int startingCol,
  }) {
    // columnCount and rowCount should be odd to have a perfect maze with walls around
    if (columnCount % 2 == 0 || rowCount % 2 == 0) {
      throw ArgumentError(
          'columnCount and rowCount should be odd to have a perfect maze with walls around');
    }

    final logicalRowCount = rowCount ~/ 2;
    final logicalColumnCount = columnCount ~/ 2;
    final logicalStartingRow = startingRow ~/ 2;
    final logicalStartingCol = startingCol ~/ 2;

    final maze = _generateLogicalMaze(
        rowCount: logicalRowCount,
        columnCount: logicalColumnCount,
        startingRow: logicalStartingRow,
        startingCol: logicalStartingCol);

    final tiles = <Tile>[];

    // initialize all as walls
    final grid = List.generate(
      rowCount,
      (row) => List.generate(
        columnCount,
        (col) => Tile(
          index: row * columnCount + col,
          row: row,
          col: col,
          content: TileContent.box,
          isConcealed: true,
          isMysteryLetter: false,
        ),
      ),
    );

    // carve paths
    for (int y = 0; y < logicalRowCount; y++) {
      for (int x = 0; x < logicalColumnCount; x++) {
        final gx = 2 * x + 1;
        final gy = 2 * y + 1;

        grid[gy][gx]._content = TileContent.empty;

        for (final n in maze[y][x]) {
          final wallX = x + n.x + 1;
          final wallY = y + n.y + 1;

          grid[wallY][wallX]._content = TileContent.empty;
        }
      }
    }

    // Create holes in the perfect maze to make more paths
    for (int i = 0; i < (rowCount * columnCount) ~/ 10; i++) {
      final row = _random.nextInt(rowCount);
      final col = _random.nextInt(columnCount);
      // Do not create holes on the borders
      if (row == 0 ||
          row == rowCount - 1 ||
          col == 0 ||
          col == columnCount - 1) {
        continue;
      }

      if (grid[row][col].isBox) {
        grid[row][col]._content = TileContent.empty;
      }
    }

    // Make sure the starting position is empty
    grid[startingRow][startingCol]._content = TileContent.empty;

    // flatten
    for (final row in grid) {
      tiles.addAll(row);
    }

    return tiles;
  }

  static List<List<List<Point<int>>>> _generateLogicalMaze({
    required int rowCount,
    required int columnCount,
    required int startingRow,
    required int startingCol,
  }) {
    final visited = List.generate(
        rowCount, (_) => List.generate(columnCount, (_) => false));

    final maze = List.generate(
        rowCount, (_) => List.generate(columnCount, (_) => <Point<int>>[]));

    List<Point<int>> neighbors(int x, int y) {
      final dirs = [
        const Point(0, 1),
        const Point(1, 0),
        const Point(0, -1),
        const Point(-1, 0),
      ]..shuffle(_random);

      return dirs
          .map((d) => Point(x + d.x, y + d.y))
          .where((p) =>
              p.x >= 0 && p.x < columnCount && p.y >= 0 && p.y < rowCount)
          .toList();
    }

    void dfs(int x, int y) {
      visited[y][x] = true;

      for (final n in neighbors(x, y)) {
        if (!visited[n.y][n.x]) {
          maze[y][x].add(n);
          maze[n.y][n.x].add(Point(x, y));
          dfs(n.x, n.y);
        }
      }
    }

    // Start the DFS from the middle of the grid to have a more interesting maze
    dfs(startingCol, startingRow);
    return maze;
  }
}
