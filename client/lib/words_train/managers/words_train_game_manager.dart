import 'dart:async';
import 'dart:math';

import 'package:common/generic/managers/serializable_controllable_timer.dart';
import 'package:common/generic/models/exceptions.dart';
import 'package:common/generic/models/game_status.dart';
import 'package:common/generic/models/generic_listener.dart';
import 'package:common/generic/models/mini_games.dart';
import 'package:common/generic/models/random_extension.dart';
import 'package:common/generic/models/serializable_game_state.dart';
import 'package:logging/logging.dart';
import 'package:train_de_mots/generic/managers/controllable_timer.dart';
import 'package:train_de_mots/generic/managers/managers.dart';
import 'package:train_de_mots/words_train/managers/two_step_requester.dart';
import 'package:train_de_mots/words_train/models/difficulty.dart';
import 'package:train_de_mots/words_train/models/letter_problem.dart';
import 'package:train_de_mots/words_train/models/player.dart';
import 'package:train_de_mots/words_train/models/round_success.dart';
import 'package:train_de_mots/words_train/models/success_level.dart';
import 'package:train_de_mots/words_train/models/word_solution.dart';

final _logger = Logger('GameManager');

class WordsTrainGameManager {
  /// ---------------- ///
  /// MEMBER VARIABLES ///
  /// ---------------- ///

  ///
  /// Whether the game manager is ready to be used.
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  ///
  /// Random generator.
  final _random = Random();

  ///
  /// All the players currently registered in the game.
  final Players players = Players();

  WordsTrainGameStatus _gameStatus = WordsTrainGameStatus.initializing;
  WordsTrainGameStatus get gameStatus {
    if (_gameStatus == WordsTrainGameStatus.roundPreparing &&
        isNextProblemReady) {
      return WordsTrainGameStatus.roundReady;
    }
    return _gameStatus;
  }

  int _roundCount = 0;
  int get roundCount => _roundCount;

  final _roundTimer = ControllableTimer(
    onStatusChanged: (status) {},
    onClockTicked: (deltaTime, status) {},
  )..initialize();
  ControllableTimer get roundTimer => _roundTimer;
  DateTime? get roundEndsAt => _roundTimer.endsAt;
  Duration? get timeRemaining => _roundTimer.timeRemaining;
  Duration _previousRoundTimeRemaining = Duration.zero;
  Duration get previousRoundTimeRemaining =>
      Duration(seconds: max(_previousRoundTimeRemaining.inSeconds, 0));

  Difficulty get _currentDifficulty =>
      Managers.instance.configuration.difficulty(_roundCount);

  Duration _computeCooldownDuration({required Player player}) {
    final cm = Managers.instance.configuration;
    return Duration(
        seconds: players.length.clamp(4, cm.cooldownPeriod.inSeconds) +
            cm.cooldownPenaltyAfterSteal.inSeconds * player.roundStealCount);
  }

  Duration _scramblingLetterTimer = Duration.zero;

  LetterProblem? _currentProblem;
  final List<LetterProblem> _playedProblems = [];
  LetterProblem? _nextProblem;
  bool _isGeneratingProblem = false;
  bool get isNextProblemReady =>
      (!_isGeneratingProblem && _nextProblem != null);
  bool get canProceedToNextRound =>
      (isNextProblemReady || _isNextRoundAMiniGame) &&
      _roundTimer.status != ControllableTimerStatus.paused;

  LetterProblem? get problem => _currentProblem;
  List<LetterStatus> get uselessLetterStatuses => problem == null
      ? []
      : List.generate(
          problem!.letters.length,
          (i) => i == problem!.uselessLetterIndex
              ? _isUselessLetterRevealed
                  ? LetterStatus.revealed
                  : LetterStatus.hidden
              : LetterStatus.normal);
  List<LetterStatus> get hiddenLetterStatuses => problem == null
      ? []
      : List.generate(
          problem!.letters.length,
          (i) => i == hiddenLetterIndex
              ? _isHiddenLetterRevealed
                  ? LetterStatus.revealed
                  : LetterStatus.hidden
              : LetterStatus.normal);

  SerializableLetterProblem? get serializableProblem => problem == null
      ? null
      : SerializableLetterProblem(
          letters: problem!.letters,
          scrambleIndices: problem!.scrambleIndices,
          uselessLetterStatuses: uselessLetterStatuses,
          hiddenLetterStatuses: hiddenLetterStatuses,
        );
  SuccessLevel _successLevel = SuccessLevel.failed;
  final List<RoundSuccess> _roundSuccesses = [];
  List<RoundSuccess> get roundSuccesses => _roundSuccesses;

  bool _hasPlayedAtLeastOnce = false;
  bool get hasPlayedAtLeastOnce => _hasPlayedAtLeastOnce;
  bool _forceEndTheRound = false;
  late bool _isAllowedToSendResults =
      !Managers.instance.configuration.useCustomAdvancedOptions;
  bool get isAllowedToSendResults => _isAllowedToSendResults;

  bool _roundHasGoldenSolution = false;
  bool _forceGoldenSolution = false;

  WordSolution? _lastStolenSolution;
  WordSolution? get lastStolenSolution => _lastStolenSolution;
  int _remainingPardons = 0;
  int get remainingPardon => _remainingPardons;

  int _remainingBoosts = 0;
  bool _boostWasGrantedThisRound = false;
  bool get boostWasGrantedThisRound => _boostWasGrantedThisRound;
  double _currentNewBoostThreshold = -1.0;
  int get remainingBoosts => _remainingBoosts;
  bool get isTrainBoosted => _boostStartedAt != null;
  Duration? get trainBoostRemainingTime => _boostStartedAt
      ?.add(Managers.instance.configuration.boostTime)
      .difference(DateTime.now());
  DateTime? _boostStartedAt;
  final List<Player> _requestedBoost = [];
  List<Player> get requestedBoost => List.unmodifiable(_requestedBoost);
  int get numberOfBoostStillNeeded {
    final cm = Managers.instance.configuration;
    final numberOfBoostRequestsNeeded = switch (players.length) {
      1 || 2 => 1,
      3 || 4 => 2,
      _ => cm.numberOfBoostRequestsNeeded,
    };

    return numberOfBoostRequestsNeeded - _requestedBoost.length;
  }

  bool _canChangeLane = false;
  bool _isChangingLane = false;
  bool get canChangeLane => _canChangeLane && !_isChangingLane;
  late final changeLaneRequester = TwoStepRequester(
    canRequest: () async => canChangeLane,
    onRequestInitialized: (playerName) async {},
    onRequestFinalized: ({required isConfirmed, required playerName}) async {
      if (isConfirmed) _performChangeOfLane();
    },
  );

