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
  void onRoundIsPreparing(VoidCallback callback) =>
      _onRoundIsPreparing.add(callback);
  void removeOnRoundIsPreparing(VoidCallback callback) =>
      _onRoundIsPreparing.removeWhere((e) => e == callback);

  ///
  /// Callbacks for that tells listeners that the round is ready to start
  void onRoundIsReady(VoidCallback callback) => _onRoundIsReady.add(callback);
  void removeOnRoundIsReady(VoidCallback callback) =>
      _onRoundIsReady.removeWhere((e) => e == callback);

  ///
  /// Callbacks for that tells listeners that the game timer has ticked
  void onTimerTicks(VoidCallback callback) => _onTimerTicks.add(callback);
  void removeOnTimerTicks(VoidCallback callback) =>
      _onTimerTicks.removeWhere((e) => e == callback);

  ///
  /// Callbacks for that tells listeners that a solution has been found
  void onSolutionFound(VoidCallback callback) => _onSolutionFound.add(callback);
  void removeOnSolutionFound(VoidCallback callback) =>
      _onSolutionFound.removeWhere((e) => e == callback);

  ///
  /// Callbacks for that tells listeners that the round is over
  void onRoundIsOver(VoidCallback callback) => _onRoundIsOver.add(callback);
  void removeOnRoundIsOver(VoidCallback callback) =>
      _onRoundIsOver.removeWhere((e) => e == callback);

  /// -------- ///
  /// INTERNAL ///
  /// -------- ///

  ///
  /// Declare the singleton
  static final GameManager _instance = GameManager._internal();
  GameManager._internal();

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
    _callOnRoundIsPreparing();

    _currentProblem = null;
    _currentProblem = await WordProblem.generateFromRandom();

    _gameTimer = roundDuration.inSeconds;
    Timer.periodic(const Duration(seconds: 1), _timerTick);

    _gameStatus = GameStatus.roundStarted;
    _callOnRoundIsReady();
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

    if (problem!.trySolution(sender, message)) _callOnSolutionFound();
  }

  ///
  /// Tick the game timer. If the timer is over, [_roundIsOver] is called.
  void _timerTick(Timer timer) {
    _gameTimer = _gameTimer! - 1;
    _callOnTimerTicks();
    if (_gameTimer! < 1 || _gameStatus == GameStatus.requestFinishRound) {
      timer.cancel();
      _roundIsOver();
    }
  }

  ///
  /// Clear the current round
  void _roundIsOver() {
    _gameTimer = null;
    _gameStatus = GameStatus.roundOver;
    _callOnRoundIsOver();
  }

  ///
  /// Callbacks management (see API for description)
  final List<VoidCallback> _onRoundIsPreparing = [];
  void _callOnRoundIsPreparing() {
    for (final callback in _onRoundIsPreparing) {
      callback();
    }
  }

  final List<VoidCallback> _onRoundIsReady = [];
  void _callOnRoundIsReady() {
    for (final callback in _onRoundIsReady) {
      callback();
    }
  }

  final List<VoidCallback> _onTimerTicks = [];
  void _callOnTimerTicks() {
    for (final callback in _onTimerTicks) {
      callback();
    }
  }

  final List<VoidCallback> _onSolutionFound = [];
  void _callOnSolutionFound() {
    for (final callback in _onSolutionFound) {
      callback();
    }
  }

  final List<VoidCallback> _onRoundIsOver = [];
  void _callOnRoundIsOver() {
    for (final callback in _onRoundIsOver) {
      callback();
    }
  }
}
