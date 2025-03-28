import 'package:common/models/simplified_game_state.dart';

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
  treasure,
  letter;

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
      case letter:
        return -2;
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
      case letter:
        return '';
    }
  }
}

class Tile {
  final int _index;
  int get index => _index;

  TileValue value;

  LetterStatus _uselessStatus = LetterStatus.normal;
  LetterStatus _hiddenStatus;
  bool get isConcealed => _hiddenStatus == LetterStatus.hidden;
  bool get isRevealed => !isConcealed;

  Tile(
      {required int index,
      required this.value,
      required bool isConcealed,
      required bool isUseless})
      : _index = index,
        _hiddenStatus =
            isConcealed ? LetterStatus.hidden : LetterStatus.revealed,
        _uselessStatus =
            isUseless ? LetterStatus.revealed : LetterStatus.normal;

  void addTreasure() => value = TileValue.treasure;
  void addLetter({required LetterStatus uselessStatus}) {
    value = TileValue.letter;
    _uselessStatus = uselessStatus;
  }

  bool get hasTreasure => value == TileValue.treasure;
  bool get hasLetter =>
      value == TileValue.letter && _uselessStatus == LetterStatus.normal;
  bool get hasReward =>
      value == TileValue.treasure || value == TileValue.letter;
  bool get hasNoReward => !hasReward;

  void decrement() {
    if (hasReward) return;
    if (value == TileValue.zero) return;

    value = TileValue.values[value.value - 1];
  }

  void reveal() {
    _hiddenStatus = LetterStatus.revealed;
  }
}