  bool _canAttemptTheBigHeist = false;
  bool _isAttemptingTheBigHeist = false;
  bool get canRequestTheBigHeist =>
      _canAttemptTheBigHeist && !_isAttemptingTheBigHeist;
  bool get isAttemptingTheBigHeist => _isAttemptingTheBigHeist;
  late final attemptTheBigHeistRequester = TwoStepRequester(
    canRequest: () async => canRequestTheBigHeist,
    onRequestInitialized: (playerName) async => pauseGame(),
    onRequestFinalized: ({required isConfirmed, required playerName}) async {
      resumeGame();
      if (isConfirmed) _attemptTheBigHeist(playerName: playerName);
    },
  );

  int _fixTracksMiniGamesAttempted = 0;
  bool _canAttemptFixTracksMiniGame = false;
  bool _isAttemptingFixTracksMiniGame = false;
  bool get canRequestFixTracksMiniGame =>
      _canAttemptFixTracksMiniGame && !_isAttemptingFixTracksMiniGame;
  bool get isAttemptingFixTracksMiniGame => _isAttemptingFixTracksMiniGame;
  late final fixTracksMiniGameRequester = TwoStepRequester(
    canRequest: () async => canRequestFixTracksMiniGame,
    onRequestInitialized: (playerName) async => pauseGame(),
    onRequestFinalized: ({required isConfirmed, required playerName}) async {
      resumeGame();
      if (isConfirmed) _prepareFixTracksMiniGame();
    },
  );

  bool _isNextRoundAMiniGame = false;
  bool get isNextRoundAMiniGame => _isNextRoundAMiniGame;
  bool _isRoundAMiniGame = false;
  bool get isRoundAMiniGame => _isRoundAMiniGame;
  MiniGames? _currentMiniGame;
  MiniGames? get currentMiniGame => _isRoundAMiniGame ? _currentMiniGame : null;
  MiniGames? get nextRoundMiniGame =>
      _isNextRoundAMiniGame ? _currentMiniGame : null;

  bool _canRequestCongratulationFireworks = false;
  bool _areCongratulationFireworksFiring = false;
  bool get canRequestCongratulationFireworks =>
      _canRequestCongratulationFireworks && !_areCongratulationFireworksFiring;
  late final congratulationFireworksRequester = TwoStepRequester(
    canRequest: () async => canRequestCongratulationFireworks,
    onRequestInitialized: (playerName) async => pauseGame(),
    onRequestFinalized: ({required isConfirmed, required playerName}) async {
      resumeGame();
      if (isConfirmed) _performCongratulationFireworks(playerName: playerName);
    },
  );

  late final _autoStart = ControllableTimer(
      onClockTicked: _onAutoStartClockTicked,
      onStatusChanged: _onAutoStartStatusChanged);
  Duration? get timeRemainingBeforeAutoStart => _autoStart.timeRemaining;
  void cancelAutoStart() => _autoStart.dispose();

  /// ----------- ///
  /// CONSTRUCTOR ///
  /// ----------- ///

  WordsTrainGameManager() {
    _asyncInitializations();
  }

