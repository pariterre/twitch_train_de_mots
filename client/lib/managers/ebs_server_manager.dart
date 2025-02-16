import 'dart:async';

import 'package:common/models/ebs_helpers.dart';
import 'package:common/models/simplified_game_state.dart';
import 'package:logging/logging.dart';
import 'package:train_de_mots/managers/configuration_manager.dart';
import 'package:train_de_mots/managers/game_manager.dart';
import 'package:train_de_mots/managers/twitch_manager.dart';
import 'package:train_de_mots/models/word_solution.dart';
import 'package:twitch_manager/twitch_ebs.dart';

final _logger = Logger('EbsServerManager');

class EbsServerManager extends TwitchAppManagerAbstract {
  SimplifiedGameState? _simplifiedStateToSend;
  Map<String, Duration> _cooldowns = {};

  // Singleton
  static EbsServerManager get instance {
    if (_instance == null) {
      throw Exception(
          'EbsServerManager not initialized, call initialize() first');
    }
    return _instance!;
  }

  static EbsServerManager? _instance;
  EbsServerManager._internal({required super.ebsUri}) {
    TwitchManager.instance.onTwitchManagerHasConnected
        .addListener(_twitchManagerHasConnected);

    onEbsHasConnected.listen(listenToGameManagerCallbacks);
    onEbsHasDisconnected.listen(disposeListeners);
  }

  void _twitchManagerHasConnected() {
    TwitchManager.instance.onTwitchManagerHasConnected
        .removeListener(_twitchManagerHasConnected);

    connect(TwitchManager.instance.broadcasterId);
  }

  ///
  /// Initialize the TrainDeMotsEbsManager establishing a connection with the
  /// EBS server if [ebsUri] is provided.
  static Future<void> initialize({required Uri? ebsUri}) async {
    if (_instance != null) return;

    _instance = EbsServerManager._internal(ebsUri: ebsUri);
  }

  void listenToGameManagerCallbacks() {
    // Connect the listeners to the GameManager
    final gm = GameManager.instance;
    gm.onRoundStarted.addListener(_prepareGameStateToSendToEbs);
    gm.onRoundIsOver.addListener(_prepareGameStateToSendToEbsWithParameter);
    gm.onStealerPardoned.addListener(_prepareGameStateToSendToEbsWithParameter);
    gm.onSolutionFound.addListener(_addCooldown);
    gm.onSolutionWasStolen.addListener(_addCooldown);
    gm.onRoundIsOver.addListener(_prepareGameStateToSendToEbsWithParameter);
    gm.onAttemptingTheBigHeist.addListener(_prepareGameStateToSendToEbs);
    gm.onScrablingLetters.addListener(_prepareGameStateToSendToEbs);
    gm.onRevealUselessLetter.addListener(_prepareGameStateToSendToEbs);
    gm.onRevealHiddenLetter.addListener(_prepareGameStateToSendToEbs);

    final cm = ConfigurationManager.instance;
    cm.onShowExtensionChanged.addListener(_prepareGameStateToSendToEbs);

    // Check if we need to send something to the EBS server at each tick
    gm.onClockTicked.addListener(_sendGameStateToEbs);

    _prepareGameStateToSendToEbs();
    _sendGameStateToEbs();
  }

  ///
  /// Dispose the TrainDeMotsEbsManager by closing the connection with the
  /// EBS server.
  void disposeListeners() {
    final gm = GameManager.instance;
    gm.onRoundStarted.removeListener(_prepareGameStateToSendToEbs);
    gm.onRoundIsOver.removeListener(_prepareGameStateToSendToEbsWithParameter);
    gm.onStealerPardoned
        .removeListener(_prepareGameStateToSendToEbsWithParameter);
    gm.onSolutionFound.removeListener(_addCooldown);
    gm.onSolutionWasStolen.removeListener(_addCooldown);
    gm.onRoundIsOver.removeListener(_prepareGameStateToSendToEbsWithParameter);
    gm.onAttemptingTheBigHeist.removeListener(_prepareGameStateToSendToEbs);
    gm.onScrablingLetters.removeListener(_prepareGameStateToSendToEbs);
    gm.onRevealUselessLetter.removeListener(_prepareGameStateToSendToEbs);
    gm.onRevealHiddenLetter.removeListener(_prepareGameStateToSendToEbs);
    gm.onClockTicked.removeListener(_sendGameStateToEbs);

    final cm = ConfigurationManager.instance;
    cm.onShowExtensionChanged.removeListener(_prepareGameStateToSendToEbs);
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
        from: MessageFrom.app,
        to: MessageTo.ebsIsolated,
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

    final problem = await response.timeout(maxSearchingTime, onTimeout: () {
      _logger
          .severe('Failed to get a new letter problem from EBS server in time');
      throw TimeoutException('Failed to get a new letter problem in time');
    });

    return (problem as MessageProtocol).data!['letter_problem'];
  }

