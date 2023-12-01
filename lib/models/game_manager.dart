import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:train_de_mots/models/custom_callback.dart';
import 'package:train_de_mots/models/game_configuration.dart';
import 'package:train_de_mots/models/player.dart';
import 'package:train_de_mots/models/solution.dart';
import 'package:train_de_mots/models/twitch_interface.dart';
import 'package:train_de_mots/models/word_problem.dart';

enum GameStatus {
  uninitialized,
  initializing,
  preparingProblem,
  roundStarted,
  requestFinishRound,
  roundOver,
}

// Declare the GameManager provider
final gameManagerProvider = Provider<_GameManager>((ref) {
  return _GameManager.instance;
});

class _GameManager {
  /// ---------- ///
  /// GAME LOGIC ///
  /// ---------- ///

  final Players players = Players();

  GameStatus _gameStatus = GameStatus.uninitialized;
  GameStatus get gameStatus => _gameStatus;
  int? _gameTimer;
  int? get gameTimer => _gameTimer;

  bool get isPreparingProblem => _gameStatus == GameStatus.preparingProblem;
  bool get hasAnActiveRound => _gameStatus == GameStatus.roundStarted;
  bool get hasNotAnActiveRound => !hasAnActiveRound;

  WordProblem? _currentProblem;
  WordProblem? _nextProblem;
  bool _isSearchingForProblem = false;
  bool get isSearchingForProblem => _isSearchingForProblem;
  bool get isNextProblemReady => _nextProblem != null;
  WordProblem? get problem => _currentProblem;

  /// ----------- ///
  /// CONSTRUCTOR ///
  /// ----------- ///

  ///
  /// Initialize the game logic. This should be called at the start of the
  /// application.
  Future<void> initialize() async {
    Timer.periodic(const Duration(seconds: 1), _gameLoop);
    await _initializeWordProblem();
  }

  Future<void> _initializeWordProblem() async {
    final configuration = ProviderContainer().read(gameConfigurationProvider);

    await WordProblem.initialize(
        nbLetterInSmallestWord: configuration.nbLetterInSmallestWord);
    _isSearchingForProblem = false;
    _nextProblem = null;
    await _searchForProblem();
  }

  /// ----------- ///
  /// INTERACTION ///
  /// ----------- ///

  ///
  /// Provide a way to request the start of a new round, if the game is not
  /// already started or if the game is not already over.
  Future<void> requestStartNewRound() async => await _startNewRound();

  ///
  /// Provide a way to request the premature end of the round
  Future<void> requestTerminateRound() async {
    if (_gameStatus != GameStatus.roundStarted) return;
    _gameStatus = GameStatus.requestFinishRound;
  }

  /// --------- ///
  /// CALLBACKS ///
  /// When registering to a callback, one should remind themselves to
  /// unregister when the widget is disposed, otherwise it will leak memory.
  /// --------- ///

  /// Callbacks for that tells listeners that the round is preparing
  final onGameIsInitializing = CustomCallback<VoidCallback>();
  final onRoundIsPreparing = CustomCallback<VoidCallback>();
  final onNextProblemReady = CustomCallback<VoidCallback>();
  final onRoundStarted = CustomCallback<VoidCallback>();
  final onRoundIsOver = CustomCallback<VoidCallback>();
  final onTimerTicks = CustomCallback<VoidCallback>();
  final onScrablingLetters = CustomCallback<VoidCallback>();
  final onSolutionFound = CustomCallback<Function(Solution)>();
  final onPlayerUpdate = CustomCallback<VoidCallback>();

  /// -------- ///
  /// INTERNAL ///
  /// -------- ///

  ///
  /// Declare the singleton
  static _GameManager get instance => _instance;
  static final _GameManager _instance = _GameManager._internal();
  _GameManager._internal();

  ///
  /// This is a method to tell the game manager that the rules have changed and
  /// some things may need to be updated
  /// [shoulRepickProblem] is used to tell the game manager that the problem
  /// picker rules have changed and that it should repick a problem.
  /// [repickNow] is used to tell the game manager that it should repick a
  /// problem now or wait a future call. That is to wait until all the changes
  /// to the rules are made before repicking a problem.
  void rulesHasChanged({
    bool shoulRepickProblem = false,
    bool repickNow = false,
  }) {
    if (shoulRepickProblem) _forceRepickProblem = true;
    if (repickNow && shoulRepickProblem) _initializeWordProblem();
  }

  ///
  /// As soon as anything changes, we need to notify the listeners of players.
  /// Otherwise, the UI would be spammed with updates.
  bool _forceRepickProblem = false;
  bool _hasAPlayerBeenUpdate = false;

  Future<void> _searchForProblem() async {
    if (_isSearchingForProblem) return;
    if (_nextProblem != null && !_forceRepickProblem) return;
    _forceRepickProblem = false;

    final configuration = ProviderContainer().read(gameConfigurationProvider);
    _isSearchingForProblem = true;
    _nextProblem = await configuration.problemGenerator(
      nbLetterInSmallestWord: configuration.nbLetterInSmallestWord,
      minLetters: configuration.minimumWordLetter,
      maxLetters: configuration.maximumWordLetter,
      minimumNbOfWords: configuration.minimumWordsNumber,
      maximumNbOfWords: configuration.maximumWordsNumber,
    );
    _nextProblem!.cooldownScrambleTimer =
        configuration.timeBeforeScramblingLetters.inSeconds;

    _isSearchingForProblem = false;
    onNextProblemReady.notifyListeners();
  }

