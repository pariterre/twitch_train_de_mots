import 'dart:async';
import 'dart:math';

import 'package:common/generic/managers/dictionary_manager.dart';
import 'package:common/generic/managers/serializable_controllable_timer.dart';
import 'package:common/generic/models/exceptions.dart';
import 'package:common/generic/models/generic_listener.dart';
import 'package:common/generic/models/serializable_game_state.dart';
import 'package:common/generic/models/valuable_letter.dart';
import 'package:common/treasure_hunt/models/serializable_treasure_hunt_game_state.dart';
import 'package:common/treasure_hunt/models/treasure_hunt_grid.dart';
import 'package:diacritic/diacritic.dart';
import 'package:logging/logging.dart';
import 'package:train_de_mots/generic/managers/managers.dart';
import 'package:train_de_mots/generic/managers/mini_games_manager.dart';

final _logger = Logger('TreasureHuntGameManager');
final _random = Random();

///
/// Easy accessors translating index into row/col pair or row/col pair into
/// index

class TreasureHuntGameManager extends MiniGameManager {
  TreasureHuntGameManager() {
    _asyncInitializations();
  }

  Future<void> _asyncInitializations() async {
    _logger.config('Initializing...');

    while (true) {
      try {
        final tm = Managers.instance.twitch;
        tm.addChatListener(trySolution);
        break;
      } on ManagerNotInitializedException {
        // Wait and repeat
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }

    _logger.config('Ready');
  }

  ///
  /// Players points earned during the game
  final Map<String, int> _playersPoints = {};
  @override
  Map<String, int> get playersPoints => Map.from(_playersPoints);

  ///
  /// Current problem
  final _dictionary = DictionaryManager.wordsWithAtLeast(6).toList();
  SerializableLetterProblem? _problem;
  SerializableLetterProblem get problem =>
      _problem == null ? throw "This should not happen" : _problem!;
  List<String> get letters => List.from(problem.letters, growable: false);

  ///
  /// Number of tries remaining
  int _triesRemaining = 0;
  int get triesRemaining => _triesRemaining;

  ///
  /// Rewards when a treasure or a letter are found
  final Duration _rewardInTime = const Duration(seconds: 5);
  final int _rewardInTrials = 1;

  // Listeners
  final onTrySolution = GenericListener<
      Function(
          {required String playerName,
          required String word,
          required bool isSolutionRight,
          required int pointsAwarded})>();
  final onTileRevealed = GenericListener<Function(Tile)>();
  final onRewardFound = GenericListener<Function(Tile)>();

  // Size of the grid
  final int _rowCount = 20;
  final int _columnCount = 10;
  final int _rewardCount = 40;
  TreasureHuntGrid? _grid;
  TreasureHuntGrid get grid => _grid!;

  ///
  /// Get the number of letters that were found
  int get letterFoundCount => problem.hiddenLetterStatuses.fold(
      0, (prev, status) => prev + (status == LetterStatus.normal ? 1 : 0));

  ///
  /// End game status
  @override
  bool get hasWon => letterFoundCount == problem.letters.length;

  @override
  String? get instructions =>
      'Pendant que vous attendez que le train se prépare, pourquoi ne pas aller aux bleuets! '
      'Trouvez le mot mystère en découvrant des lettres dans le champ.\n\n'
      'Chaque bleuet trouvé vous redonne des essais, et regagnez du temps en trouvant des lettres.\n'
      'Mais attention, chaque tentative de mot ou de case vous coûtera un essai!\n\n';

  @override
  Future<void> initialize() async {
    _generateProblem();
    _grid = TreasureHuntGrid.random(
        rowCount: _rowCount,
        columnCount: _columnCount,
        rewardCount: _rewardCount,
        problem: _problem!);
    _triesRemaining = 10;
    _playersPoints.clear();

    await super.initialize();
  }

  @override
  SerializableTreasureHuntGameState serializeMiniGame() {
    return SerializableTreasureHuntGameState(
      roundTimer: roundTimer,
      grid: _grid!,
      triesRemaining: _triesRemaining,
    );
  }

  @override
  Duration get initialRoundDuration =>
      const Duration(seconds: 20) +
      Managers.instance.train.previousRoundTimeRemaining;

  void trySolution(String playerName, String message) {
    if (roundStatus != ControllableTimerStatus.inProgress) return;

    // Transform the message so it is only the first word all in uppercase
    final words = message.split(' ');
    if (words.isEmpty || words.length > 1 || words.first[0] == '!') return;

    final word = removeDiacritics(words.first.toUpperCase());
    // Refuse any word that contains non-letter characters
    if (!RegExp(r'^[A-Z]+$').hasMatch(word)) return;

    final wordValue = 5 *
        word
            .split('')
            .map((e) => ValuableLetter.getValueOfLetter(e))
            .reduce((a, b) => a + b);

    final isSolutionRight = word == problem.letters.join();
    if (isSolutionRight) {
      for (int i = 0; i < _problem!.uselessLetterStatuses.length; i++) {
        _problem!.uselessLetterStatuses[i] = LetterStatus.normal;
        _problem!.hiddenLetterStatuses[i] = LetterStatus.normal;
      }
      _playersPoints[playerName] = wordValue;
    } else {
      _triesRemaining--;
    }
    onTrySolution.notifyListeners((callback) => callback(
        playerName: playerName,
        word: word,
        isSolutionRight: isSolutionRight,
        pointsAwarded: wordValue));
  }

  ///
  /// Main interface for a user to reveal a tile from the grid
  bool revealTile({int? row, int? col, int? tileIndex}) {
    if (roundStatus == ControllableTimerStatus.initialized) {
      // The first revealed tile starts the game
      startRound();
    } else if (roundStatus != ControllableTimerStatus.inProgress) {
      return false;
    }

    final tile = _grid!.revealAt(row: row, col: col, index: tileIndex);
    if (tile == null) return false;

    // Change the values of the surrounding tiles if it is a reward
    switch (tile.value) {
      case TileValue.treasure:
        _triesRemaining += _rewardInTrials;
        if (tile.isLetter) {
          problem.hiddenLetterStatuses[tile.letterIndex!] = LetterStatus.normal;
          addTime(_rewardInTime);
        }

        onRewardFound.notifyListeners((callback) => callback(tile));
        break;
      default:
        _triesRemaining--;
    }

    onTileRevealed.notifyListeners((callback) => callback(tile));
    onGameUpdated.notifyListeners((callback) => callback());

    return true;
  }

  void _revealSolution() {
    // Reveal all the letters in the problem
    for (int i = 0; i < problem.letters.length; i++) {
      if (problem.hiddenLetterStatuses[i] == LetterStatus.hidden) {
        problem.hiddenLetterStatuses[i] = LetterStatus.revealed;
      }
    }

    // Reveal all the tiles in the grid
    for (int i = 0; i < _grid!.cellCount; i++) {
      final tile = _grid!.tileAt(index: i);
      if (tile == null || !tile.isLetter) continue;
      tile.reveal();
      onRewardFound.notifyListeners((callback) => callback(tile));
    }
  }

  ///
  /// Get a random word from the list (capitalized)
  void _generateProblem() {
    final word = _dictionary[_random.nextInt(_dictionary.length)];

    // One letter will not be on the grid. For internal reasons of LetterDisplayer, we must flag it as "revealed"
    final mysteryLetterIndex = _random.nextInt(word.length);

    _problem = SerializableLetterProblem(
      letters: word.split(''),
      scrambleIndices: List.generate(word.length, (index) => index),
      uselessLetterStatuses: List.generate(
          word.length,
          (i) => i == mysteryLetterIndex
              ? LetterStatus.revealed
              : LetterStatus.normal),
      hiddenLetterStatuses:
          List.generate(word.length, (_) => LetterStatus.hidden),
    );
  }

  @override
  void onRoundStatusChanged(ControllableTimerStatus newStatus) {
    if (newStatus == ControllableTimerStatus.ended) _processRoundIsEnding();

    super.onRoundStatusChanged(newStatus);
  }

  @override
  Future<bool> shouldEndRoundImmediately() async {
    return triesRemaining <= 0 || hasWon;
  }

  Future<void> _processRoundIsEnding() async {
    _revealSolution();
  }
}
