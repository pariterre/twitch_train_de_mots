import 'dart:async';

import 'package:flutter/material.dart';
import 'package:train_de_mots/managers/configuration_manager.dart';
import 'package:train_de_mots/managers/database_manager.dart';
import 'package:train_de_mots/managers/twitch_manager.dart';
import 'package:train_de_mots/models/custom_callback.dart';
import 'package:train_de_mots/models/exceptions.dart';
import 'package:train_de_mots/models/letter_problem.dart';
import 'package:train_de_mots/models/player.dart';
import 'package:train_de_mots/models/round_success.dart';
import 'package:train_de_mots/models/success_level.dart';
import 'package:train_de_mots/models/word_solution.dart';

enum GameStatus {
  initializing,
  roundPreparing,
  roundReady,
  roundStarted,
  revealAnswers,
}

class GameManager {
  /// ---------- ///
  /// GAME LOGIC ///
  /// ---------- ///

  final Players players = Players();

  GameStatus _gameStatus = GameStatus.initializing;
  GameStatus get gameStatus => _gameStatus;

  int? _roundDuration;
  int? get timeRemaining => _roundDuration == null || _roundStartedSince == null
      ? null
      : ((_roundDuration! ~/ 1000 - _roundStartedSince!)) -
          ConfigurationManager.instance.postRoundGracePeriodDuration.inSeconds;
  int? get _roundStartedSince => _roundStartedAt == null
      ? null
      : (DateTime.now().millisecondsSinceEpoch -
              _roundStartedAt!.millisecondsSinceEpoch) ~/
          1000;
  DateTime? _roundStartedAt;
  DateTime? _nextRoundStartAt;
  Duration? get nextRoundStartIn =>
      _nextRoundStartAt?.difference(DateTime.now());
  void cancelAutomaticStart() => _nextRoundStartAt = null;
  DateTime? _nextTickAt;
  int _roundCount = 0;
  int get roundCount => _roundCount;

  int _scramblingLetterTimer = 0;

  LetterProblem? _currentProblem;
  final List<LetterProblem?> _nextProblems = [];
  final List<LetterProblem> _previousProblems = [];

  /// [isNextProblemReady] assumes [_successLevel] to be max while playing, so
  /// it ensures to search for all possible next problems.
  bool get isNextProblemReady => _nextProblems.length > _successLevel.toInt();

  bool _isSearchingNextProblem = false;
  LetterProblem? get problem => _currentProblem;
  SuccessLevel _successLevel = SuccessLevel.threeStars;
  final List<RoundSuccess> _roundSuccesses = [];
  List<RoundSuccess> get roundSuccesses => _roundSuccesses;

  bool _hasPlayedAtLeastOnce = false;
  bool get hasPlayedAtLeastOnce => _hasPlayedAtLeastOnce;
  bool _forceEndTheRound = false;
  late bool _isAllowedToSendResults =
      !ConfigurationManager.instance.useCustomAdvancedOptions;
  bool get isAllowedToSendResults => _isAllowedToSendResults;

  WordSolution? _lastStolenSolution;
  int _remainingPardons = 0;
  int get remainingPardon => _remainingPardons;

  int _remainingBoosts = 0;
  int get remainingBoosts => _remainingBoosts;
  bool get isTrainBoosted => _boostStartedAt != null;
  Duration? get trainBoostRemainingTime => _boostStartedAt
      ?.add(ConfigurationManager.instance.boostTime)
      .difference(DateTime.now());
  DateTime? _boostStartedAt;
  final List<Player> _requestedBoost = [];

  /// ----------- ///
  /// CONSTRUCTOR ///
  /// ----------- ///

  ///
  /// Initialize the game logic. This should be called at the start of the
  /// application.
  static Future<void> initialize() async {
    if (_instance != null) {
      throw ManagerAlreadyInitializedException(
          'GameManager should not be initialized twice');
    }
    GameManager._instance = GameManager._internal();

    Timer.periodic(const Duration(milliseconds: 100), instance._gameLoop);
  }