  Future<void> _addCooldown(WordSolution solution) async {
    _cooldowns[solution.foundBy.name] = solution.foundBy.cooldownDuration;
    _prepareGameStateToSendToEbs();
  }

  ///
  /// Send a message to the EBS server to notify that the state of the game has
  /// changed.
  Future<void> _prepareGameStateToSendToEbs() async {
    final cm = ConfigurationManager.instance;
    final gm = GameManager.instance;

    _simplifiedStateToSend ??= SimplifiedGameState(
      status: gm.gameStatus,
      round: gm.roundCount,
      isRoundSuccess: gm.successLevel.toInt() > 0,
      timeRemaining: Duration(seconds: gm.timeRemaining ?? 0),
      newCooldowns: _cooldowns,
      letterProblem: gm.simplifiedProblem,
      pardonRemaining: gm.remainingPardon,
      pardonners: [gm.lastStolenSolution?.stolenFrom.name ?? ''],
      boostRemaining: gm.remainingBoosts,
      boostStillNeeded: gm.numberOfBoostStillNeeded,
      boosters: gm.requestedBoost.map((e) => e.name).toList(),
      canAttemptTheBigHeist: gm.canAttemptTheBigHeist,
      isAttemptingTheBigHeist: gm.isAttemptingTheBigHeist,
      configuration: SimplifiedConfiguration(hideExtension: !cm.showExtension),
    );
  }

  Future<void> _sendGameStateToEbs() async {
    if (_simplifiedStateToSend == null) return;

    sendMessageToEbs(MessageProtocol(
        from: MessageFrom.app,
        to: MessageTo.pubsub,
        type: MessageTypes.put,
        data: {
          'type': ToFrontendMessages.gameState.name,
          'game_state': _simplifiedStateToSend!.serialize(),
        }));

    _simplifiedStateToSend = null;
    _cooldowns = {};
  }

  ///
  /// Send a message to the EBS server to notify that a round has ended
  Future<void> _prepareGameStateToSendToEbsWithParameter(_) async =>
      _prepareGameStateToSendToEbs();

  @override
  Future<void> handleGetRequest(MessageProtocol message) async {
    try {
      final gm = GameManager.instance;

      switch (ToAppMessages.values.byName(message.data!['type'])) {
        case ToAppMessages.gameStateRequest:
          _prepareGameStateToSendToEbs();
          break;

        case ToAppMessages.pardonRequest:
          final playerName = message.data!['player_name'] as String;
          final player = gm.players.firstWhereOrAdd(playerName);

          sendMessageToEbs(message.copyWith(
              from: MessageFrom.app,
              to: MessageTo.ebsIsolated,
              type: MessageTypes.response,
              isSuccess: gm.pardonLastStealer(pardonner: player)));
          break;

        case ToAppMessages.boostRequest:
          final playerName = message.data!['player_name'] as String;
          final player = gm.players.firstWhereOrAdd(playerName);

          sendResponseToEbs(message.copyWith(
              from: MessageFrom.app,
              to: MessageTo.ebsIsolated,
              type: MessageTypes.response,
              isSuccess: gm.boostTrain(player: player)));
          break;

        case ToAppMessages.fireworksRequest:
          final playerName = message.data!['player_name'] as String;
          sendResponseToEbs(message.copyWith(
              from: MessageFrom.app,
              to: MessageTo.ebsIsolated,
              type: MessageTypes.response,
              isSuccess: true));
          gm.onCongratulationFireworks.notifyListenersWithParameter(
              {'player_name': playerName, 'is_congratulating': true});
          break;

        case ToAppMessages.attemptTheBigHeist:
          sendResponseToEbs(message.copyWith(
              from: MessageFrom.app,
              to: MessageTo.ebsIsolated,
              type: MessageTypes.response,
              isSuccess: gm.requestTheBigHeist()));
          break;

        case ToAppMessages.changeLaneRequest:
          sendResponseToEbs(message.copyWith(
              from: MessageFrom.app,
              to: MessageTo.ebsIsolated,
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
          from: MessageFrom.app,
          to: MessageTo.ebsIsolated,
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
