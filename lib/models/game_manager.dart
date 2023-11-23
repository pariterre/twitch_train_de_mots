import 'dart:async';

import 'package:flutter/material.dart';
import 'package:train_de_mots/models/player.dart';
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
  final onRoundIsPreparing = GameCallback();
  final onRoundIsReady = GameCallback();
  final onRoundIsOver = GameCallback();
  final onTimerTicks = GameCallback();
  final onSolutionFound = GameCallback();
  final onPlayerUpdate = GameCallback();

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

  ///
  /// Prepare the game for a new round by making sure everything is initialized.
  /// Then, it finds a new word problem and start the timer.
  Future<void> _startNewRound() async {
    if (_gameStatus != GameStatus.uninitialized &&
        _gameStatus != GameStatus.roundOver) {
      return;
    }

    if (_gameStatus == GameStatus.uninitialized) {
      _gameStatus = GameStatus.initializing;
      _initializeTrySolutionCallback();
    }
    _gameStatus = GameStatus.preparingProblem;
    onRoundIsPreparing._notifyListeners();

    _currentProblem = null;
    _currentProblem = await WordProblem.generateFromRandom();

    _gameTimer = roundDuration.inSeconds;

    _gameStatus = GameStatus.roundStarted;
    onRoundIsReady._notifyListeners();
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
    onSolutionFound._notifyListeners();

    // Also plan for an call to the listeners of players on next game loop
    _hasAPlayerUpdate = true;
  }

  ///
  /// Tick the game timer. If the timer is over, [_roundIsOver] is called.
  void _gameLoop(Timer timer) {
    if (_gameStatus == GameStatus.roundStarted) {
      _gameTick();
    }
  }

  void _gameTick() {
    _gameTimer = _gameTimer! - 1;
    if (_gameTimer! < 1 || _gameStatus == GameStatus.requestFinishRound) {
      _roundIsOver();
      return;
    }

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
  void _roundIsOver() {
    _gameTimer = null;
    _gameStatus = GameStatus.roundOver;
    onRoundIsOver._notifyListeners();
  }
}

class GameCallback {
  final List<VoidCallback> _listeners = [];

  void addListener(VoidCallback callback) => _listeners.add(callback);

  void removeListener(VoidCallback callback) =>
      _listeners.removeWhere((e) => e == callback);

  void _notifyListeners() {
    for (final callback in _listeners) {
      callback();
    }
  }
}