  /// ----------- ///
  /// INTERACTION ///
  /// ----------- ///

  ///
  /// Provide a way to request the start of a new round, if the game is not
  /// already started or if the game is not already over.
  Future<void> requestStartNewRound() async => await _startNewRound();

  ///
  /// Provide a way to request the search for the next problem, if the game is
  /// not already searching for a problem.
  Future<void> requestSearchForNextProblem() async =>
      await _searchProblemForRound(
          round: _roundCount, maxSearchingTime: Duration.zero);

  ///
  /// Provide a way to request the premature end of the round
  Future<void> requestTerminateRound() async {
    if (gameStatus == GameStatus.initializing) {
      _initializeCallbacks();
      _gameStatus = GameStatus.roundPreparing;
    }
    if (_gameStatus != GameStatus.roundStarted) return;
    _forceEndTheRound = true;
  }

  final List<String> _messagesToPlayers = [];
  SuccessLevel get successLevel => _successLevel;

  bool get hasUselessLetter =>
      ConfigurationManager.instance.difficulty(_roundCount).hasUselessLetter;
  bool _isUselessLetterRevealed = false;
  bool get isUselessLetterRevealed => _isUselessLetterRevealed;
  int get uselessLetterIndex => _currentProblem?.uselessLetterIndex ?? -1;

  bool get hasHiddenLetter =>
      ConfigurationManager.instance.difficulty(_roundCount).hasHiddenLetter &&
      !_isHiddenLetterRevealed;
  bool _isHiddenLetterRevealed = false;
  int get hiddenLetterIndex => _currentProblem?.hiddenLettersIndex ?? -1;

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
  final onRoundIsOver = CustomCallback<Function(bool)>();
  final onTimerTicks = CustomCallback<VoidCallback>();
  final onScrablingLetters = CustomCallback<VoidCallback>();
  final onRevealUselessLetter = CustomCallback<VoidCallback>();
  final onRevealHiddenLetter = CustomCallback<VoidCallback>();
  final onSolutionFound = CustomCallback<Function(WordSolution)>();
  final onSolutionWasStolen = CustomCallback<Function(WordSolution)>();
  final onStealerPardonned = CustomCallback<Function(WordSolution)>();
  final onTrainGotBoosted = CustomCallback<Function(int)>();
  final onAllSolutionsFound = CustomCallback<VoidCallback>();
  final onPlayerUpdate = CustomCallback<VoidCallback>();
  Future<void> Function(String)? onShowMessage;

  /// -------- ///
  /// INTERNAL ///
  /// -------- ///

  ///
  /// Declare the singleton
  static GameManager get instance {
    if (_instance == null) {
      throw ManagerNotInitializedException(
          'GameManager must be initialized before being used');
    }
    return _instance!;
  }

  static GameManager? _instance;
  GameManager._internal() {
    ConfigurationManager.instance.onChanged.addListener(_checkForInvalidRules);
  }

  ///
  /// This is a method to tell the game manager that the rules have changed and
  /// some things may need to be updated
  /// [shouldRepickProblem] is used to tell the game manager that the problem
  /// picker rules have changed and that it should repick a problem.
  /// [repickNow] is used to tell the game manager that it should repick a
  /// problem now or wait a future call. That is to wait until all the changes
  /// to the rules are made before repicking a problem.
  void rulesHasChanged({
    bool shouldRepickProblem = false,
    bool repickNow = false,
  }) {
    if (shouldRepickProblem) _forceRepickProblem = true;
    if (repickNow && _forceRepickProblem) {
      _isSearchingNextProblem = false;
      _nextProblems.clear();
      _searchProblemForRound(
          round: _roundCount, maxSearchingTime: Duration.zero);
    }
  }

