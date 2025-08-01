import 'dart:async';
import 'dart:math';

import 'package:common/generic/models/exceptions.dart';
import 'package:common/generic/models/game_status.dart';
import 'package:common/generic/models/generic_listener.dart';
import 'package:common/generic/models/mini_games.dart';
import 'package:common/generic/models/serializable_game_state.dart';
import 'package:logging/logging.dart';
import 'package:train_de_mots/generic/managers/managers.dart';
import 'package:train_de_mots/words_train/models/difficulty.dart';
import 'package:train_de_mots/words_train/models/letter_problem.dart';
import 'package:train_de_mots/words_train/models/player.dart';
import 'package:train_de_mots/words_train/models/round_success.dart';
import 'package:train_de_mots/words_train/models/success_level.dart';
import 'package:train_de_mots/words_train/models/word_solution.dart';

final _logger = Logger('GameManager');

extension RandomExtension on Random {
  int nextSkewedInt({
    int min = 0,
    required int max,
    required int skewTowards,
    int stdWidthAdjustment = 6,
  }) {
    assert(min < max);
    assert(skewTowards >= min && skewTowards < max);

    final stdDev =
        (max - min) / stdWidthAdjustment; // Adjust for bell curve width

    double gaussian = nextGaussian() * stdDev + skewTowards;
    return gaussian.round().clamp(min, max - 1);
  }

  double nextGaussian() {
    // Box-Muller transform to generate a standard normal distribution
    final u1 = nextDouble();
    final u2 = nextDouble();
    final z0 = sqrt(-2.0 * log(u1)) * cos(2.0 * pi * u2);
    return z0;
  }
}

class WordsTrainGameManager {
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  final Duration _deltaTime;
  WordsTrainGameManager({deltaTime = const Duration(milliseconds: 1000)})
      : _deltaTime = deltaTime {
    _asyncInitializations();
    Timer.periodic(_deltaTime, _gameLoop);
  }

  Future<void> _asyncInitializations() async {
    _logger.config('Initializing...');

    while (true) {
      try {
        final cm = Managers.instance.configuration;
        cm.onChanged.listen(_checkForInvalidRules);
        break;
      } on ManagerNotInitializedException {
        // Wait and repeat
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }

    // This is triggered if a user sends fireworks to the screen
    onCongratulationFireworks.listen(_requestedFireworks);

    _isInitialized = true;

    _logger.config('Ready');
  }

  /// ---------- ///
  /// GAME LOGIC ///
  /// ---------- ///

  final Players players = Players();

  WordsTrainGameStatus _gameStatus = WordsTrainGameStatus.initializing;
  WordsTrainGameStatus get gameStatus {
    if (!_isRoundAMiniGame) {
      if (_gameStatus == WordsTrainGameStatus.roundPreparing &&
          isNextProblemReady) {
        return WordsTrainGameStatus.roundReady;
      }
      return _gameStatus;
    }

    if (_gameStatus == WordsTrainGameStatus.roundPreparing ||
        _gameStatus == WordsTrainGameStatus.roundReady) {
      return Managers.instance.miniGames.manager?.isReady == false
          ? WordsTrainGameStatus.miniGameReady
          : WordsTrainGameStatus.miniGamePreparing;
    } else if (_gameStatus == WordsTrainGameStatus.roundStarted) {
      return WordsTrainGameStatus.miniGameStarted;
    } else if (_gameStatus == WordsTrainGameStatus.roundEnding) {
      return WordsTrainGameStatus.miniGameEnding;
    }
    return _gameStatus;
  }

  final _random = Random();

  int? _roundDuration;
  Duration? get timeRemaining =>
      _roundDuration == null || _roundStartedSince == null
          ? null
          : Duration(
              seconds: ((_roundDuration! ~/ 1000 - _roundStartedSince!)) -
                  Managers.instance.configuration.postRoundGracePeriodDuration
                      .inSeconds);
  Duration _previousRoundTimeRemaining = Duration.zero;
  Duration get previousRoundTimeRemaining => _previousRoundTimeRemaining;
  int? get _roundStartedSince => _roundStartedAt == null
      ? null
      : (DateTime.now().millisecondsSinceEpoch -
              _roundStartedAt!.millisecondsSinceEpoch) ~/
          1000;
  DateTime? _roundStartedAt;
  DateTime? _nextRoundStartAt;
  Duration? get nextRoundStartIn =>
      _nextRoundStartAt?.difference(DateTime.now());
  void cancelAutomaticStart() {
    _logger.info('Automatic start of the round has been canceled');
    _nextRoundStartAt = null;
  }

  int _roundCount = 0;
  int get roundCount => _roundCount;
  late Difficulty _currentDifficulty =
      Managers.instance.configuration.difficulty(0);

  Duration cooldownDuration({required Player player}) {
    final cm = Managers.instance.configuration;
    return Duration(
        seconds: players.length.clamp(4, cm.cooldownPeriod.inSeconds) +
            cm.cooldownPenaltyAfterSteal.inSeconds * player.roundStealCount);
  }

  int _scramblingLetterTimer = 0;

  LetterProblem? _currentProblem;
  final List<LetterProblem> _playedProblems = [];
  LetterProblem? _nextProblem;
  bool _isGeneratingProblem = false;
  bool get isNextProblemReady =>
      (!_isGeneratingProblem && _nextProblem != null);
  bool get canProceedToNextRound => isNextProblemReady || _isNextRoundAMiniGame;

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
    return cm.numberOfBoostRequestsNeeded - _requestedBoost.length;
  }

