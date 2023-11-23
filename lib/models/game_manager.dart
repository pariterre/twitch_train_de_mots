import 'dart:async';

import 'package:flutter/material.dart';
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

class GameManager {
  /// ---------- ///
  /// GAME LOGIC ///
  /// ---------- ///

  final Players players = Players();

  GameStatus _gameStatus = GameStatus.uninitialized;
  GameStatus get gameStatus => _gameStatus;
  int? _gameTimer;
  int? get gameTimer => _gameTimer;

  bool get hasAnActiveRound => _currentProblem != null;
  bool get hasNotAnActiveRound => !hasAnActiveRound;

  WordProblem? _currentProblem;
  WordProblem? _nextProblem;
  bool _isSearchingForProblem = false;
  bool get isNextProblemReady => _nextProblem != null;
  WordProblem? get problem => _currentProblem;

  final Duration roundDuration = const Duration(minutes: 3);
  final Duration cooldownPeriod = const Duration(seconds: 15);

  ///
  /// Game configuration
  ///

  final int nbLetterInSmallestWord = 5;
  final int minimumWordLetter = 6;
  final int maximumWordLetter = 8;
  final int minimumWordsNumber = 20;
  final int maximumWordsNumber = 30;

  /// ----------- ///
  /// CONSTRUCTOR ///
  /// ----------- ///

  ///
  /// Initialize the game logic. This should be called at the start of the
  /// application.
  Future<void> initialize() async {
    await WordProblem.initialize();
    Timer.periodic(const Duration(seconds: 1), _gameLoop);
    _searchForProblem();
  }

  ///
  /// Provide a way to get the singleton
  static GameManager get instance => _instance;

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
  final onRoundIsPreparing = GameCallback<VoidCallback>();
  final onNextProblemReady = GameCallback<VoidCallback>();
  final onRoundStarted = GameCallback<VoidCallback>();
  final onRoundIsOver = GameCallback<VoidCallback>();
  final onTimerTicks = GameCallback<VoidCallback>();
  final onSolutionFound = GameCallback<Function(Solution)>();
  final onPlayerUpdate = GameCallback<VoidCallback>();

  /// -------- ///
  /// INTERNAL ///
  /// -------- ///

  ///
  /// Declare the singleton
  static final GameManager _instance = GameManager._internal();
  GameManager._internal();

  ///
  /// As soon as anything changes, we need to notify the listeners of players.
  /// Otherwise, the UI would be spammed with updates.
  bool _hasAPlayerUpdate = false;

  Future<void> _searchForProblem() async {
    if (_isSearchingForProblem || _nextProblem != null) return;

    _isSearchingForProblem = true;
    _nextProblem = await WordProblem.generateFromRandom();
    _isSearchingForProblem = false;
    onNextProblemReady._notifyListeners();
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
      _initializeTrySolutionCallback();
    }
    _gameStatus = GameStatus.preparingProblem;
    onRoundIsPreparing._notifyListeners();

    _searchForProblem(); // It is already searching, but make sure
    while (_isSearchingForProblem) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    _currentProblem = _nextProblem;
    _nextProblem = null;

    _gameTimer = roundDuration.inSeconds;
    for (final player in players) {
      player.resetForNextRound();
    }

    _gameStatus = GameStatus.roundStarted;
    onRoundStarted._notifyListeners();
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

    // Get the player from the players list
    final player = GameManager.instance.players.firstWhereOrAdd(sender);

    // If the player is in cooldown, they are not allowed to answer
    if (player.isInCooldownPeriod) return;

    // Find if the proposed word is valid
    final solution = problem!.trySolution(message);
    if (solution == null) return;

    // Add to player score
    int cooldownTimer = cooldownPeriod.inSeconds;
    if (solution.isFound) {
      // If the solution was already found, the player can steal it. It however
      // provides half the score and doubles the cooldown period.

      // Also, the player is only allowed to steal once per round
      if (player.isStealer) return;

      // First remove the score from the previous finder
      cooldownTimer *= 2;
      solution.foundBy!.score -= solution.value;

      // Mark the solution as stolen and player as stealer and proceed as usual
      solution.wasStealed = true;
      player.isStealer = true;
    }
    solution.foundBy = player;
    player.score += solution.value;
    player.cooldownTimer = cooldownTimer;

    // Call the listeners of solution found
    onSolutionFound._notifyListenersWithParameter(solution);

    // Also plan for an call to the listeners of players on next game loop
    _hasAPlayerUpdate = true;
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

    _gameTimer = _gameTimer! - 1;

    for (final player in players) {
      if (player.isInCooldownPeriod) {
        player.cooldownTimer = player.cooldownTimer - 1;
        _hasAPlayerUpdate = true;
      }
    }
    if (_hasAPlayerUpdate) {
      onPlayerUpdate._notifyListeners();
      _hasAPlayerUpdate = false;
    }

    onTimerTicks._notifyListeners();
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
    onRoundIsOver._notifyListeners();

    _searchForProblem();
  }
}

class GameCallback<T extends Function> {
  final List<T> _listeners = [];

  void addListener(T callback) => _listeners.add(callback);

  void removeListener(T callback) =>
      _listeners.removeWhere((e) => e == callback);

  void _notifyListeners() {
    for (final callback in _listeners) {
      callback();
    }
  }

  void _notifyListenersWithParameter(parameter) {
    for (final callback in _listeners) {
      callback(parameter);
    }
  }
}
