import 'dart:async';

import 'package:common/models/ebs_helpers.dart';
import 'package:common/models/simplified_game_state.dart';
import 'package:logging/logging.dart';
import 'package:train_de_mots/generic/managers/managers.dart';
import 'package:train_de_mots/words_train/models/word_solution.dart';
import 'package:twitch_manager/twitch_ebs.dart';
import 'package:common/models/exceptions.dart';

final _logger = Logger('EbsServerManager');

class EbsServerManager extends TwitchAppManagerAbstract {
  EbsServerManager._({required super.ebsUri});

  ///
  /// Initialize the EbsServerManager establishing a connection with the
  /// EBS server if [ebsUri] is provided.
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  static Future<EbsServerManager> factory({required Uri ebsUri}) async {
    final instance = EbsServerManager._(ebsUri: ebsUri);
    instance._startListeningToTwich();
    instance.onEbsHasConnected.listen(instance._listenToGameManagerCallbacks);
    instance.onEbsHasDisconnected.listen(instance._disposeListeners);
    return instance;
  }

  Future<void> _startListeningToTwich() async {
    while (true) {
      try {
        final tm = Managers.instance.twitch;
        tm.onTwitchManagerHasConnected.listen(_twitchManagerHasConnected);
        break;
      } on ManagerNotInitializedException {
        // Retry until the manager is initialized
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }

    _isInitialized = true;
    _logger.info('EbsServerManager initialized');
  }

  void _twitchManagerHasConnected() {
    Managers.instance.twitch.onTwitchManagerHasConnected
        .cancel(_twitchManagerHasConnected);

    connect(Managers.instance.twitch.broadcasterId);
  }

  void _listenToGameManagerCallbacks() {
    // Connect the listeners to the GameManager
    final gm = Managers.instance.train;
    gm.onRoundStarted.listen(_sendGameStateToEbs);
    gm.onRoundIsOver.listen(_sendGameStateToEbssWithParameter);
    gm.onStealerPardoned.listen(_sendGameStateToEbssWithParameter);
    gm.onSolutionFound.listen(_sendCooldownToEbs);
    gm.onSolutionWasStolen.listen(_sendCooldownToEbs);
    gm.onRoundIsOver.listen(_sendGameStateToEbssWithParameter);
    gm.onAttemptingTheBigHeist.listen(_sendGameStateToEbs);
    gm.onScrablingLetters.listen(_sendGameStateToEbs);
    gm.onRevealUselessLetter.listen(_sendGameStateToEbs);
    gm.onRevealHiddenLetter.listen(_sendGameStateToEbs);

    final cm = Managers.instance.configuration;
    cm.onShowExtensionChanged.listen(_sendGameStateToEbs);

    // Check if we need to send something to the EBS server at each tick
    //gm.onClockTicked.listen(_sendGameStateToEbs);

    _sendGameStateToEbs();
  }

  ///
  /// Dispose the EbsServerManager by closing the connection with the
  /// EBS server.
  void _disposeListeners() {
    final gm = Managers.instance.train;
    gm.onRoundStarted.cancel(_sendGameStateToEbs);
    gm.onRoundIsOver.cancel(_sendGameStateToEbssWithParameter);
    gm.onStealerPardoned.cancel(_sendGameStateToEbssWithParameter);
    gm.onSolutionFound.cancel(_sendCooldownToEbs);
    gm.onSolutionWasStolen.cancel(_sendCooldownToEbs);
    gm.onRoundIsOver.cancel(_sendGameStateToEbssWithParameter);
    gm.onAttemptingTheBigHeist.cancel(_sendGameStateToEbs);
    gm.onScrablingLetters.cancel(_sendGameStateToEbs);
    gm.onRevealUselessLetter.cancel(_sendGameStateToEbs);
    gm.onRevealHiddenLetter.cancel(_sendGameStateToEbs);
    //gm.onClockTicked.cancel(_sendGameStateToEbs);

    final cm = Managers.instance.configuration;
    cm.onShowExtensionChanged.cancel(_sendGameStateToEbs);
  }

  ///
  /// Request a new letter problem, it will return a completer that will complete
  /// when the EBS server sends the new letter problem. Note requesting twice will
  /// result in undefined behavior.
  Future<Map<String, dynamic>> generateLetterProblem({
    required int nbLetterInSmallestWord,
    required int minLetters,
    required int maxLetters,
    required int minimumNbOfWords,
    required int maximumNbOfWords,
    required bool addUselessLetter,
    required Duration maxSearchingTime,
  }) async {
    // Create a new completer with a timout of maxSearchingTime

    _logger.info('Requesting a new letter problem to EBS server');
    final response = sendQuestionToEbs(
      MessageProtocol(
        to: MessageTo.ebs,
        from: MessageFrom.app,
        type: MessageTypes.get,
        data: {
          'type': ToBackendMessages.newLetterProblemRequest.name,
          'configuration': {
            'algorithm': 'fromRandomWord',
            'lengthShortestSolutionMin': nbLetterInSmallestWord,
            'lengthShortestSolutionMax': nbLetterInSmallestWord,
            'lengthLongestSolutionMin': minLetters,
            'lengthLongestSolutionMax': maxLetters,
            'nbSolutionsMin': minimumNbOfWords,
            'nbSolutionsMax': maximumNbOfWords,
            'nbUselessLetters': addUselessLetter ? 1 : 0,
            'timeout': maxSearchingTime.inSeconds,
          }
        },
      ),
    );

    final message = await response.timeout(maxSearchingTime, onTimeout: () {
      _logger
          .severe('Failed to get a new letter problem from EBS server in time');
      throw TimeoutException('Failed to get a new letter problem in time');
    });

    return message.data!['letter_problem'];
  }

  Future<void> _sendCooldownToEbs(WordSolution solution) async {
    _sendGameStateToEbs(newCooldowns: {
      solution.foundBy.name: solution.foundBy.cooldownDuration
    });
  }

  ///
  /// Get a simplified version of the GameState
  SimplifiedGameState simplifiedGameState(
      {Map<String, Duration> newCooldowns = const {}}) {
    final cm = Managers.instance.configuration;
    final gm = Managers.instance.train;

    return SimplifiedGameState(
      status: gm.gameStatus,
      round: gm.roundCount,
      isRoundSuccess: gm.successLevel.toInt() > 0,
      timeRemaining: Duration(seconds: gm.timeRemaining ?? 0),
      newCooldowns: newCooldowns,
      letterProblem: gm.simplifiedProblem,
      pardonRemaining: gm.remainingPardon,
      pardonners: [gm.lastStolenSolution?.stolenFrom.name ?? ''],
      boostRemaining: gm.remainingBoosts,
      boostStillNeeded: gm.numberOfBoostStillNeeded,
      boosters: gm.requestedBoost.map((e) => e.name).toList(),
      canAttemptTheBigHeist: gm.canAttemptTheBigHeist,
      isAttemptingTheBigHeist: gm.isAttemptingTheBigHeist,
      configuration: SimplifiedConfiguration(showExtension: cm.showExtension),
    );
  }

  Future<void> _sendGameStateToEbs(
          {Map<String, Duration> newCooldowns = const {}}) async =>
      sendMessageToEbs(MessageProtocol(
          to: MessageTo.frontend,
          from: MessageFrom.app,
          type: MessageTypes.put,
          data: {
            'type': ToFrontendMessages.gameState.name,
            'game_state':
                simplifiedGameState(newCooldowns: newCooldowns).serialize(),
          }));

  ///
  /// Send a message to the EBS server to notify that a round has ended
  Future<void> _sendGameStateToEbssWithParameter(_) async =>
      _sendGameStateToEbs();

  @override
  Future<void> handleGetRequest(MessageProtocol message) async {
    try {
      final gm = Managers.instance.train;

      switch (ToAppMessages.values.byName(message.data!['type'])) {
        case ToAppMessages.gameStateRequest:
          sendResponseToEbs(message.copyWith(
              to: MessageTo.frontend,
              from: MessageFrom.app,
              type: MessageTypes.response,
              isSuccess: true,
              data: {
                'type': ToFrontendMessages.gameState.name,
                'game_state': simplifiedGameState().serialize(),
              }));
          break;

        case ToAppMessages.pardonRequest:
          final playerName = message.data!['player_name'] as String;
          final player = gm.players.firstWhereOrAdd(playerName);

          sendResponseToEbs(message.copyWith(
              to: MessageTo.frontend,
              from: MessageFrom.app,
              type: MessageTypes.response,
              isSuccess: gm.pardonLastStealer(pardonner: player)));
          break;

        case ToAppMessages.boostRequest:
          final playerName = message.data!['player_name'] as String;
          final player = gm.players.firstWhereOrAdd(playerName);

          sendResponseToEbs(message.copyWith(
              to: MessageTo.frontend,
              from: MessageFrom.app,
              type: MessageTypes.response,
              isSuccess: gm.boostTrain(player: player)));
          break;

        case ToAppMessages.fireworksRequest:
          final playerName = message.data!['player_name'] as String;
          sendResponseToEbs(message.copyWith(
              to: MessageTo.frontend,
              from: MessageFrom.app,
              type: MessageTypes.response,
              isSuccess: true));
          gm.onCongratulationFireworks.notifyListeners((callback) =>
              callback({'player_name': playerName, 'is_congratulating': true}));
          break;

        case ToAppMessages.attemptTheBigHeist:
          sendResponseToEbs(message.copyWith(
              to: MessageTo.frontend,
              from: MessageFrom.app,
              type: MessageTypes.response,
              isSuccess: gm.requestTheBigHeist()));
          break;

        case ToAppMessages.changeLaneRequest:
          sendResponseToEbs(message.copyWith(
              to: MessageTo.frontend,
              from: MessageFrom.app,
              type: MessageTypes.response,
              isSuccess: gm.requestChangeOfLane()));
          break;

        case ToAppMessages.bitsRedeemed:
          throw UnimplementedError(
              'Bits redeemed should be handled by the EBS and rerouted properly');
      }
    } catch (e) {
      _logger.severe('Error while handling message from EBS: $e');
      sendResponseToEbs(message.copyWith(
          to: MessageTo.frontend,
          from: MessageFrom.app,
          type: MessageTypes.response,
          isSuccess: false));
    }
  }

  @override
  Future<void> handlePutRequest(MessageProtocol message) {
    // There is currently no put request to handle
    throw UnimplementedError();
  }
}
