import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
final gameManagerProvider = ChangeNotifierProvider<_GameManager>((ref) {
  return _GameManager.instance;
});

class _GameManager with ChangeNotifier {
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
  bool get isNextProblemReady => _nextProblem != null;
  WordProblem? get problem => _currentProblem;

  ///
  /// Game configuration

  void finalizeConfigurationChanges() {
    // If [_forceRedraw] was set to true, it means we should redraw a problem
    _searchForProblem();
  }

  final _canSteal = true;
  bool get canSteal => _canSteal;
  final Future<WordProblem> Function({
    required int nbLetterInSmallestWord,
    required int minLetters,
    required int maxLetters,
    required int minimumNbOfWords,
    required int maximumNbOfWords,
  }) _problemGenerator = WordProblem.generateFromRandom;

  Duration _roundDuration = const Duration(minutes: 3);
  Duration get roundDuration => _roundDuration;
  set roundDuration(Duration value) {
    _roundDuration = value;
    _saveConfiguration();
  }

  bool get canChangeRoundDuration => !hasAnActiveRound;

  final Duration cooldownPeriod = const Duration(seconds: 15);

  int _nbLetterInSmallestWord = 5;
  int get nbLetterInSmallestWord => _nbLetterInSmallestWord;
  set nbLetterInSmallestWord(int value) {
    if (_nbLetterInSmallestWord == value) return;
    _nbLetterInSmallestWord = value;
    _forceRedraw = true;
    _saveConfiguration();
  }

  bool get canChangeNbLetterInSmallestWord =>
      !_isSearchingForProblem && !hasAnActiveRound;

  final int minimumWordLetter = 6;
  final int maximumWordLetter = 8;
  final int minimumWordsNumber = 15;
  final int maximumWordsNumber = 25;

  Map<String, dynamic> serializeConfiguration() {
    return {
      'nbLetterInSmallestWord': nbLetterInSmallestWord,
      'roundDuration': roundDuration.inSeconds,
    };
  }

  void _saveConfiguration() async {
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    prefs.setString('gameConfiguration', jsonEncode(serializeConfiguration()));
  }

  void _loadConfiguration() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('gameConfiguration');
    if (data != null) {
      final map = jsonDecode(data);
      _nbLetterInSmallestWord = map['nbLetterInSmallestWord'] ?? 5;
      _roundDuration = Duration(seconds: map['roundDuration'] ?? 180);

      _forceRedraw = true;
      _initializeWordProblem();
    }
    notifyListeners();
  }

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
    await WordProblem.initialize(
        nbLetterInSmallestWord: nbLetterInSmallestWord);
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
  static _GameManager get instance => _instance;
  static final _GameManager _instance = _GameManager._internal();
  _GameManager._internal() {
    _loadConfiguration();
  }

  ///
  /// As soon as anything changes, we need to notify the listeners of players.
  /// Otherwise, the UI would be spammed with updates.
  bool _forceRedraw = false;
  bool _hasAPlayerUpdate = false;

  Future<void> _searchForProblem() async {
    if (_isSearchingForProblem) return;
    if (_nextProblem != null && !_forceRedraw) return;
    _forceRedraw = false;

    _isSearchingForProblem = true;
    _nextProblem = await _problemGenerator(
      nbLetterInSmallestWord: nbLetterInSmallestWord,
      minLetters: minimumWordLetter,
      maxLetters: maximumWordLetter,
      minimumNbOfWords: minimumWordsNumber,
      maximumNbOfWords: maximumWordsNumber,
    );
    _isSearchingForProblem = false;
    onNextProblemReady._notifyListeners();
    notifyListeners();
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
    final player = players.firstWhereOrAdd(sender);

    // If the player is in cooldown, they are not allowed to answer
    if (player.isInCooldownPeriod) return;

    // Find if the proposed word is valid
    final solution = problem!
        .trySolution(message, nbLetterInSmallestWord: nbLetterInSmallestWord);
    if (solution == null) return;

    // Add to player score
    int cooldownTimer = cooldownPeriod.inSeconds;
    if (solution.isFound) {
      // If the solution was already found, the player can steal it. It however
      // provides half the score and doubles the cooldown period.

      // The player cannot steal if the game is not configured to allow it
      if (!canSteal) return;

      // The player cannot steal from themselves
      if (solution.foundBy == player) return;

      // The player is only allowed to steal once per round
      if (player.isStealer) return;

      // First remove the score from the previous finder
      cooldownTimer *= 2;
      solution.foundBy!.score -= solution.value;

      // Mark the solution as stolen and player as stealer and proceed as usual
      solution.wasStolen = true;
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