  ///
  /// Check if the rules are valid. If not, it will prevent the game from
  /// sending the results to the leaderboard.
  /// If the rules were invalid at least once during the game, do not allow
  /// for the results to be sent to the leaderboard either (even if the rules
  /// are valid now).
  void _checkForInvalidRules() {
    _isAllowedToSendResults = _isAllowedToSendResults &&
        !ConfigurationManager.instance.useCustomAdvancedOptions;
  }

  ///
  /// As soon as anything changes, we need to notify the listeners of players.
  /// Otherwise, the UI would be spammed with updates.
  bool _forceRepickProblem = false;
  bool _hasAPlayerBeenUpdate = false;
  // This helps calling [_hasAPlayerBeenUpdate] a single frame after a player is out of cooldown
  final Map<String, bool> _playersWasInCooldownLastFrame = {};

  Future<void> _searchProblemForRound(
      {required int round, required Duration maxSearchingTime}) async {
    if (_isSearchingNextProblem) return;
    final cm = ConfigurationManager.instance;

    _forceRepickProblem = false;
    _isSearchingNextProblem = true;

    int i = _nextProblems.length - 1; // -1 is the round 0 (the first round)
    while (_nextProblems.length < 4) {
      // The first element is always the first level (in case of a restart of the game)
      // The others depend on the current round count
      final difficulty = cm.difficulty(i < 0 ? 0 : round + i);
      final previousDifficulty = cm.difficulty(i <= 0 ? 0 : round + i - 1);

      if (i >= 1 &&
          difficulty.hasSameRulesForPickingLetters(previousDifficulty)) {
        _nextProblems.add(_nextProblems.last);
      } else {
        _nextProblems.add(await cm.problemGenerator(
          nbLetterInSmallestWord: difficulty.nbLettersOfShortestWord,
          minLetters: difficulty.nbLettersMinToDraw,
          maxLetters: difficulty.nbLettersMaxToDraw,
          minimumNbOfWords: cm.minimumWordsNumber,
          maximumNbOfWords: cm.maximumWordsNumber,
          addUselessLetter: difficulty.hasUselessLetter,
          maxSearchingTime: maxSearchingTime,
          previousProblems: _previousProblems,
        ));
      }
      i++;
    }

    _isSearchingNextProblem = false;
  }

  void _initializeCallbacks() {
    onGameIsInitializing.notifyListeners();
    _initializeTrySolutionCallback();
    if (onShowMessage == null) {
      throw Exception('onShowMessage must be set before starting the game');
    }
    _gameStatus = GameStatus.roundPreparing;
  }

  ///
  /// Prepare the game for a new round by making sure everything is initialized.
  /// Then, it finds a new word problem and start the timer.
  Future<void> _startNewRound() async {
    if (_gameStatus == GameStatus.initializing) _initializeCallbacks();

    if (_gameStatus != GameStatus.roundPreparing &&
        _gameStatus != GameStatus.roundReady) {
      return;
    }

    final cm = ConfigurationManager.instance;

    onRoundIsPreparing.notifyListeners();

    // Wait until a problem is found
    while (_isSearchingNextProblem) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (_successLevel == SuccessLevel.failed) _restartGame();
    _setValuesAtStartRound();

    // Start searching for the next problem as soon as possible to avoid
    // waiting for the next round
    _searchProblemForRound(
        round: _roundCount + 1,
        maxSearchingTime: Duration(seconds: cm.roundDuration.inSeconds ~/ 2));

    // Send a message to players if required, but only once per session
    await _manageMessageToPlayers();

    _gameStatus = GameStatus.roundStarted;
    _roundStartedAt = DateTime.now();
    _nextTickAt = _roundStartedAt!.add(const Duration(seconds: 1));
    onRoundStarted.notifyListeners();
  }

  ///
  /// Manage the message to players. This is called at the start of a round and
  /// sends a telegram to the players if required. The message is skipped if it
  /// was previously sent.
  Future<void> _manageMessageToPlayers() async {
    final message =
        ConfigurationManager.instance.difficulty(_roundCount).message;

    if (message == null || _messagesToPlayers.contains(message)) return;

    _messagesToPlayers.add(message);
    await onShowMessage!(message);
  }

