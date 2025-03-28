import 'dart:math';

final _rand = Random();

class GameTile {
  final int row;
  final int col;

  @override
  bool operator ==(other) =>
      other is GameTile && row == other.row && col == other.col;

  const GameTile(this.row, this.col);
  const GameTile.starting()
      : row = -1,
        col = -1;
  GameTile.random(int nbRows, int nbCols)
      : row = _rand.nextInt(nbRows),
        col = _rand.nextInt(nbCols);

  GameTile get copy => GameTile(row, col);

  @override
  int get hashCode => row.hashCode + col.hashCode;

  @override
  String toString() {
    return '($row, $col)';
  }
}
