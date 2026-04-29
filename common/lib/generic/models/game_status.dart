enum WordsTrainGameStatus {
  uninitialized,
  initializing,
  roundPreparing,
  roundReady,
  roundStarted,
  roundEnding;

  String get serialized {
    switch (this) {
      case WordsTrainGameStatus.uninitialized:
        return 'uninitialized';
      case WordsTrainGameStatus.initializing:
        return 'initializing';
      case WordsTrainGameStatus.roundPreparing:
        return 'round_preparing';
      case WordsTrainGameStatus.roundReady:
        return 'round_ready';
      case WordsTrainGameStatus.roundStarted:
        return 'round_started';
      case WordsTrainGameStatus.roundEnding:
        return 'round_ending';
    }
  }

  static WordsTrainGameStatus deserialize(String value) {
    switch (value) {
      case 'uninitialized':
        return WordsTrainGameStatus.uninitialized;
      case 'initializing':
        return WordsTrainGameStatus.initializing;
      case 'round_preparing':
        return WordsTrainGameStatus.roundPreparing;
      case 'round_ready':
        return WordsTrainGameStatus.roundReady;
      case 'round_started':
        return WordsTrainGameStatus.roundStarted;
      case 'round_ending':
        return WordsTrainGameStatus.roundEnding;
      case 'mini_game_preparing':
      default:
        throw ArgumentError('Invalid game status: $value');
    }
  }
}