  void _setValuesAtStartRound() {
    final cm = ConfigurationManager.instance;

    // Reinitialize the round timer and players
    _roundDuration = cm.roundDuration.inMilliseconds +
        cm.postRoundGracePeriodDuration.inMilliseconds;
    for (final player in players) {
      player.resetForNextRound();
    }

    _hasPlayedAtLeastOnce = true;
    _isUselessLetterRevealed = false;
    _isHiddenLetterRevealed = false;
    _nextRoundStartAt = null;
    _scramblingLetterTimer = cm.timeBeforeScramblingLetters.inSeconds;

    // Transfer the next problem to the current problem
    _currentProblem = _nextProblems[_successLevel.toInt()];
    _previousProblems.add(_currentProblem!);
    if (_roundCount < 1) {
      _nextProblems.clear();
    } else {
      // No need to remove the first element (Round 0)
      while (_nextProblems.length > 1) {
        _nextProblems.removeAt(1);
      }
    }

    // Reset the round successes
    _successLevel = SuccessLevel.threeStars;
    _roundSuccesses.clear();
    _lastStolenSolution = null;

    _boostStartedAt = null;
    _requestedBoost.clear();
  }

  ///
  /// Initialize the callbacks from Twitch chat to [_trySolution]
  Future<void> _initializeTrySolutionCallback() async => TwitchManager.instance
      .addChatListener((sender, message) => _trySolution(sender, message));

  ///
  /// Try to solve the problem from a [message] sent by a [sender], that is a
  /// Twitch chatter.
  Future<void> _trySolution(String sender, String message) async {
    if (problem == null || timeRemaining == null) return;
    final cm = ConfigurationManager.instance;

    // Get the player from the players list
    final player = players.firstWhereOrAdd(sender);

    if (cm.canUseControllerHelper) {
      if (message == '!pardon') {
        _pardonLastStealer(player);
        return;
      } else if (message == '!boost') {
        _boostTrain(player);
      }
    }

    // If the player is in cooldown, they are not allowed to answer
    if (player.isInCooldownPeriod) return;

    // Find if the proposed word is valid
    final solution = problem!.trySolution(message,
        nbLetterInSmallestWord:
            cm.difficulty(_roundCount).nbLettersOfShortestWord);
    if (solution == null) return;

    // Add to player score
    if (solution.isFound) {
      // If the solution was already found, the player can steal it. It however
      // provides half the score and doubles the cooldown period.

      // The player cannot steal
      // if the game is not configured to allow it
      // or if the word was already stolen once
      // or the player is trying to steal from themselves
      // or was stolen in less than the cooldown of the previous founder
      if (!cm.canSteal ||
          solution.isStolen ||
          solution.foundBy == player ||
          solution.foundBy.isInCooldownPeriod) {
        return;
      }
      _lastStolenSolution = solution;

      // Remove the score to original founder and override the cooldown
      solution.foundBy.score -= solution.value;
    }
    solution.foundBy = player;
    player.lastSolutionFound = solution;
    if (solution.isStolen) {
      solution.foundBy.addToStealCount();
      solution.stolenFrom.lastSolutionFound = null;
      onSolutionWasStolen.notifyListenersWithParameter(solution);
    }

    player.score += solution.value;

    final cooldownDuration = Duration(
        seconds: (players.length * 2 + 1)
                .clamp(5, cm.cooldownPeriod.inSeconds) +
            cm.cooldownPenaltyAfterSteal.inSeconds * player.roundStealCount);
    player.startCooldown(duration: cooldownDuration);

    // Call the listeners of solution found
    onSolutionFound.notifyListenersWithParameter(solution);

    // Also plan for an call to the listeners of players on next game loop
    _hasAPlayerBeenUpdate = true;
    _playersWasInCooldownLastFrame[player.name] = true;
  }

