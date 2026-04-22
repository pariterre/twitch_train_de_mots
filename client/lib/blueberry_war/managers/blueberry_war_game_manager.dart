import 'dart:async';
import 'dart:math';

import 'package:common/blueberry_war/models/agent.dart';
import 'package:common/blueberry_war/models/blueberry_agent.dart';
import 'package:common/blueberry_war/models/blueberry_war_game_manager_helpers.dart';
import 'package:common/blueberry_war/models/letter_agent.dart';
import 'package:common/blueberry_war/models/serializable_blueberry_war_game_state.dart';
import 'package:common/generic/managers/dictionary_manager.dart';
import 'package:common/generic/managers/serializable_controllable_timer.dart';
import 'package:common/generic/models/exceptions.dart';
import 'package:common/generic/models/generic_listener.dart';
import 'package:common/generic/models/serializable_game_state.dart';
import 'package:common/generic/models/valuable_letter.dart';
import 'package:diacritic/diacritic.dart';
import 'package:logging/logging.dart';
import 'package:train_de_mots/generic/managers/managers.dart';
import 'package:train_de_mots/generic/managers/mini_games_manager.dart';
import 'package:vector_math/vector_math.dart';

final _logger = Logger('BlueberryWarGameManager');
final _random = Random();

final _dictionary = DictionaryManager.wordsWithAtLeast(10).toList();

///
/// Easy accessors translating index into row/col pair or row/col pair into
/// index

class BlueberryWarGameManager extends MiniGameManager {
  bool _hasWon = false;
  @override
  bool get hasWon => _hasWon;

  ///
  /// The points each player has earned in the mini game
  final Map<String, int> _playersPoints = {};
  @override
  Map<String, int> get playersPoints => Map.from(_playersPoints);

  ///
  /// Current problem for the game
  SerializableLetterProblem? _problem;
  SerializableLetterProblem get problem => _problem!;

  ///
  /// List of agents in the game (blueberries and letters)
  final allAgents = <Agent>[];
  List<LetterAgent> get letters =>
      allAgents.whereType<LetterAgent>().toList(growable: false);
  List<BlueberryAgent> get blueberries =>
      allAgents.whereType<BlueberryAgent>().toList(growable: false);

  // Listeners
  final onLetterHitByBlueberry =
      GenericListener<Function(int letterIndex, bool isDestroyed)>();
  final onLetterHitByLetter = GenericListener<
      Function(int firstIndex, int secondIndex, bool firstIsBoss,
          bool secondIsBoss)>();
  final onBlueberryDestroyed = GenericListener<Function(int blueberryIndex)>();
  final onTrySolution = GenericListener<
      Function({
        required String playerName,
        required String word,
        required bool isSolutionRight,
        required int pointsAwarded,
      })>();

  ///
  /// Constructor
  BlueberryWarGameManager() {
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

  @override
  String? get instructions =>
      'Un mot s\'est enfuit et tente de vous narguer dans le champ de bleuets!\n'
      'Lancer lui tout ce que vous pouvez pour le récupérer et gagner une étoile.\n\n'
      'Utilisez l\'extension dans votre écran pour lancer les bleuets sur les lettres,\n'
      'et ainsi le révéler.\n'
      'La guerre des bleuets est ouverte!';

  ///
  /// Initialize the game manager
  @override
  Future<void> initialize() async {
    _logger.fine('BlueberryWarGameManager initializing');

    _hasWon = false;
    _playersPoints.clear();
    _generateProblem();

    // Populate letters with random agents
    allAgents.clear();
    for (int i = 0; i < _problem!.letters.length; i++) {
      final isBoss =
          _problem!.uselessLetterStatuses[i] == LetterStatus.revealed;
      allAgents.add(
        LetterAgent(
          id: i,
          isBoss: isBoss,
          problemIndex: i,
          letter: _problem!.letters[i],
          position: Vector2(
            BlueberryWarConfig.fieldSize.x * 2 / 3,
            BlueberryWarConfig.fieldSize.y * 2 / 5,
          ),
          velocity: isBoss
              ? Vector2.zero()
              : Vector2(
                  _random.nextDouble() * 1500 - 750,
                  _random.nextDouble() * 1500 - 750,
                ),
          maxVelocity: BlueberryWarConfig.letterMaxVelocity,
          radius: Vector2(40.0, 50.0),
          mass: 1.0,
          coefficientOfFriction: (isBoss ? -0.1 : 0.3),
        ),
      );
    }

    // Populate blueberries with random agents
    for (int i = 0; i < BlueberryWarConfig.initialBlueberryCount; i++) {
      allAgents.add(
        BlueberryAgent(
          id: i + 1000,
          position: BlueberryAgent.generateRandomStartingPosition(
            blueberryFieldSize: BlueberryWarConfig.blueberryFieldSize,
            blueberryRadius: BlueberryWarConfig.blueberryRadius,
          ),
          velocity: Vector2.zero(),
          isInField: false,
          maxVelocity: BlueberryWarConfig.blueberryMaxVelocity,
          radius: BlueberryWarConfig.blueberryRadius,
          mass: 3.0,
          coefficientOfFriction: 0.8,
        ),
      );
    }

    await super.initialize();
  }

  @override
  Duration get initialRoundDuration =>
      const Duration(seconds: 35) +
      Managers.instance.train.previousRoundTimeRemaining;

  void slingShoot(
      {required BlueberryAgent blueberry, required Vector2 newVelocity}) {
    if (roundStatus != ControllableTimerStatus.inProgress) return;

    if (blueberry.canBeSlingShot) {
      _logger.fine(
          'Sling shooting blueberry ${blueberry.id} with velocity $newVelocity');

      // Ensure the velocity is within a reasonable range
      double scale = 1.0;
      if (newVelocity.length2 >
          (blueberry.maxVelocity * blueberry.maxVelocity)) {
        scale = blueberry.maxVelocity / newVelocity.length;
      }

      blueberry.velocity = newVelocity * scale;

      onGameUpdated.notifyListeners((callback) => callback());
    } else {
      _logger.warning(
          'Blueberry ${blueberry.id} cannot be slingshot, ignoring request');
    }
  }

  void trySolution(String playerName, String message) {
    if (roundStatus != ControllableTimerStatus.inProgress) return;

    // Transform the message so it is only the first word all in uppercase
    final words = message.split(' ');
    if (words.isEmpty || words.length > 1) return;

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
      _hasWon = true;
      for (int i = 0; i < _problem!.uselessLetterStatuses.length; i++) {
        _problem!.uselessLetterStatuses[i] = LetterStatus.normal;
        _problem!.hiddenLetterStatuses[i] = LetterStatus.normal;
      }
      _playersPoints[playerName] = wordValue;
    }
    onTrySolution.notifyListeners((callback) => callback(
        playerName: playerName,
        word: word,
        isSolutionRight: isSolutionRight,
        pointsAwarded: wordValue));
  }

