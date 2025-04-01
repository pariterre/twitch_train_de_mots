import 'package:common/generic/models/serializable_game_state.dart';
import 'package:common/treasure_hunt/serializable_tile.dart';
import 'package:train_de_mots/generic/managers/managers.dart';

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
      value == TileValue.letter &&
      (_uselessStatus == LetterStatus.normal ||
          Managers.instance.miniGames.treasureHunt.isGameOver);
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

  SerializableTile serialize() => SerializableTile(
        index: _index,
        value: value,
        uselessStatus: _uselessStatus,
        hiddenStatus: _hiddenStatus,
        isRevealed: isRevealed,
        hasTreasure: hasTreasure,
        hasLetter: hasLetter,
      );
}