  ///
  /// Performs the pardon to a player, that is giving back the points to the team
  /// and remove the stolen flag for the player. This is only performed if the
  /// pardonner is not the stealer themselves.
  void _pardonLastStealer(Player playerWhoRequestedPardon) {
    if (_remainingPardons < 1) return;

    if (_lastStolenSolution == null) {
      // Tell the players that there was no stealer to pardon
      onStealerPardonned.notifyListenersWithParameter(null);
      return;
    }
    final solution = _lastStolenSolution!;

    // Only the player who was stolen from can pardon the stealer
    if (solution.stolenFrom != playerWhoRequestedPardon) {
      onStealerPardonned.notifyListenersWithParameter(solution);
      return;
    }

    // If we get here, the solution is pardonned (so not stolen anymore)
    _remainingPardons -= 1;
    _lastStolenSolution = null;
    solution.pardonStealer();
    solution.foundBy.removeFromStealCount();

    onStealerPardonned.notifyListenersWithParameter(solution);
  }

  ///
  /// Boost the train. This will double the score for the subsequent solutions
  /// found during the next boostTime
  void _boostTrain(Player player) {
    if (_remainingBoosts < 1 || isTrainBoosted) return;

    // All different players must request the boost
    if (_requestedBoost.contains(player)) return;
    _requestedBoost.add(player);

    // If we fulfill the number of boost requests needed, we can start the boost
    final cm = ConfigurationManager.instance;
    final nbBoostStillNeeded =
        cm.numberOfBoostRequestsNeeded - _requestedBoost.length;
    if (nbBoostStillNeeded == 0) {
      _remainingBoosts -= 1;
      _boostStartedAt = DateTime.now();
    }

    onTrainGotBoosted.notifyListenersWithParameter(nbBoostStillNeeded);
  }

  ///
  /// Restart the game by resetting the players and the round count
  void _restartGame() {
    final cm = ConfigurationManager.instance;

    _roundCount = 0;
    _isAllowedToSendResults = !cm.useCustomAdvancedOptions;
    _previousProblems.clear();

    _remainingPardons = cm.numberOfPardons;
    _remainingBoosts = cm.numberOfBoosts;

    players.clear();
  }

  ///
  /// Tick the game timer. If the timer is over, [_endOfRound] is called.
  void _gameLoop(Timer timer) {
    onTimerTicks.notifyListeners();

    if ((_gameStatus == GameStatus.initializing ||
            _gameStatus == GameStatus.roundPreparing) &&
        isNextProblemReady) {
      if (_gameStatus == GameStatus.roundPreparing) {
        _gameStatus = GameStatus.roundReady;
      }
      onNextProblemReady.notifyListeners();

      return;
    }
    if (_gameStatus == GameStatus.roundReady) {
      if (_nextRoundStartAt != null &&
          DateTime.now().isAfter(_nextRoundStartAt!)) {
        _nextRoundStartAt = null;
        _startNewRound();
      }

      return;
    }

    _gameTick();
    _endOfRound();
  }

