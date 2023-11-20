import 'package:flutter/material.dart';
import 'package:train_de_mots/models/player.dart';
import 'package:train_de_mots/models/twitch_interface.dart';
import 'package:train_de_mots/models/word_problem.dart';

class GameManager {
  final Players players = Players();

  final Duration roundDuration = const Duration(minutes: 3);
  final Duration cooldownPeriod = const Duration(seconds: 5);

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

    // TODO Start timer

    _callOnRoundIsReady();
  }

  Future<void> _trySolution(String sender, String message) async {
    if (problem == null) return;

    if (problem!.trySolution(sender, message)) {
      _callOnSolutionFound();
    }
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

  final List<VoidCallback> _onSolutionFound = [];
  void onSolutionFound(VoidCallback callback) => _onSolutionFound.add(callback);
  void removeOnSolutionFound(VoidCallback callback) =>
      _onSolutionFound.removeWhere((e) => e == callback);
  void _callOnSolutionFound() {
    for (final callback in _onSolutionFound) {
      callback();
    }
  }
}
