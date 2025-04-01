import 'package:common/generic/models/serializable_game_state.dart';

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

class SerializableTile {
  final int index;
  TileValue value;

  final LetterStatus uselessStatus;
  final LetterStatus hiddenStatus;
  final bool isRevealed;

  final bool hasTreasure;
  final bool hasLetter;
  bool get hasReward =>
      value == TileValue.treasure || value == TileValue.letter;

  SerializableTile({
    required this.index,
    required this.value,
    required this.uselessStatus,
    required this.hiddenStatus,
    required this.isRevealed,
    required this.hasTreasure,
    required this.hasLetter,
  });

  SerializableTile copyWith({
    int? index,
    TileValue? value,
    LetterStatus? uselessStatus,
    LetterStatus? hiddenStatus,
    bool? isRevealed,
    bool? hasTreasure,
    bool? hasLetter,
  }) =>
      SerializableTile(
        index: index ?? this.index,
        value: value ?? this.value,
        uselessStatus: uselessStatus ?? this.uselessStatus,
        hiddenStatus: hiddenStatus ?? this.hiddenStatus,
        isRevealed: isRevealed ?? this.isRevealed,
        hasTreasure: hasTreasure ?? this.hasTreasure,
        hasLetter: hasLetter ?? this.hasLetter,
      );
  Map<String, dynamic> serialize() {
    return {
      'index': index,
      'value': value.index,
      'useless_status': uselessStatus.index,
      'hidden_status': hiddenStatus.index,
      'is_revealed': isRevealed,
      'has_treasure': hasTreasure,
      'has_letter': hasLetter,
    };
  }

  static SerializableTile deserialize(Map<String, dynamic> data) {
    return SerializableTile(
      index: data['index'] as int,
      value: TileValue.values[data['value'] as int],
      uselessStatus: LetterStatus.values[data['useless_status'] as int],
      hiddenStatus: LetterStatus.values[data['hidden_status'] as int],
      isRevealed: data['is_revealed'] as bool,
      hasTreasure: data['has_treasure'] as bool,
      hasLetter: data['has_letter'] as bool,
    );
  }
}