  ///
  /// Tick the game timer and the cooldown timer of players. Call the
  /// listeners if needed.
  void _gameTick() {
    if (_gameStatus != GameStatus.roundStarted || timeRemaining == null) return;

    // Wait for a full second to pass before ticking
    if (DateTime.now().isBefore(_nextTickAt!)) return;
    _nextTickAt = _nextTickAt!.add(const Duration(seconds: 1));

    final cm = ConfigurationManager.instance;

    // Manager players cooling down
    for (final player in players) {
      if (player.isInCooldownPeriod) {
        _hasAPlayerBeenUpdate = true;
      } else if (_playersWasInCooldownLastFrame[player.name] ?? false) {
        _playersWasInCooldownLastFrame[player.name] = false;
        _hasAPlayerBeenUpdate = true;
      }
    }
    if (_hasAPlayerBeenUpdate) {
      onPlayerUpdate.notifyListeners();
      _hasAPlayerBeenUpdate = false;
    }

    // Manager letter swapping in the problem
    _scramblingLetterTimer -= 1;
    if (_scramblingLetterTimer <= 0) {
      _scramblingLetterTimer = cm.timeBeforeScramblingLetters.inSeconds;
      _currentProblem!.scrambleLetters();
      onScrablingLetters.notifyListeners();
    }

    // Manage useless letter
    if (!_isUselessLetterRevealed &&
        ConfigurationManager.instance
            .difficulty(_roundCount)
            .hasUselessLetter &&
        timeRemaining! <=
            cm.difficulty(_roundCount).revealUselessLetterAtTimeLeft) {
      _isUselessLetterRevealed = true;
      onRevealUselessLetter.notifyListeners();
    }

    // Manage hidden letter
    if (!_isHiddenLetterRevealed &&
        ConfigurationManager.instance.difficulty(_roundCount).hasHiddenLetter &&
        timeRemaining! <=
            cm.difficulty(_roundCount).revealHiddenLetterAtTimeLeft) {
      _isHiddenLetterRevealed = true;
      onRevealHiddenLetter.notifyListeners();
    }

    // Manage boost of the train
    if (isTrainBoosted && (trainBoostRemainingTime?.inSeconds ?? -1) <= 0) {
      _boostStartedAt = null;
    }
  }

  ///
  /// Clear the current round
  Future<void> _endOfRound() async {
    // Do not end the round if we are not playing
    if (_gameStatus != GameStatus.roundStarted) return;

    final cm = ConfigurationManager.instance;

    // End round
    // if the request was made
    // if the timer is over
    // if all the words have been found
    bool shouldEndTheRound = _forceEndTheRound ||
        timeRemaining! <=
            -ConfigurationManager
                .instance.postRoundGracePeriodDuration.inSeconds ||
        _currentProblem!.areAllSolutionsFound;
    if (!shouldEndTheRound) return;

    _successLevel = completedLevel;
    _roundCount += _successLevel.toInt();
    DatabaseManager.instance.sendLetterProblem(problem: _currentProblem!);

    _forceEndTheRound = false;
    _roundDuration = null;
    _roundStartedAt = null;
    _boostStartedAt = null;

    if (_currentProblem!.areAllSolutionsFound) {
      _roundSuccesses.add(RoundSuccess.foundAll);
      _remainingPardons += 1;
      onAllSolutionsFound.notifyListeners();
    }

    _showCaseAnswers(playSound: true);

    // Launch the automatic start of the round time if needed
    if (cm.autoplay) {
      _nextRoundStartAt = DateTime.now()
          .add(cm.autoplayDuration + cm.postRoundShowCaseDuration);
    }

    // If it is permitted to send the results to the leaderboard, do it
    if (_isAllowedToSendResults) {
      DatabaseManager.instance.sendResults(
          stationReached: roundCount, mvpPlayers: players.bestPlayers);
    }
  }

  void requestShowCaseAnswers() {
    if (_gameStatus == GameStatus.initializing ||
        _gameStatus == GameStatus.roundStarted ||
        _gameStatus == GameStatus.revealAnswers) {
      return;
    }
    _gameStatus = GameStatus.revealAnswers;
    _showCaseAnswers(playSound: false);
  }

  void _showCaseAnswers({required bool playSound}) {
    final cm = ConfigurationManager.instance;

    _gameStatus = GameStatus.revealAnswers;
    Timer(Duration(seconds: cm.postRoundShowCaseDuration.inSeconds), () {
      onRoundIsPreparing.notifyListeners();
      _gameStatus = isNextProblemReady
          ? GameStatus.roundReady
          : GameStatus.roundPreparing;
    });
    onRoundIsOver.notifyListenersWithParameter(playSound);
  }