  ///
  /// Prepare the game for a new round by making sure everything is initialized.
  /// Then, it finds a new word problem and start the timer.
  Future<void> _startNewRound() async {
    if (_gameStatus != GameStatus.uninitialized &&
        _gameStatus != GameStatus.roundOver &&
        !isNextProblemReady) {
      return;
    }

    if (_gameStatus == GameStatus.uninitialized) {
      _gameStatus = GameStatus.initializing;
      onGameIsInitializing.notifyListeners();
      _initializeTrySolutionCallback();
    }
    _gameStatus = GameStatus.preparingProblem;
    onRoundIsPreparing.notifyListeners();

    _searchForProblem(); // It is already searching, but make sure
    while (_isSearchingForProblem) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    _currentProblem = _nextProblem;
    _nextProblem = null;

    _gameTimer = ProviderContainer()
        .read(gameConfigurationProvider)
        .roundDuration
        .inSeconds;
    for (final player in players) {
      player.resetForNextRound();
    }

    _gameStatus = GameStatus.roundStarted;
    onRoundStarted.notifyListeners();
  }

  ///
  /// Initialize the callbacks from Twitch chat to [_trySolution]
  Future<void> _initializeTrySolutionCallback() async =>
      TwitchInterface.instance
          .addChatListener((sender, message) => _trySolution(sender, message));

  ///
  /// Try to solve the problem from a [message] sent by a [sender], that is a
  /// Twitch chatter.
  Future<void> _trySolution(String sender, String message) async {
    if (problem == null || gameTimer == null) return;
    final configuration = ProviderContainer().read(gameConfigurationProvider);

    // Get the player from the players list
    final player = players.firstWhereOrAdd(sender);

    // If the player is in cooldown, they are not allowed to answer
    if (player.isInCooldownPeriod) return;

    // Find if the proposed word is valid
    final solution = problem!.trySolution(message,
        nbLetterInSmallestWord: configuration.nbLetterInSmallestWord);
    if (solution == null) return;

    // Add to player score
    int cooldownTimer = configuration.cooldownPeriod.inSeconds;
    if (solution.isFound) {
      // If the solution was already found, the player can steal it. It however
      // provides half the score and doubles the cooldown period.

      // The player cannot steal if the game is not configured to allow it
      if (!configuration.canSteal) return;

      // The player cannot steal from themselves
      if (solution.foundBy == player) return;

      // The player is only allowed to steal once per round
      if (player.isStealer) return;

      // First remove the score from the previous finder
      cooldownTimer = configuration.cooldownPeriodAfterSteal.inSeconds;
      solution.foundBy!.score -= solution.value;

      // Mark the solution as stolen and player as stealer and proceed as usual
      solution.wasStolen = true;
      player.isStealer = true;
    }
    solution.foundBy = player;
    player.score += solution.value;
    player.cooldownTimer = cooldownTimer;

    // Call the listeners of solution found
    onSolutionFound.notifyListenersWithParameter(solution);

    // Also plan for an call to the listeners of players on next game loop
    _hasAPlayerBeenUpdate = true;
  }

  ///
  /// Tick the game timer. If the timer is over, [_roundIsOver] is called.
  void _gameLoop(Timer timer) {
    if (_gameStatus == GameStatus.uninitialized) return;

    _gameTick();
    _checkEndOfRound();
  }

  ///
  /// Tick the game timer and the cooldown timer of players. Call the
  /// listeners if needed.
  void _gameTick() {
    if (_gameStatus != GameStatus.roundStarted) return;
    final configuration = ProviderContainer().read(gameConfigurationProvider);

    _gameTimer = _gameTimer! - 1;

    // Manager players cooling down
    for (final player in players) {
      if (player.isInCooldownPeriod) {
        player.cooldownTimer -= 1;
        _hasAPlayerBeenUpdate = true;
      }
    }
    if (_hasAPlayerBeenUpdate) {
      onPlayerUpdate.notifyListeners();
      _hasAPlayerBeenUpdate = false;
    }

    // Manager letter swapping in the problem
    _currentProblem!.cooldownScrambleTimer -= 1;
    if (_currentProblem!.cooldownScrambleTimer <= 0) {
      _currentProblem!.cooldownScrambleTimer =
          configuration.timeBeforeScramblingLetters.inSeconds;
      _currentProblem!.scrambleLetters();
      onScrablingLetters.notifyListeners();
    }

    onTimerTicks.notifyListeners();
  }

  ///
  /// Clear the current round
  void _checkEndOfRound() {
    // End round no matter what if the request was made
    if (_gameStatus != GameStatus.requestFinishRound) {
      // Do not end round if we are not playing
      if (_gameStatus != GameStatus.roundStarted || _gameTimer! > 0) return;
    }

    _gameTimer = null;
    _gameStatus = GameStatus.roundOver;
    onRoundIsOver.notifyListeners();

    _searchForProblem();
  }
}