  Future<void> _asyncInitializations() async {
    _logger.config('Initializing...');

    while (true) {
      try {
        Managers.instance.configuration.onChanged.listen(_checkForInvalidRules);
        break;
      } on ManagerNotInitializedException {
        // Wait and repeat
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }

    _isInitialized = true;

    _logger.config('Ready');
    while (!Managers.instance.allManagersInitialized) {
      // Wait for all managers to be initialized before allowing the game to start
      await Future.delayed(const Duration(milliseconds: 100));
    }
    Managers.instance.tickerManager.onFixedClockTicked.listen(_gameLoop);
  }

  SerializableGameState serialize() {
    return SerializableGameState(
      roundCount: roundCount,
      gameStatus: gameStatus,
      isRoundAMiniGame: isRoundAMiniGame,
      isRoundSuccess: successLevel.toInt() > 0,
      roundTimer: _roundTimer.toSerializable(),
      players: players
          .asMap()
          .map((_, player) => MapEntry(player.name, player.serialize())),
      letterProblem: serializableProblem,
      pardonRemaining: remainingPardon,
      pardonners: [lastStolenSolution?.stolenFrom.name ?? ''],
      boostRemaining: remainingBoosts,
      boostStillNeeded: numberOfBoostStillNeeded,
      boosters: requestedBoost.map((e) => e.name).toList(),
      canRequestTheBigHeist: canRequestTheBigHeist,
      isAttemptingTheBigHeist: isAttemptingTheBigHeist,
      canRequestFixTracksMiniGame: canRequestFixTracksMiniGame,
      isAttemptingFixTracksMiniGame: isAttemptingFixTracksMiniGame,
      configuration: SerializableConfiguration(
          showExtension: Managers.instance.configuration.showExtension),
      miniGameState: isRoundAMiniGame || isNextRoundAMiniGame
          ? Managers.instance.miniGames.manager?.serializeMiniGame()
          : null,
    );
  }

  /// ----------- ///
  /// INTERACTION ///
  /// ----------- ///

  ///
  /// Pause the game by stopping the round timer.
  ///
  void pauseGame() {
    _logger.info('Pausing the game...');
    _roundTimer.pause();
    if (_autoStart.isInitialized) _autoStart.pause();
    Managers.instance.miniGames.manager?.pauseRound();
  }

  ///
  /// Resume the game by restarting the round timer with the remaining time when the game was paused.
  ///
  void resumeGame() {
    _logger.info('Resuming the game...');
    _roundTimer.resume();
    if (_autoStart.isInitialized) _autoStart.resume();
    Managers.instance.miniGames.manager?.resumeRound();
  }

  ///
  /// Provide a way to request the start of a new round, if the game is not
  /// already started or if the game is not already over.
  Future<void> requestStartNewRound() async {
    if (!canProceedToNextRound) return;

    _logger.info('Requesting to start a new round');
    _startNewRound();
  }

  ///
  /// Provide a way to request the search for the next problem, if the game is
  /// not already searching for a problem.
  Future<void> requestSearchForNextProblem() async {
    _logger.info('Requesting to search for the next problem');

    _generateNextProblem(force: false);
  }

  ///
  /// Provide a way to request the premature end of the round
  Future<void> requestTerminateRound() async {
    _logger.info('Requesting to terminate the round');

    if (gameStatus == WordsTrainGameStatus.initializing) {
      _initializeCallbacks();
      _gameStatus = WordsTrainGameStatus.roundPreparing;
      onRoundIsPreparing.notifyListeners((callback) => callback());
    }
    if (_gameStatus != WordsTrainGameStatus.roundStarted) return;
    _forceEndTheRound = true;
  }

  final List<String> _messagesToPlayers = [];
  SuccessLevel get successLevel => _successLevel;

  bool get hasUselessLetter => _currentDifficulty.hasUselessLetter;
  bool _isUselessLetterRevealed = false;
  bool get isUselessLetterRevealed => _isUselessLetterRevealed;
  int get uselessLetterIndex => _currentProblem?.uselessLetterIndex ?? -1;

  bool get hasHiddenLetter =>
      _currentDifficulty.hasHiddenLetter && !_isHiddenLetterRevealed;
  bool _isHiddenLetterRevealed = false;
  int get hiddenLetterIndex => _currentDifficulty.hasHiddenLetter
      ? _currentProblem!.hiddenLettersIndex
      : -1;

  /// --------- ///
  /// CALLBACKS ///
  /// When registering to a callback, one should remind themselves to
  /// unregister when the widget is disposed, otherwise it will leak memory.
  /// --------- ///

  /// Callbacks for that tells listeners that the round is preparing
  final onGameIsInitializing = GenericListener<Function()>();
  final onRoundIsPreparing = GenericListener<Function()>();
  final onNextProblemReady = GenericListener<Function()>();
  final onRoundStarted = GenericListener<Function()>();
  final onRoundIsOver = GenericListener<Function()>();
  final onScrablingLetters = GenericListener<Function()>();
  final onRevealUselessLetter = GenericListener<Function()>();
  final onRevealHiddenLetter = GenericListener<Function()>();
  final onSolutionFound = GenericListener<Function(WordSolution)>();
  final onSolutionWasStolen = GenericListener<Function(WordSolution)>();
  final onGoldenSolutionAppeared = GenericListener<Function(WordSolution)>();
  final onStealerPardoned = GenericListener<Function(WordSolution?)>();
  final onNewPardonGranted = GenericListener<Function()>();
  final onMiniGameGranted = GenericListener<Function(MiniGames)>();
  final onFixTracksMiniGameUpdated = GenericListener<Function()>();
  final onNewBoostGranted = GenericListener<Function()>();
  final onTrainGotBoosted = GenericListener<Function(int)>();
  final onTrainBoostEnded = GenericListener<Function()>();
  final onBigHeistIsBeingPrepared = GenericListener<
      Function({required String playerName, required bool isActive})>();
  final onAttemptingTheBigHeist =
      GenericListener<Function({required String playerName})>();
  final onBigHeistSuccess = GenericListener<Function()>();
  final onBigHeistFailed = GenericListener<Function()>();
  final onChangingLane = GenericListener<Function()>();
  final onShowcaseSolutionsRequest = GenericListener<Function()>();
  final onPlayerUpdate = GenericListener<Function()>();
  final onCongratulationFireworksPreparing = GenericListener<
      Function({required String playerName, required bool isActive})>();
  final onCongratulationFireworks = GenericListener<
      Function({required String playerName, required bool isActive})>();
  Future<void> Function(String)? onShowTelegram;

  /// -------- ///
  /// INTERNAL ///
  /// -------- ///

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
    _logger.info('Checking for changes in the rules...');

    if (shouldRepickProblem) _forceRepickProblem = true;
    if (repickNow && _forceRepickProblem) {
      _logger.info('Rules have changed, repicking a problem...');
      _generateNextProblem(force: true);
    }

    _logger.info('Rules have been updated');
  }

  ///
  /// Check if the rules are valid. If not, it will prevent the game from
  /// sending the results to the leaderboard.
  /// If the rules were invalid at least once during the game, do not allow
  /// for the results to be sent to the leaderboard either (even if the rules
  /// are valid now).
  void _checkForInvalidRules() {
    _logger.fine('Checking for invalid rules...');
    _isAllowedToSendResults = _isAllowedToSendResults &&
        !Managers.instance.configuration.useCustomAdvancedOptions;
  }

  ///
  /// As soon as anything changes, we need to notify the listeners of players.
  /// Otherwise, the UI would be spammed with updates.
  bool _forceRepickProblem = false;
  bool _hasAPlayerBeenUpdate = false;
  // This helps calling [_hasAPlayerBeenUpdate] a single frame after a player is out of cooldown
  final Map<String, bool> _playersWasInCooldownLastFrame = {};

  Future<void> _generateNextProblem({required bool force}) async {
    final round = _successLevel == SuccessLevel.failed ? 0 : roundCount;
    _logger.info('Generating for next problem (round $round...)');

    // If we are already generating a problem, we have to wait for it to finish and then we generate a new one.
    // If we do not need a new problem, we just return
    while (_isGeneratingProblem) {
      if (!force) {
        _logger.warning('Already searching for a problem');
        return;
      }
      await Future.delayed(const Duration(milliseconds: 100));
    }

    _nextProblem = null;
    _isGeneratingProblem = true;

    final cm = Managers.instance.configuration;
    _forceRepickProblem = false;

    LetterProblem? problem;
    final difficulty = cm.difficulty(round);
    while (problem == null) {
      problem = await LetterProblem.fetchFromEbs(
        nbLetterInSmallestWord: difficulty.nbLettersOfShortestWord,
        minLetters: difficulty.nbLettersMinToDraw,
        maxLetters: difficulty.nbLettersMaxToDraw,
        minimumNbOfWords: cm.minimumWordsNumber,
        maximumNbOfWords: cm.maximumWordsNumber,
        addUselessLetter: difficulty.hasUselessLetter,
      );

      if (_playedProblems.contains(problem)) {
        _logger
            .fine('Problem was already played, searching for another one...');
        problem = null;
      }
    }

    onNextProblemReady.notifyListeners((callback) => callback());
    _nextProblem = problem;
    _isGeneratingProblem = false;
    _logger.info('Problem found for round $round');
  }

  void _initializeCallbacks() {
    _logger.info('Initializing callbacks...');

    onGameIsInitializing.notifyListeners((callback) => callback());
    _initializeTrySolutionCallback();
    if (onShowTelegram == null) {
      throw Exception('onShowTelegram must be set before starting the game');
    }

    _gameStatus = WordsTrainGameStatus.roundPreparing;

    _logger.info('Callbacks initialized');
  }