  bool _canAttemptTheBigHeist = false;
  bool get canAttemptTheBigHeist => _canAttemptTheBigHeist;
  bool _isAttemptingTheBigHeist = false;
  bool get isAttemptingTheBigHeist => _isAttemptingTheBigHeist;

  bool _isNextRoundAMiniGame = false;
  bool get isNextRoundAMiniGame => _isNextRoundAMiniGame;
  bool _isRoundAMiniGame = false;
  bool get isRoundAMiniGame => _isRoundAMiniGame;
  MiniGames? _currentMiniGame;

  bool _areCongratulationFireworksFiring = false;

  /// ----------- ///
  /// CONSTRUCTOR ///
  /// ----------- ///

  /// ----------- ///
  /// INTERACTION ///
  /// ----------- ///

  ///
  /// Provide a way to request the start of a new round, if the game is not
  /// already started or if the game is not already over.
  Future<void> requestStartNewRound() async {
    _logger.info('Requesting to start a new round');
    _startNewRound();
  }

  ///
  /// Provide a way to request the search for the next problem, if the game is
  /// not already searching for a problem.
  Future<void> requestSearchForNextProblem() async {
    _logger.info('Requesting to search for the next problem');

    final cm = Managers.instance.configuration;
    _generateNextProblem(
        maxSearchingTime:
            Duration(seconds: cm.autoplayDuration.inSeconds ~/ 2));
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
  final onClockTicked = GenericListener<Function()>();
  final onScrablingLetters = GenericListener<Function()>();
  final onRevealUselessLetter = GenericListener<Function()>();
  final onRevealHiddenLetter = GenericListener<Function()>();
  final onSolutionFound = GenericListener<Function(WordSolution)>();
  final onSolutionWasStolen = GenericListener<Function(WordSolution)>();
  final onGoldenSolutionAppeared = GenericListener<Function(WordSolution)>();
  final onStealerPardoned = GenericListener<Function(WordSolution?)>();
  final onNewPardonGranted = GenericListener<Function()>();
  final onNewBoostGranted = GenericListener<Function()>();
  final onTrainGotBoosted = GenericListener<Function(int)>();
  final onAttemptingTheBigHeist = GenericListener<Function()>();
  final onBigHeistSuccess = GenericListener<Function()>();
  final onBigHeistFailed = GenericListener<Function()>();
  final onChangingLane = GenericListener<Function()>();
  final onAllSolutionsFound = GenericListener<Function()>();
  final onShowcaseSolutionsRequest = GenericListener<Function()>();
  final onPlayerUpdate = GenericListener<Function()>();
  final onCongratulationFireworks =
      GenericListener<Function(Map<String, dynamic>)>();
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

      final cm = Managers.instance.configuration;
      _generateNextProblem(
          maxSearchingTime: timeRemaining ??
              Duration(seconds: cm.autoplayDuration.inSeconds ~/ 2));
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
    _logger.info('Checking for invalid rules...');
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

  Future<void> _generateNextProblem(
      {required Duration maxSearchingTime}) async {
    final round = _successLevel == SuccessLevel.failed ? 0 : roundCount;
    _logger.info('Generating for next problem (round $round...)');

    if (_isGeneratingProblem) {
      _logger.warning('Already searching for a problem');
      return;
    }

    _nextProblem = null;
    _isGeneratingProblem = true;

    final cm = Managers.instance.configuration;
    _forceRepickProblem = false;

    LetterProblem? problem;
    final difficulty = cm.difficulty(round);
    while (problem == null) {
      problem = await cm.problemGenerator(
          nbLetterInSmallestWord: difficulty.nbLettersOfShortestWord,
          minLetters: difficulty.nbLettersMinToDraw,
          maxLetters: difficulty.nbLettersMaxToDraw,
          minimumNbOfWords: cm.minimumWordsNumber,
          maximumNbOfWords: cm.maximumWordsNumber,
          addUselessLetter: difficulty.hasUselessLetter,
          maxSearchingTime: maxSearchingTime);

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

    if (_gameStatus == WordsTrainGameStatus.initializing) {
      _initializeCallbacks();
    }

    if (_gameStatus != WordsTrainGameStatus.roundPreparing) {
      _logger.warning('Cannot start a new round at this time');
      return;
    }

    onRoundIsPreparing.notifyListeners((callback) => callback());
    if (_isNextRoundAMiniGame) {
      _logger.info('Preparing the mini game $_currentMiniGame...');
      _isRoundAMiniGame = true;
      _isNextRoundAMiniGame = false;

      Managers.instance.miniGames.initialize(_currentMiniGame!);
      final mgm = Managers.instance.miniGames.manager!;
      while (!mgm.isReady) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      mgm.onGameEnded.listen(_miniGameEnded);
      _roundSuccesses.clear();
      mgm.start();
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
    }

    // Start the round
    await _sendTelegramToPlayers();
    _gameStatus = WordsTrainGameStatus.roundStarted;

    _roundStartedAt = DateTime.now();
    onRoundStarted.notifyListeners((callback) => callback());

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
    _roundDuration = cm.roundDuration.inMilliseconds +
        cm.postRoundGracePeriodDuration.inMilliseconds;
    for (final player in players) {
      player.resetForNextRound();
    }

    _roundHasGoldenSolution = false;
    _hasPlayedAtLeastOnce = true;
    _isUselessLetterRevealed = false;
    _isHiddenLetterRevealed = false;
    _nextRoundStartAt = null;
    _scramblingLetterTimer = cm.timeBeforeScramblingLetters.inSeconds;

    // Transfer the next problem to the current problem
    if (_currentProblem != null) _playedProblems.add(_currentProblem!);
    _currentProblem = _nextProblem;

    // Reset the round successes
    _successLevel = SuccessLevel.threeStars;
    _roundSuccesses.clear();
    _lastStolenSolution = null;

    _boostStartedAt = null;
    _requestedBoost.clear();

    // We can only attempt the big heist during the pause
    _canAttemptTheBigHeist = false;

    _logger.info('Values set at the start of the round');
  }

  ///
  /// Initialize the callbacks from Twitch chat to [_trySolution]
  Future<void> _initializeTrySolutionCallback() async =>
      Managers.instance.twitch
          .addChatListener((sender, message) => _trySolution(sender, message));

  ///
  /// Try to solve the problem from a [message] sent by a [sender], that is a
  /// Twitch chatter.
  Future<void> _trySolution(String sender, String message) async {
    if (_isRoundAMiniGame) {
      _logger.warning('Cannot try solution while playing a mini game');
      return;
    }

    _logger.info('Trying solution from $sender: $message');

    if (problem == null || timeRemaining == null) {
      _logger.warning('Cannot try solution at this time');
      return;
    }
    final cm = Managers.instance.configuration;

    // Get the player from the players list
    final player = players.firstWhereOrAdd(sender);

    // Can get a little help from the controller of the train
    if (cm.canUseControllerHelper) {
      if (message == '!pardon') {
        _logger.info('Trying to pardon the last stealer');
        pardonLastStealer(pardonner: player);
        return;
      } else if (message == '!boost') {
        _logger.info('Trying to boost the train');
        boostTrain(player: player);
        return;
      }
    }

    // If the player is in cooldown, they are not allowed to answer
    if (player.isInCooldownPeriod) {
      _logger.warning('Solution is invalid because player is in cooldown');
      return;
    }

    // Find if the proposed word is valid
    final solution = problem!.trySolution(message,
        nbLetterInSmallestWord: _currentDifficulty.nbLettersOfShortestWord);
    if (solution == null) {
      _logger.warning('Solution is invalid because it is not a valid word');
      return;
    }

    // Add to player score
    _logger.info('Solution is valid');
    if (solution.isFound) {
      _logger.info('Solution is valid, but was already found');
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
      onSolutionWasStolen.notifyListeners((callback) => callback(solution));
    }

    player.score += solution.value;
    if (solution.isGolden) player.starsCollected++;

    player.startCooldown(duration: cooldownDuration(player: player));

    // Call the listeners of solution found
    onSolutionFound.notifyListeners((callback) => callback(solution));

    // Also plan for an call to the listeners of players on next game loop
    _hasAPlayerBeenUpdate = true;
    _playersWasInCooldownLastFrame[player.name] = true;

    _logger.info('Solution found');
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

  bool requestTheBigHeist() {
    _logger.info('Requesting the big heist...');
    if (!_canAttemptTheBigHeist) {
      _logger.warning('Big heist cannot be attempted');
      return false;
    }

    _canAttemptTheBigHeist = false;
    _isAttemptingTheBigHeist = true;
    onAttemptingTheBigHeist.notifyListeners((callback) => callback());

    _logger.info('Big heist is attempted');
    return true;
  }

  bool requestChangeOfLane() {
    _logger.info('Requesting the change of lane...');

    if (gameStatus != WordsTrainGameStatus.roundStarted) {
      _logger.warning('Cannot change lane at this time');
      return false;
    }

    _performChangeOfLane();
    return true;
  }

  Future<void> _performChangeOfLane() async {
    // Perform a huge scramble of the letters
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
  }

  void _requestedFireworks(info) {
    _areCongratulationFireworksFiring =
        (info['is_congratulating'] as bool?) ?? false;
  }

  ///
  /// Restart the game by resetting the players and the round count
  void _restartGame() {
    _logger.info('Restarting the game...');

    final cm = Managers.instance.configuration;

    _roundCount = 0;
    _currentDifficulty = cm.difficulty(_roundCount);
    _isAllowedToSendResults = !cm.useCustomAdvancedOptions;

    _remainingPardons = cm.numberOfPardons;
    _remainingBoosts = cm.numberOfBoosts;

    // We can never attempt the big heist at the start
    _canAttemptTheBigHeist = false;
    _isAttemptingTheBigHeist = false;

    // There is no mini game at the start
    _isNextRoundAMiniGame = false;
    _isRoundAMiniGame = false;
    _currentMiniGame = null;
    _forceGoldenSolution = false;

    players.clear();

    _logger.info('Game restarted');
  }

  ///
  /// Tick the game timer. If the timer is over, [_endingRound] is called.
  void _gameLoop(Timer timer) async {
    _logger.fine('Game looping...');

    _tickingClock();
    if (_checkIfShouldAutomaticallyStartRound()) _autoStartingRound();
    if (_checkForEndOfRound()) _endingRound();

    _logger.fine('Game looped');
  }

  bool _checkIfShouldAutomaticallyStartRound() {
    _logger.fine('Checking if the round should start automatically...');

    if (_nextRoundStartAt == null) {
      _logger.fine('No automatic start of the round planned');
      return false;
    }
    if (_areCongratulationFireworksFiring) {
      _nextRoundStartAt = _nextRoundStartAt!.add(_deltaTime);
      return false;
    }
    if (_gameStatus != WordsTrainGameStatus.roundPreparing) {
      _logger.fine('Round is not preparing, so cannot start automatically');
      return false;
    }
    if (!isNextProblemReady) {
      _logger.fine('Next problem is not ready, so cannot start automatically');
      return false;
    }
    if (DateTime.now().isBefore(_nextRoundStartAt!)) {
      _logger.fine(
          'Next round start is in the future, so cannot start automatically');
      return false;
    }

    _logger.fine('Automatic start');
    return true;
  }

  void _autoStartingRound() {
    _logger.info('Automatic start of the round');
    _nextRoundStartAt = null;
    _startNewRound();
  }

  ///
  /// Tick the game timer and the cooldown timer of players. Call the
  /// listeners if needed.
  Future<void> _tickingClock() async {
    _logger.fine('Tic...');
    onClockTicked.notifyListeners((callback) => callback());

    if (_gameStatus != WordsTrainGameStatus.roundStarted ||
        timeRemaining == null) {
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
        (_random.nextDouble() < cm.goldenSolutionProbability ||
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
          // and that is not found yet. If there is no solution with the highest score,
          // then pick a solution with the next best score that is not found yet until
          // there is no more solution to pick. If there is no solution to pick,
          // then break the loop and do not set a golden solution.
          int highestScore = _currentProblem!.solutionWithHighestScore;

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
    _scramblingLetterTimer -= 1;
    if (_scramblingLetterTimer <= 0) {
      _logger.info('Scrambling letters...');
      _scramblingLetterTimer = cm.timeBeforeScramblingLetters.inSeconds;
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

    // Manage boost of the train
    _logger.fine('Managing train boost...');
    if (isTrainBoosted && (trainBoostRemainingTime?.inSeconds ?? -1) <= 0) {
      _logger.info('Train boost ended');
      _boostStartedAt = null;
    }

    _logger.fine('Toc');
  }

  bool _checkForEndOfRound() {
    if (_isRoundAMiniGame) {
      _logger.fine('Mini game is running, so nothing to do unless forced');
      if (_forceEndTheRound) {
        Managers.instance.miniGames.manager?.end();
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

    _successLevel = _numberOfStarObtained(problem!.teamScore);
    _roundCount += _successLevel.toInt();
    _currentDifficulty = cm.difficulty(_roundCount);

    Managers.instance.database.sendLetterProblem(problem: _currentProblem!);
    _generateNextProblem(maxSearchingTime: cm.autoplayDuration * 3 ~/ 4);

    _previousRoundTimeRemaining = timeRemaining!;
    _forceEndTheRound = false;
    _roundDuration = null;
    _roundStartedAt = null;
    _boostStartedAt = null;
    if (_isAttemptingTheBigHeist) {
      if (_successLevel == SuccessLevel.bigHeist) {
        onBigHeistSuccess.notifyListeners((callback) => callback());
      } else {
        onBigHeistFailed.notifyListeners((callback) => callback());
      }
    }
    _isAttemptingTheBigHeist = false;

    if (_currentProblem!.teamScore >= _currentProblem!.maximumPossibleScore) {
      _roundSuccesses.add(RoundSuccess.maxPoints);
      _remainingBoosts += 1;
      onNewBoostGranted.notifyListeners((callback) => callback());
    }

    if (_currentProblem!.noSolutionWasStolenOrPardoned &&
        _successLevel != SuccessLevel.failed) {
      _roundSuccesses.add(RoundSuccess.noSteal);
      _remainingPardons += 1;
      onNewPardonGranted.notifyListeners((callback) => callback());
    }

    _canAttemptTheBigHeist = false;
    if (_successLevel != SuccessLevel.failed) {
      if (_random.nextDouble() < _currentDifficulty.bigHeistProbability) {
        _canAttemptTheBigHeist = true;
      }
    }

    // Select the mini game to play if allowed
    _isNextRoundAMiniGame = false;
    _currentMiniGame = null;
    if (_currentProblem!.areAllSolutionsFound) {
      _roundSuccesses.add(RoundSuccess.foundAll);
      _isNextRoundAMiniGame = true;
      _currentMiniGame = MiniGames.treasureHunt;
      onAllSolutionsFound.notifyListeners((callback) => callback());
    }

    _gameStatus = WordsTrainGameStatus.roundEnding;
    onRoundIsOver.notifyListeners((callback) => callback());
    _showCaseAnswers();

    // Launch the automatic start of the round timer if needed
    if (cm.autoplay) {
      _nextRoundStartAt = DateTime.now()
          .add(cm.autoplayDuration + cm.postRoundShowCaseDuration);
    }

    // If it is permitted to send the results to the leaderboard, do it
    if (_isAllowedToSendResults) {
      Managers.instance.database.sendResults(
          stationReached: roundCount,
          mvpScore: players.bestPlayersByScore,
          mvpStars: players.bestPlayersByStars);
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
    final maxScore = problem?.maximumPossibleScore ?? 0;
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

  void _miniGameEnded(bool hasWon) {
    _logger.info('Mini game ended');
    Managers.instance.miniGames.manager?.onGameEnded.cancel(_miniGameEnded);
    Managers.instance.miniGames.finalize();

    // Give some perks based on the mini game
    if (hasWon) {
      _forceGoldenSolution = true;
      _roundSuccesses.add(RoundSuccess.miniGameWon);
    }

    // Reset some flags
    _forceEndTheRound = false;
    _roundDuration = null;
    _roundStartedAt = null;
    _boostStartedAt = null;

    _gameStatus = WordsTrainGameStatus.roundEnding;
    _showCaseAnswers();

    // Launch the automatic start of the round timer if needed
    final cm = Managers.instance.configuration;
    if (cm.autoplay) {
      _nextRoundStartAt = DateTime.now()
          .add(cm.autoplayDuration + cm.postRoundShowCaseDuration);
    }

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
  }) : super(deltaTime: Duration(milliseconds: 100)) {
    if (players != null) {
      for (final player in players) {
        this.players.add(player);
      }
    }

    _gameStatus = WordsTrainGameStatus.initializing;
    if (roundCount != null) {
      _roundCount = roundCount;
      _gameStatus = WordsTrainGameStatus.roundPreparing;
    }
    if (successLevel != null) {
      _roundCount += successLevel.toInt();
      _successLevel = successLevel;
    }
    _currentDifficulty =
        Managers.instance.configuration.difficulty(roundCount!);

    _initializeTrySolutionCallback();
    if (problem == null) {
      _generateNextProblem(maxSearchingTime: Duration.zero);
    } else {
      _problemMocker = problem;
      _currentProblem = problem;
      _nextProblem = null;

      Future.delayed(const Duration(seconds: 1)).then((value) =>
          onNextProblemReady.notifyListeners((callback) => callback()));
    }

    if (shouldAttemptTheBigHeist) {
      _canAttemptTheBigHeist = true;
      requestTheBigHeist();
    }

    if (shouldChangeLane) {
      Future.delayed(const Duration(seconds: 15))
          .then((_) => requestChangeOfLane());
    }

    if (gameStatus != null) _gameStatus = gameStatus;
    if (gameStatus == WordsTrainGameStatus.roundStarted) {
      _setValuesAtStartRound();
    }

    _previousRoundTimeRemaining = Duration(seconds: 100);
    _isNextRoundAMiniGame = isNextRoundAMiniGame;
    _currentMiniGame = nextMiniGame;

    _asyncInitializations();
  }

  @override
  bool get hasPlayedAtLeastOnce => true;

  @override
  Future<void> _generateNextProblem(
      {required Duration maxSearchingTime}) async {
    if (_problemMocker == null) {
      await super._generateNextProblem(maxSearchingTime: maxSearchingTime);
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