  SuccessLevel get completedLevel {
    if (problem == null ||
        problem!.teamScore < pointsToObtain(SuccessLevel.oneStar)) {
      return SuccessLevel.failed;
    } else if (problem!.teamScore < pointsToObtain(SuccessLevel.twoStars)) {
      return SuccessLevel.oneStar;
    } else if (problem!.teamScore < pointsToObtain(SuccessLevel.threeStars)) {
      return SuccessLevel.twoStars;
    } else {
      return SuccessLevel.threeStars;
    }
  }

  int remainingPointsToNextLevel() {
    final currentLevel = completedLevel;
    if (currentLevel == SuccessLevel.threeStars) return 0;

    final nextLevel = SuccessLevel.values[currentLevel.index + 1];
    return pointsToObtain(nextLevel) - problem!.teamScore;
  }

  int pointsToObtain(SuccessLevel level) {
    final difficulty = ConfigurationManager.instance.difficulty(_roundCount);

    final maxScore = problem?.maximumScore ?? 0;
    switch (level) {
      case SuccessLevel.oneStar:
        return (maxScore * difficulty.thresholdFactorOneStar).toInt();
      case SuccessLevel.twoStars:
        return (maxScore * difficulty.thresholdFactorTwoStars).toInt();
      case SuccessLevel.threeStars:
        return (maxScore * difficulty.thresholdFactorThreeStars).toInt();
      case SuccessLevel.failed:
        throw Exception('Failed is not a valid level');
    }
  }
}

class GameManagerMock extends GameManager {
  LetterProblemMock? _problemMocker;

  static Future<void> initialize({
    GameStatus? gameStatus,
    LetterProblemMock? problem,
    List<Player>? players,
    int? roundCount,
    SuccessLevel? successLevel,
  }) async {
    if (GameManager._instance != null) {
      throw ManagerAlreadyInitializedException(
          'GameManager should not be initialized twice');
    }
    GameManager._instance = GameManagerMock._internal();

    if (players != null) {
      for (final player in players) {
        GameManager._instance!.players.add(player);
      }
    }

    GameManager._instance!._gameStatus = GameStatus.initializing;
    if (roundCount != null) {
      GameManager._instance!._roundCount = roundCount;
      GameManager._instance!._gameStatus = GameStatus.roundReady;
    }
    if (successLevel != null) {
      GameManager._instance!._roundCount += successLevel.toInt();
      (GameManager._instance! as GameManagerMock)._successLevel = successLevel;
    }

    GameManager._instance!._initializeTrySolutionCallback();
    if (problem == null) {
      GameManager._instance!._searchProblemForRound(
          round: GameManager.instance._roundCount,
          maxSearchingTime: Duration.zero);
    } else {
      (GameManager._instance! as GameManagerMock)._problemMocker = problem;
      GameManager._instance!._currentProblem = problem;
      GameManager._instance!._nextProblems.add(problem);

      Future.delayed(const Duration(seconds: 1)).then((value) =>
          GameManager._instance!.onNextProblemReady.notifyListeners());
    }

    if (gameStatus != null) GameManager._instance!._gameStatus = gameStatus;
    if (gameStatus == GameStatus.roundStarted) {
      GameManager._instance!._setValuesAtStartRound();
    }

    Timer.periodic(
        const Duration(milliseconds: 100), GameManager._instance!._gameLoop);
  }

  @override
  bool get hasPlayedAtLeastOnce => true;

  @override
  Future<void> _searchProblemForRound(
      {required int round, required Duration maxSearchingTime}) async {
    if (_problemMocker == null) {
      await super._searchProblemForRound(
          round: round, maxSearchingTime: maxSearchingTime);
    } else {
      _nextProblems.add(_problemMocker);

      // Make sure the game don't run if the player is not logged in
      final dm = DatabaseManager.instance;
      dm.onLoggedOut.addListener(() => requestTerminateRound());
      dm.onFullyLoggedIn.addListener(() {
        if (gameStatus != GameStatus.initializing) _startNewRound();
      });

      _isSearchingNextProblem = false;
    }
    GameManager._instance!.onGameIsInitializing.notifyListeners();
  }

  GameManagerMock._internal() : super._internal();
}
