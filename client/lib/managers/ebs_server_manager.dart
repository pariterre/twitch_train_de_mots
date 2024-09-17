import 'dart:async';

import 'package:common/models/ebs_helpers.dart';
import 'package:common/models/simplified_game_state.dart';
import 'package:logging/logging.dart';
import 'package:train_de_mots/managers/game_manager.dart';
import 'package:train_de_mots/managers/twitch_manager.dart';
import 'package:twitch_manager/twitch_ebs.dart';

final _logger = Logger('EbsServerManager');

class EbsServerManager extends TwitchAppManagerAbstract {
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
    gm.onRoundStarted.addListener(_sendGameStateToEbs);
    gm.onRoundIsOver.addListener(_sendGameStateToEbsWithParameter);
    gm.onStealerPardoned.addListener(_sendGameStateToEbsWithParameter);
    gm.onSolutionWasStolen.addListener(_sendGameStateToEbsWithParameter);
    gm.onRoundIsOver.addListener(_sendGameStateToEbsWithParameter);
  }

  ///
  /// Dispose the TrainDeMotsEbsManager by closing the connection with the
  /// EBS server.
  void disposeListeners() {
    final gm = GameManager.instance;
    gm.onRoundStarted.removeListener(_sendGameStateToEbs);
    gm.onRoundIsOver.removeListener(_sendGameStateToEbsWithParameter);
    gm.onStealerPardoned.removeListener(_sendGameStateToEbsWithParameter);
    gm.onSolutionWasStolen.removeListener(_sendGameStateToEbsWithParameter);
    gm.onRoundIsOver.removeListener(_sendGameStateToEbsWithParameter);
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

  ///
  /// Send a message to the EBS server to notify that a new round has started
  Future<void> _sendGameStateToEbs([MessageProtocol? previousMessage]) async {
    final type =
        previousMessage == null ? MessageTypes.put : MessageTypes.response;
    previousMessage ??= MessageProtocol(
        from: MessageFrom.app, to: MessageTo.frontend, type: type);

    final gm = GameManager.instance;
    sendMessageToEbs(previousMessage.copyWith(
        from: MessageFrom.app,
        to: MessageTo.frontend,
        type: type,
        data: {
          'type': ToFrontendMessages.gameState.name,
          'game_state': SimplifiedGameState(
            status: gm.gameStatus,
            round: gm.roundCount,
            pardonRemaining: gm.remainingPardon,
            pardonners: [gm.lastStolenSolution?.stolenFrom.name ?? ''],
            boostRemaining: gm.remainingBoosts,
            boostStillNeeded: gm.numberOfBoostStillNeeded,
          ).serialize(),
        }));
  }

  ///
  /// Send a message to the EBS server to notify that a round has ended
  Future<void> _sendGameStateToEbsWithParameter(_) async =>
      _sendGameStateToEbs();

  @override
  Future<void> handleGetRequest(MessageProtocol message) {
    // There is currently no get request to handle
    throw UnimplementedError();
  }

  @override
  Future<void> handlePutRequest(MessageProtocol message) {
    // There is currently no put request to handle
    throw UnimplementedError();
  }
}
