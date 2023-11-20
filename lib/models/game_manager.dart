import 'dart:async';

import 'package:flutter/material.dart';
import 'package:train_de_mots/models/player.dart';
import 'package:train_de_mots/models/twitch_interface.dart';
import 'package:train_de_mots/models/word_problem.dart';

class GameManager {
  final Players players = Players();
  int? _gameTimer;
  int? get gameTimer => _gameTimer;

  final Duration roundDuration = const Duration(minutes: 3);
  final Duration cooldownPeriod = const Duration(seconds: 15);

  final int nbLetterInSmallestWord = 5;
  final int minimumWordLetter = 6;
  final int maximumWordLetter = 8;
  final int minimumWordsNumber = 20;
  final int maximumWordsNumber = 30;

  // Declare the singleton
  static final GameManager _instance = GameManager._internal();
  GameManager._internal();
  static GameManager get instance => _instance;

  // Initialize the game logic
  Future<void> initialize() async {
    await WordProblem.initialize();
  }

  bool _isGetAnswerInitialized = false;
  Future<void> initializeGetAnswersCallback() async => TwitchInterface.instance
      .addChatListener((sender, message) => _trySolution(sender, message));

  /// Game logic
  bool get hasAnActiveRound => _currentProblem != null;
  bool get hasNotAnActiveRound => !hasAnActiveRound;
  WordProblem? _currentProblem;
  WordProblem? get problem => _currentProblem;

  Future<void> nextRound() async {
    if (!_isGetAnswerInitialized) {
      initializeGetAnswersCallback();
      _isGetAnswerInitialized = true;
    }

    _currentProblem = null;
    _currentProblem = await WordProblem.generateFromRandom();

    _gameTimer = roundDuration.inSeconds;
    Timer.periodic(const Duration(seconds: 1), _timerTick);

    _callOnRoundIsReady();
  }

  Future<void> _trySolution(String sender, String message) async {
    if (problem == null || gameTimer == null) return;

    if (problem!.trySolution(sender, message)) _callOnSolutionFound();
  }

  void _timerTick(Timer timer) {
    _callOnTimerTicks();
    _gameTimer = _gameTimer! - 1;
    if (_gameTimer! < 1) {
      timer.cancel();
      _roundIsOver();
    }
  }

  void _roundIsOver() {
    _gameTimer = null;
    _callOnRoundIsOver();
  }

  /// All the callbacks
  final List<VoidCallback> _onRoundIsReady = [];
  void onRoundIsReady(VoidCallback callback) => _onRoundIsReady.add(callback);
  void removeOnRoundIsReady(VoidCallback callback) =>
      _onRoundIsReady.removeWhere((e) => e == callback);
  void _callOnRoundIsReady() {
    for (final callback in _onRoundIsReady) {
      callback();
    }
  }

  final List<VoidCallback> _onTimerTicks = [];
  void onTimerTicks(VoidCallback callback) => _onTimerTicks.add(callback);
  void removeOnTimerTicks(VoidCallback callback) =>
      _onTimerTicks.removeWhere((e) => e == callback);
  void _callOnTimerTicks() {
    for (final callback in _onTimerTicks) {
      callback();
    }
  }

  final List<VoidCallback> _onSolutionFound = [];
  void onSolutionFound(VoidCallback callback) => _onSolutionFound.add(callback);
  void removeOnSolutionFound(VoidCallback callback) =>
      _onSolutionFound.removeWhere((e) => e == callback);
  void _callOnSolutionFound() {
    for (final callback in _onSolutionFound) {
      callback();
    }
  }

  final List<VoidCallback> _onRoundIsOver = [];
  void onRoundIsOver(VoidCallback callback) => _onRoundIsOver.add(callback);
  void removeOnRoundIsOver(VoidCallback callback) =>
      _onRoundIsOver.removeWhere((e) => e == callback);
  void _callOnRoundIsOver() {
    for (final callback in _onRoundIsOver) {
      callback();
    }
  }
}