  ///
  /// Prepare the game for a new round by making sure everything is initialized.
  /// Then, it finds a new word problem and start the timer. It launches the mini
  /// game if needed.
  Future<void> _startNewRound() async {
    _logger.info('Starting a new round...');
    if (_autoStart.isInitialized) _autoStart.dispose();

    if (_gameStatus == WordsTrainGameStatus.initializing) {
      _initializeCallbacks();
    }

    if (_gameStatus != WordsTrainGameStatus.roundPreparing) {
      _logger.warning('Cannot start a new round at this time');
      return;
    }

    if (Managers.instance.miniGames.current != null) {
      // If the previous round was a minigame, we need to finalize it before starting a new round
      Managers.instance.miniGames.finalize();
    }

    onRoundIsPreparing.notifyListeners((callback) => callback());
    if (_isNextRoundAMiniGame) {
      _logger.info('Preparing the mini game $_currentMiniGame...');
      _isRoundAMiniGame = true;
      _isNextRoundAMiniGame = false;

      Managers.instance.miniGames.initialize(_currentMiniGame!);
      final mgm = Managers.instance.miniGames.manager!;
      while (!mgm.isInitialized) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      mgm.onRoundEnded.listen(_miniGameEnded);
      _setValuesAtMiniGameStart();
      mgm.startRound();
    } else {
      _logger.info('Preparing a normal round...');
      _isRoundAMiniGame = false;

      // Wait for the problem to be generated
      while (_isGeneratingProblem) {
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // Prepare next round
      if (_successLevel == SuccessLevel.failed) _restartGame();
      _setValuesAtStartRound();
      final cm = Managers.instance.configuration;
      _roundTimer.start(
          duration: cm.roundDuration - Duration(seconds: roundCount));
    }
    _gameStatus = WordsTrainGameStatus.roundStarted;
    onRoundStarted.notifyListeners((callback) => callback());

    // Start the round
    pauseGame();
    await _sendTelegramToPlayers();
    resumeGame();

    _logger.info('New round started');
  }

  ///
  /// Manage the message to players. This is called at the start of a round and
  /// sends a telegram to the players if required. The message is skipped if it
  /// was previously sent.
  Future<void> _sendTelegramToPlayers() async {
    _logger.info('Preparing to send telegram to players...');

    String? message;
    if (_isRoundAMiniGame) {
      message = Managers.instance.miniGames.manager?.instructions;
    } else {
      message = _currentDifficulty.message;
    }

    if (message == null) {
      _logger.info('No telegram to send to players');
      return;
    }
    if (_messagesToPlayers.contains(message)) {
      _logger.info('telegram already sent to players');
      return;
    }

    _messagesToPlayers.add(message);
    _logger.info('Sending telegram to players...');
    await onShowTelegram!(message);
    _logger.info('Telegram sent to players');
  }

  void _setValuesAtStartRound() {
    _logger.info('Setting values at the start of the round...');

    final cm = Managers.instance.configuration;

    // Reinitialize the round timer and players
    for (final player in players) {
      player.resetForNextRound();
    }

    _roundHasGoldenSolution = false;
    _boostWasGrantedThisRound = false;
    _currentNewBoostThreshold = _currentDifficulty.newBoostThreshold +
        _random.nextDouble() * (1.0 - _currentDifficulty.newBoostThreshold);
    _hasPlayedAtLeastOnce = true;
    _isUselessLetterRevealed = false;
    _isHiddenLetterRevealed = false;
    _scramblingLetterTimer = cm.timeBeforeScramblingLetters;

    // Transfer the next problem to the current problem
    if (_currentProblem != null) _playedProblems.add(_currentProblem!);
    _currentProblem = _nextProblem;

    // Reset the round successes
    _successLevel = SuccessLevel.threeStars;
    _roundSuccesses.clear();
    _lastStolenSolution = null;

    _boostStartedAt = null;
    _requestedBoost.clear();

    // Change flags that are (not-)allowed during the round
    _canChangeLane = true;
    _canRequestCongratulationFireworks = false;
    _canAttemptTheBigHeist = false;
    _canAttemptFixTracksMiniGame = false;

    _logger.info('Values set at the start of the round');
  }

  void _setValuesAtMiniGameStart() {
    _roundSuccesses.clear();
  }

  ///
  /// Initialize the callbacks from Twitch chat to [trySolution]
  Future<void> _initializeTrySolutionCallback() async =>
      Managers.instance.twitch.addChatListener(
          (sender, message) => trySolution(playerName: sender, word: message));

  ///
  /// Try a solution proposed by a player. If the solution is valid, it updates
  /// the player score and notifies the listeners.
  Future<bool> trySolution(
      {required String playerName, required String word}) async {
    if (gameStatus != WordsTrainGameStatus.roundStarted) {
      _logger.fine('Cannot try solution while not playing a round');
      return false;
    }

    _logger.fine('Trying solution from $playerName: $word');
    final cm = Managers.instance.configuration;

    // Get the player from the players list
    final player = players.firstWhereOrAdd(playerName);

    // Can get a little help from the controller of the train
    if (cm.canUseControllerHelper) {
      if (word == '!pardon') {
        _logger.info('Trying to pardon the last stealer');
        pardonLastStealer(pardonner: player);
        return true;
      } else if (word == '!boost') {
        _logger.info('Trying to boost the train');
        boostTrain(player: player);
        return true;
      }
    }

    // If the player is in cooldown, they are not allowed to answer
    if (player.isInCooldownPeriod) {
      _logger.fine('Solution is invalid because player is in cooldown');
      return false;
    }

    // Find if the proposed word is valid
    final solution = problem!.trySolution(word,
        nbLetterInSmallestWord: _currentDifficulty.nbLettersOfShortestWord);
    if (solution == null) {
      _logger.fine('Solution is invalid because it is not a valid word');
      return false;
    }

    // Add to player score
    _logger.fine('Solution is valid');
    if (solution.isFound) {
      _logger.fine('Solution is valid, but was already found');
      // If the solution was already found, the player can steal it. It however
      // provides half the score and doubles the cooldown period.

      // The player cannot steal
      // if the game is not configured to allow it
      // or if the word was already stolen once
      // or if the word is golden
      // or the player is trying to steal from themselves
      // or was stolen in less than the cooldown of the previous founder
      // WARNING: there is actually a bug here where the cooldown is not the one
      // of the solution, but the cooldown of the player. This means that any
      // solution can't be stolen if the player is in cooldown. I decided to
      // keep it this way as there is already a lot of steals.
      if (!cm.canSteal ||
          solution.isStolen ||
          solution.isGolden ||
          solution.foundBy == player ||
          solution.foundBy.isInCooldownPeriod) {
        _logger.warning('Solution cannot be stolen');
        return false;
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
      onSolutionWasStolen.notifyListeners((callback) => callback(solution));
    }

    player.score += solution.value;
    if (solution.isGolden) player.starsCollected++;

    player.startCooldown(duration: _computeCooldownDuration(player: player));

    // Call the listeners of solution found
    onSolutionFound.notifyListeners((callback) => callback(solution));

    // Also plan for an call to the listeners of players on next game loop
    _hasAPlayerBeenUpdate = true;
    _playersWasInCooldownLastFrame[player.name] = true;

    _logger.info('Solution found');
    return true;
  }

  ///
  /// Performs the pardon to a player, that is giving back the points to the team
  /// and remove the stolen flag for the player. This is only performed if the
  /// pardonner is not the stealer themselves.
  bool pardonLastStealer({required Player pardonner}) {
    _logger.info('Pardoning the last stealer...');

    if (_remainingPardons < 1) {
      // Player cannot pardon anymore
      _logger.warning('No more pardons available');
      return false;
    }

    if (_lastStolenSolution == null) {
      // Tell the players that there was no stealer to pardon
      onStealerPardoned.notifyListeners((callback) => callback(null));
      _logger.warning('No stealer to pardon');
      return false;
    }
    final solution = _lastStolenSolution!;

    // Only the player who was stolen from can pardon the stealer
    if (solution.stolenFrom != pardonner) {
      onStealerPardoned.notifyListeners((callback) => callback(solution));
      _logger.warning('Player cannot pardon the stealer');
      return false;
    }

    // If we get here, the solution is pardoned (so not stolen anymore)
    _remainingPardons -= 1;
    _lastStolenSolution = null;
    solution.pardonStealer();
    solution.foundBy.removeFromStealCount();

    onStealerPardoned.notifyListeners((callback) => callback(solution));

    _logger.info('Stealer (${solution.foundBy.name}) has been pardoned by '
        '${pardonner.name}');
    return true;
  }

  ///
  /// Boost the train. This will double the score for the subsequent solutions
  /// found during the next boostTime
  bool boostTrain({required Player player}) {
    _logger.info('Boosting the train...');
    if (isTrainBoosted) {
      _logger.warning('Train is already boosted');
      return false;
    }

    if (_remainingBoosts < 1) {
      _logger.warning('No more boosts available');
      return false;
    }

    // All players requesting a boost must be unique
    if (_requestedBoost.contains(player)) {
      _logger.warning('Player already requested the boost');
      return false;
    }
    _requestedBoost.add(player);

    // If we fulfill the number of boost requests needed, we can start the boost
    if (numberOfBoostStillNeeded == 0) {
      _remainingBoosts -= 1;
      _boostStartedAt = DateTime.now();
    }

    onTrainGotBoosted
        .notifyListeners((callback) => callback(numberOfBoostStillNeeded));

    _logger.info('Train has been boosted');
    return true;
  }

  bool _attemptTheBigHeist({required String playerName}) {
    _logger.info('Requesting the big heist...');
    if (!canRequestTheBigHeist) {
      _logger.warning('Big heist cannot be attempted');
      return false;
    }

    _canAttemptTheBigHeist = false;
    _isAttemptingTheBigHeist = true;
    onAttemptingTheBigHeist
        .notifyListeners((callback) => callback(playerName: playerName));

    _logger.info('Big heist is attempted');
    return true;
  }

  void _prepareFixTracksMiniGame() {
    _logger.info('Preparing the fix tracks mini game...');
    if (!canRequestFixTracksMiniGame) {
      _logger.warning('Fix tracks mini game cannot be attempted');
      return;
    }

    _canAttemptFixTracksMiniGame = false;
    _fixTracksMiniGamesAttempted += 1;

    _isAttemptingFixTracksMiniGame = true;
    _isNextRoundAMiniGame = true;
    _currentMiniGame = MiniGames.fixTracksGames;

    onFixTracksMiniGameUpdated.notifyListeners((callback) => callback());
  }

  Future<void> _performChangeOfLane() async {
    _logger.info('Changing lane...');
    if (!canChangeLane) {
      _logger.warning('Cannot change lane at this time');
      return;
    }

    // Perform a huge scramble of the letters
    _isChangingLane = true;
    bool hasNotified = false;
    for (int i = 0; i < problem!.letters.length * 4; i++) {
      if (i % problem!.letters.length == 0) {
        if (!hasNotified) {
          onChangingLane.notifyListeners((callback) => callback());
          hasNotified = true;
        }
        onScrablingLetters.notifyListeners((callback) => callback());
        await Future.delayed(const Duration(milliseconds: 500));
      }
      problem!.scrambleLetters();
    }
    _isChangingLane = false;
  }

  ///
  /// Request the actual firework process
  Future<void> _performCongratulationFireworks(
      {required String playerName}) async {
    _logger.info('Performing congratulation fireworks...');
    if (!canRequestCongratulationFireworks) {
      _logger.warning('Cannot request congratulation fireworks at this time');
      return;
    }

    _areCongratulationFireworksFiring = true;

    // This is triggered if a user sends fireworks to the screen
    onCongratulationFireworks.notifyListeners(
        (callback) => callback(playerName: playerName, isActive: true));

    pauseGame();
    await Future.delayed(Duration(seconds: 10));
    resumeGame();

    // This should be stopped before that, but just in case we call stop anyway
    await requestStopFireworks(playerName: playerName);
  }

  ///
  /// Request the stop of the fireworks
  Future<void> requestStopFireworks({required String playerName}) async {
    if (!_areCongratulationFireworksFiring) return;

    _areCongratulationFireworksFiring = false;
    onCongratulationFireworks.notifyListeners(
        (callback) => callback(playerName: playerName, isActive: false));
  }

  ///
  /// Restart the game by resetting the players and the round count
  void _restartGame() {
    _logger.info('Restarting the game...');

    final cm = Managers.instance.configuration;

    _roundCount = 0;
    _isAllowedToSendResults = !cm.useCustomAdvancedOptions;

    _remainingPardons = cm.numberOfPardons;
    _remainingBoosts = cm.numberOfBoosts;

    // We can never attempt the big heist at the start
    _canAttemptTheBigHeist = false;
    _isAttemptingTheBigHeist = false;

    // There is no mini game at the start
    _isNextRoundAMiniGame = false;
    _isAttemptingFixTracksMiniGame = false;
    _fixTracksMiniGamesAttempted = 0;
    _isRoundAMiniGame = false;
    _currentMiniGame = null;
    _forceGoldenSolution = false;

    players.clear();

    _logger.info('Game restarted');
  }

  ///
  /// Tick the game timer. If the timer is over, [_endingRound] is called.
  void _gameLoop(Duration deltaTime) async {
    _tickingClock(deltaTime);
    if (_checkForEndOfRound()) _endingRound();
  }

  void _onAutoStartClockTicked(
      Duration deltaTime, ControllableTimerStatus status) {
    // If we are waiting for the round to start preparing
    if (_gameStatus != WordsTrainGameStatus.roundPreparing) {
      _logger.fine('Round is not preparing, so we delay the start');
      _autoStart.addTime(deltaTime);
    }

    // If the next problem is not ready and we are close to the end of the autostart timer,
    // we delay the start to avoid starting the round without a problem
    if (!isNextProblemReady &&
        (_autoStart.timeRemaining?.inMilliseconds ?? 1000) < 500) {
      _logger.fine('Next problem is not ready, so cannot start automatically');
      _autoStart.addTime(Duration(milliseconds: 100));
    }
  }

  void _onAutoStartStatusChanged(ControllableTimerStatus newStatus) {
    if (newStatus == ControllableTimerStatus.ended) {
      _startNewRound();
      _logger.info('Automatic start of the round');
    }
  }

  ///
  /// Tick the game timer and the cooldown timer of players. Call the
  /// listeners if needed.
  Future<void> _tickingClock(Duration deltaTime) async {
    _logger.fine('Tic...');

    if (_isRoundAMiniGame || _gameStatus != WordsTrainGameStatus.roundStarted) {
      _logger.fine('The game is not running, so nothing more to do');
      _logger.fine('Toc');
      return;
    }

    final cm = Managers.instance.configuration;

    // Manager players cooling down
    _logger.fine('Managing players cooling down...');
    for (final player in players) {
      if (player.isInCooldownPeriod) {
        _hasAPlayerBeenUpdate = true;
      } else if (_playersWasInCooldownLastFrame[player.name] ?? false) {
        _playersWasInCooldownLastFrame[player.name] = false;
        _hasAPlayerBeenUpdate = true;
      }
    }
    if (_hasAPlayerBeenUpdate) {
      onPlayerUpdate.notifyListeners((callback) => callback());
      _hasAPlayerBeenUpdate = false;
    }

    // Manage golden solution
    _logger.fine('Managing golden solution...');
    if (!_roundHasGoldenSolution &&
        timeRemaining! > cm.goldenSolutionMinimumDuration &&
        ((_random.nextDouble() * deltaTime.inMilliseconds) <
                cm.goldenSolutionProbability ||
            _forceGoldenSolution)) {
      _logger.info('A new golden solution appears');

      // Find one solution that is not found yet and make it golden solution
      int index = -1;
      do {
        if (_currentProblem!.areAllSolutionsFound) {
          // If all solutions are found, we cannot make a golden solution
          // as the round is over
          index = -1;
          break;
        }
        if (_forceGoldenSolution) {
          // When forcing the golden solution, pick a solution with the highest score value
          // that is not found yet. If there is no solution with the highest score,
          // then pick a solution with the next best score that is not found yet until
          // there is no more solution to pick. If there is no solution to pick,
          // then break the loop and do not set a golden solution.
          int highestScore = _currentProblem!.solutions.highestScore;

          while (true) {
            final bestSolutions = _currentProblem!.solutions
                .where((s) => !s.isFound && s.value >= highestScore);
            if (bestSolutions.isEmpty) {
              highestScore -= 1;
              // No more solution to pick, so break
              if (highestScore == 0) break;
              continue;
            }
            final solution =
                bestSolutions.elementAt(_random.nextInt(bestSolutions.length));
            index = _currentProblem!.solutions.indexOf(solution);
            break;
          }
        } else {
          // When normal picking, pick a skewed value towards the best solutions base on gaussian distribution
          index = _random.nextSkewedInt(
            max: _currentProblem!.solutions.length,
            skewTowards: _currentProblem!.solutions.length * 2 ~/ 3,
          );
        }
      } while (_currentProblem!.solutions[index].isFound);

      if (index != -1) {
        _currentProblem!.solutions[index].isGolden = true;
        _roundHasGoldenSolution = true;
        onGoldenSolutionAppeared.notifyListeners(
            (callback) => callback(_currentProblem!.solutions[index]));
      }

      _forceGoldenSolution = false;
    }

    // Manager letter swapping in the problem
    _logger.fine('Managing letter swapping...');
    _scramblingLetterTimer -= deltaTime;
    if (_scramblingLetterTimer <= Duration.zero) {
      _logger.fine('Scrambling letters...');
      _scramblingLetterTimer = cm.timeBeforeScramblingLetters;
      _currentProblem!.scrambleLetters();
      onScrablingLetters.notifyListeners((callback) => callback());
    }

    // Manage useless letter
    _logger.fine('Managing useless letter...');
    if (!_isUselessLetterRevealed &&
        _currentDifficulty.hasUselessLetter &&
        timeRemaining!.inSeconds <=
            _currentDifficulty.revealUselessLetterAtTimeLeft) {
      _logger.info('Revealing useless letter...');
      _isUselessLetterRevealed = true;
      onRevealUselessLetter.notifyListeners((callback) => callback());
    }

    // Manage hidden letter
    _logger.fine('Managing hidden letter...');
    if (!_isHiddenLetterRevealed &&
        _currentDifficulty.hasHiddenLetter &&
        timeRemaining!.inSeconds <=
            _currentDifficulty.revealHiddenLetterAtTimeLeft) {
      _logger.info('Revealing hidden letter...');
      _isHiddenLetterRevealed = true;
      onRevealHiddenLetter.notifyListeners((callback) => callback());
    }

    // Manage if the train got to a new boost
    _logger.fine('Managing if the train got to a new boost...');
    if (!_boostWasGrantedThisRound && _trainHasReachedNewBoost()) {
      _logger.info('Train got a new boost');
      _boostWasGrantedThisRound = true;
      _remainingBoosts += 1;

      // Notify that a new boost was granted. This triggers the message overlay
      // but was decided is a good idea since the boost can be used immediately
      onNewBoostGranted.notifyListeners((callback) => callback());
    }

    // Manage if the train is boosted
    _logger.fine('Managing train boost...');
    if (isTrainBoosted && (trainBoostRemainingTime?.inSeconds ?? -1) <= 0) {
      _logger.info('Train boost ended');
      _boostStartedAt = null;
      onTrainBoostEnded.notifyListeners((callback) => callback());
    }

    _logger.fine('Toc');
  }

  bool _checkForEndOfRound() {
    if (_isRoundAMiniGame) {
      _logger.fine('Mini game is running, so nothing to do unless forced');
      if (_forceEndTheRound) {
        Managers.instance.miniGames.manager?.terminateRound();
        _forceEndTheRound = false;
      }
      return false;
    }
    _logger.fine('Checking for end of round...');

    // Do not end the round if we are not playing
    if (_gameStatus != WordsTrainGameStatus.roundStarted) {
      _logger.fine(
          'Round is not running, so cannot check for end of round at this time');
      return false;
    }

    // End round
    // if the request was made
    // if all the words have been found
    // if the timer has past the timer + the grace period
    // if we are attempting the big heist and it is a success
    final cm = Managers.instance.configuration;
    if (_forceEndTheRound ||
        _currentProblem!.areAllSolutionsFound ||
        ((timeRemaining! + cm.postRoundGracePeriodDuration).inSeconds <= 0) ||
        (_isAttemptingTheBigHeist &&
            _numberOfStarObtained(problem!.teamScore) ==
                SuccessLevel.bigHeist)) {
      _logger.fine('Round is over');
      return true;
    } else {
      _logger.fine('Round is not over yet');
      return false;
    }
  }

  ///
  /// Clear the current round
  Future<void> _endingRound() async {
    _logger.info('Round is over, ending the round...');
    final cm = Managers.instance.configuration;

    // Finishing the round
    _successLevel = _numberOfStarObtained(problem!.teamScore);
    if (_isAttemptingTheBigHeist) {
      if (_successLevel == SuccessLevel.bigHeist) {
        onBigHeistSuccess.notifyListeners((callback) => callback());
      } else {
        onBigHeistFailed.notifyListeners((callback) => callback());
      }
    }
    _gameStatus = WordsTrainGameStatus.roundEnding;
    onRoundIsOver.notifyListeners((callback) => callback());
    _showCaseAnswers();

    // Distribute round successes
    if (_successLevel != SuccessLevel.failed) {
      if (_currentProblem!.teamScore >= _currentProblem!.solutions.totalScore) {
        _roundSuccesses.add(RoundSuccess.maxPoints);
      }
      if (_currentProblem!.areAllSolutionsFound) {
        _roundSuccesses.add(RoundSuccess.foundAll);
      }
      if (_currentProblem!.noSolutionWasStolenOrPardoned) {
        _roundSuccesses.add(RoundSuccess.noSteal);
      }
    }

    // Distribute perks
    if (roundSuccesses.contains(RoundSuccess.noSteal)) {
      _remainingPardons += 1;
      onNewPardonGranted.notifyListeners((callback) => callback());
    }
    if (cm.useMinigames &&
        (roundSuccesses.contains(RoundSuccess.foundAll) ||
            roundSuccesses.contains(RoundSuccess.maxPoints))) {
      handleNextRoundAsMiniGame();
    } else {
      _isNextRoundAMiniGame = false;
      _currentMiniGame = null;
    }

    // Prepare next round
    _previousRoundTimeRemaining = timeRemaining!;
    _forceEndTheRound = false;
    _boostStartedAt = null;
    _canRequestCongratulationFireworks = true;
    _canChangeLane = false;
    _canAttemptTheBigHeist = false;
    _isAttemptingTheBigHeist = false;
    _roundCount += _successLevel.toInt();

    _generateNextProblem(force: false);
    if (_successLevel == SuccessLevel.failed) {
      if (_fixTracksMiniGamesAttempted == 0) {
        _canAttemptFixTracksMiniGame = true;
      }
    } else {
      if (_random.nextDouble() < _currentDifficulty.bigHeistProbability) {
        _canAttemptTheBigHeist = true;
      }
    }

    // Launch the automatic start of the round timer if needed
    if (cm.autoplay) {
      _autoStart.initialize();
      _autoStart.start(
          duration: _successLevel == SuccessLevel.failed
              ? cm.autoplayFailedDuration
              : cm.autoplayDuration);
    }
    // If it is permitted to send the results to the leaderboard, do it
    if (_isAllowedToSendResults) {
      Managers.instance.database.sendResults(
        stationReached: roundCount,
        mvpScore: players.bestPlayersByScore,
        mvpStars: players.bestPlayersByStars,
        mvpSteals: players.biggestStealers,
      );
    }

    _logger.info('Round ended');
  }

  void requestShowCaseAnswers() {
    _logger.info('Requesting to show case answers...');

    if (_gameStatus != WordsTrainGameStatus.roundPreparing) {
      _logger.warning('Cannot show case answers at this time');
      return;
    }
    _showCaseAnswers();
  }

  void _showCaseAnswers() {
    _logger.info('Show casing answers...');

    final cm = Managers.instance.configuration;

    _gameStatus = WordsTrainGameStatus.roundEnding;
    Timer(Duration(seconds: cm.postRoundShowCaseDuration.inSeconds), () {
      onRoundIsPreparing.notifyListeners((callback) => callback());
      _gameStatus = WordsTrainGameStatus.roundPreparing;
    });
    onShowcaseSolutionsRequest.notifyListeners((callback) => callback());

    _logger.info('Answers are shown');
  }

  SuccessLevel _numberOfStarObtained(int score) {
    if (problem == null) return SuccessLevel.failed;

    if (_isAttemptingTheBigHeist) {
      return score >= pointsToObtain(SuccessLevel.threeStars)
          ? SuccessLevel.bigHeist
          : SuccessLevel.failed;
    } else if (score >= pointsToObtain(SuccessLevel.threeStars)) {
      return SuccessLevel.threeStars;
    } else if (score >= pointsToObtain(SuccessLevel.twoStars)) {
      return SuccessLevel.twoStars;
    } else if (score >= pointsToObtain(SuccessLevel.oneStar)) {
      return SuccessLevel.oneStar;
    } else {
      return SuccessLevel.failed;
    }
  }

  int pointsToObtain(SuccessLevel level) {
    final maxScore = problem?.solutions.totalScore ?? 0;
    switch (level) {
      case SuccessLevel.oneStar:
        return (maxScore * _currentDifficulty.thresholdFactorOneStar).toInt();
      case SuccessLevel.twoStars:
        return (maxScore * _currentDifficulty.thresholdFactorTwoStars).toInt();
      case SuccessLevel.threeStars:
      case SuccessLevel.bigHeist:
        return (maxScore * _currentDifficulty.thresholdFactorThreeStars)
            .toInt();
      case SuccessLevel.failed:
        throw Exception('Failed is not a valid level');
    }
  }

  int pointsToObtainBoost() =>
      ((problem?.solutions.totalScore ?? 0) * _currentNewBoostThreshold)
          .toInt();

  bool _trainHasReachedNewBoost() =>
      (problem?.teamScore ?? -1) >= pointsToObtainBoost();

  void handleNextRoundAsMiniGame({MiniGames? forceMinigame}) {
    _isNextRoundAMiniGame = true;
    _currentMiniGame = forceMinigame ?? _selectNextMiniGame();
    onMiniGameGranted
        .notifyListeners((callback) => callback(_currentMiniGame!));
  }

  void handleCancelNextRoundAsMiniGame() {
    _isNextRoundAMiniGame = false;
    _currentMiniGame = null;
    _isAttemptingFixTracksMiniGame = false;
    onFixTracksMiniGameUpdated.notifyListeners((callback) => callback());
  }

  MiniGames? _selectNextMiniGame() {
    return MiniGames.betweenRoundsGames[
        _random.nextInt(MiniGames.betweenRoundsGames.length)];
  }

  void _miniGameEnded() {
    _logger.info('Mini game ended');
    final mgm = Managers.instance.miniGames.manager;
    if (mgm == null) {
      _logger
          .warning('Mini game manager is null, cannot end mini game properly');
      return;
    }

    mgm.onRoundEnded.cancel(_miniGameEnded);
    final playerPoints = Managers.instance.miniGames.getPlayersPoints();

    // Give some perks based on the mini game
    if (mgm.hasWon) {
      // If we played an end of railway mini game successfully, we can retried the
      // failed round. Otherwise, the players get perks
      if (_isAttemptingFixTracksMiniGame) {
        _successLevel = SuccessLevel.oneStar;

        // If we won that mini game, we no longer play the 0th round, but the next as
        // if we had won the previous round. However, in order to save time the 0th round
        // problem is prepared as soon as the game was lost. So we need to override the
        // next problem.
        _generateNextProblem(force: true);
      } else {
        _forceGoldenSolution = true;
        _roundSuccesses.add(RoundSuccess.miniGameWon);

        for (final playerName in playerPoints.keys) {
          final player = players.firstWhereOrAdd(playerName);
          player.score += playerPoints[playerName]!;
        }
      }
    }

    // Reset some flags
    _forceEndTheRound = false;
    _boostStartedAt = null;

    _gameStatus = WordsTrainGameStatus.roundEnding;
    _showCaseAnswers();

    // Launch the automatic start of the round timer if needed
    final cm = Managers.instance.configuration;
    if (cm.autoplay) {
      _autoStart.initialize();
      _autoStart.start(duration: cm.autoplayDuration);
    }

    _isAttemptingFixTracksMiniGame = false;
    _isNextRoundAMiniGame = false;
    _currentMiniGame = null;
    _startNewRound();
  }
}

class WordsTrainGameManagerMock extends WordsTrainGameManager {
  LetterProblemMock? _problemMocker;

  WordsTrainGameManagerMock({
    WordsTrainGameStatus? gameStatus,
    LetterProblemMock? problem,
    List<Player>? players,
    int? roundCount,
    SuccessLevel? successLevel,
    bool shouldAttemptTheBigHeist = false,
    bool shouldChangeLane = false,
    bool isNextRoundAMiniGame = false,
    MiniGames? nextMiniGame,
    bool? forceGoldenSolution,
    bool canRequestCongratulationFireworks = true,
    bool canAttemptTheBigHeist = true,
    bool canAttemptFixTracksMiniGame = true,
  }) : super() {
    if (players != null) {
      for (final player in players) {
        this.players.add(player);
      }
    }

    _canRequestCongratulationFireworks = canRequestCongratulationFireworks;
    _canAttemptTheBigHeist = canAttemptTheBigHeist;
    _canAttemptFixTracksMiniGame = canAttemptFixTracksMiniGame;

    _gameStatus = WordsTrainGameStatus.initializing;
    if (roundCount != null) {
      _roundCount = roundCount;
      _gameStatus = WordsTrainGameStatus.roundPreparing;
    }
    if (successLevel != null) {
      _roundCount += successLevel.toInt();
      _successLevel = successLevel;
    }

    _initializeTrySolutionCallback();
    if (problem == null) {
      _generateNextProblem(force: true);
    } else {
      _problemMocker = problem;
      if (_gameStatus == WordsTrainGameStatus.roundStarted) {
        _currentProblem = problem;
        _nextProblem = null;
      } else {
        _nextProblem = problem;
      }

      Future.delayed(const Duration(seconds: 1)).then((value) =>
          onNextProblemReady.notifyListeners((callback) => callback()));
    }

    if (shouldAttemptTheBigHeist) {
      _canAttemptTheBigHeist = true;
      _attemptTheBigHeist(playerName: 'Anonyme');
    }

    if (shouldChangeLane) {
      Future.delayed(const Duration(seconds: 15))
          .then((_) => _performChangeOfLane());
    }

    if (gameStatus != null) _gameStatus = gameStatus;
    if (gameStatus == WordsTrainGameStatus.roundStarted) {
      _setValuesAtStartRound();
    }

    _previousRoundTimeRemaining = Duration(seconds: 100);
    _isNextRoundAMiniGame = isNextRoundAMiniGame;
    _currentMiniGame = nextMiniGame;
    _forceGoldenSolution = forceGoldenSolution ?? false;

    _asyncInitializations();
  }

  @override
  bool get hasPlayedAtLeastOnce => true;

  @override
  Future<void> _generateNextProblem({required bool force}) async {
    if (_problemMocker == null) {
      await super._generateNextProblem(force: force);
    } else {
      _nextProblem = _problemMocker;
      _isGeneratingProblem = false;

      // Make sure the game don't run if the player is not logged in
      final dm = Managers.instance.database;
      dm.onLoggedOut.listen(() => requestTerminateRound());
      dm.onFullyLoggedIn.listen(() {
        if (gameStatus != WordsTrainGameStatus.initializing) _startNewRound();
      });
    }
    onGameIsInitializing.notifyListeners((callback) => callback());
  }
}