  ///
  /// Get a random word from the list (capitalized)
  void _generateProblem() {
    final word = _dictionary[_random.nextInt(_dictionary.length)];

    // One letter will not be on the grid. For internal reasons of LetterDisplayer,
    // we must flag it as "revealed"
    final isBoss = _random.nextInt(word.length);

    _problem = SerializableLetterProblem(
      letters: word.split(''),
      scrambleIndices: List.generate(word.length, (index) => index),
      uselessLetterStatuses: List.generate(
        word.length,
        (i) => i == isBoss ? LetterStatus.revealed : LetterStatus.normal,
      ),
      hiddenLetterStatuses: List.generate(
        word.length,
        (_) => LetterStatus.hidden,
      ),
    );
  }

  @override
  SerializableBlueberryWarGameState serializeMiniGame() =>
      SerializableBlueberryWarGameState(
        roundTimer: roundTimer,
        allAgents: allAgents,
        problem: _problem!,
      );

  ///
  /// The game loop
  @override
  Future<void> onRoundClockTicked(
      Duration deltaTime, ControllableTimerStatus status) async {
    switch (status) {
      case ControllableTimerStatus.notInitialized:
      case ControllableTimerStatus.initialized:
        break;
      case ControllableTimerStatus.paused:
      case ControllableTimerStatus.inProgress:
      case ControllableTimerStatus.ended:
        await _processRound(deltaTime);
        break;
    }
  }

  @override
  void onRoundStatusChanged(ControllableTimerStatus newStatus) {
    if (newStatus == ControllableTimerStatus.ended) _processRoundIsEnding();

    super.onRoundStatusChanged(newStatus);
  }

  Future<void> _processRound(Duration deltaTime) async {
    // Check if the game is over
    bool shouldCallUpdate = false;
    BlueberryWarGameManagerHelpers.updateAllAgents(
      dt: deltaTime,
      allAgents: allAgents,
      problem: _problem!,
      onBlueberryDestroyed: (blueberry) {
        onBlueberryDestroyed
            .notifyListeners((callback) => callback(blueberry.id));
        shouldCallUpdate = true;
      },
      onLetterHitByBlueberry: (letter) {
        onLetterHitByBlueberry.notifyListeners(
          (callback) => callback(letter.problemIndex, letter.isDestroyed),
        );
        shouldCallUpdate = true;
      },
      onLetterHitByLetter: (first, second) {
        onLetterHitByLetter.notifyListeners(
          (callback) => callback(first.problemIndex, second.problemIndex,
              first.isBoss, second.isBoss),
        );
      },
    );
    BlueberryWarGameManagerHelpers.checkForBlueberriesTeleportation(
      allAgents: allAgents,
      onBlueberryTeleported: (blueberry) => shouldCallUpdate = true,
    );
    if (shouldCallUpdate) {
      // Notify listeners that the game has been updated with more than just
      // movement and collisions
      onGameUpdated.notifyListeners((callback) => callback());
    }
  }

  @override
  Future<bool> shouldEndRoundImmediately() async {
    return hasWon;
  }

  Future<void> _processRoundIsEnding() async {
    // Make all the agents quickly slowing down
    for (final agent in allAgents) {
      agent.coefficientOfFriction = 0.9;
    }

    // Reveal the problem
    for (int i = 0; i < _problem!.hiddenLetterStatuses.length; i++) {
      if (problem.hiddenLetterStatuses[i] == LetterStatus.hidden) {
        problem.hiddenLetterStatuses[i] = LetterStatus.revealed;
      }
      onLetterHitByBlueberry.notifyListeners((callback) => callback(i, true));
    }
  }
}
