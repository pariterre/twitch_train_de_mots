import 'dart:async';
import 'dart:convert';

import 'package:common/generic/models/ebs_helpers.dart';
import 'package:common/generic/models/game_status.dart';
import 'package:common/generic/models/serializable_game_state.dart';
import 'package:common/treasure_hunt/models/serializable_treasure_hunt_game_state.dart';
import 'package:common/treasure_hunt/models/treasure_hunt_grid.dart';
import 'package:frontend_common/managers/game_manager.dart';
import 'package:logging/logging.dart';
import 'package:twitch_manager/ebs/network/communication_protocols.dart';
import 'package:twitch_manager/twitch_frontend.dart' as tm;

final _logger = Logger('TwitchManager');

TwitchManager? _instance;

class TwitchManager {
  ///
  /// Interface reference to the TwitchFrontendManager.
  tm.TwitchFrontendManager? _frontendManager;
  tm.TwitchFrontendManager get frontendManager {
    if (_frontendManager == null) {
      _logger.severe('TwitchFrontendManager is not ready yet');
      throw Exception('TwitchFrontendManager is not ready yet');
    }

    return _frontendManager!;
  }

  final bool useLocalEbs;

  ///
  /// Initialize the TwitchManager
  static Future<void> initialize(
          {bool useMocker = false, bool useLocalEbs = false}) async =>
      useMocker
          ? _instance = TwitchManagerMock(useLocalEbs: useLocalEbs)
          : _instance = TwitchManager._(useLocalEbs: useLocalEbs);

  ///
  /// Get the opaque user ID of the current user. This is the ID that is used
  /// to identify the user in the game even though it is impossible to identify
  /// the user with this. The EBS is well aware of this opcaity and can use it
  /// to identify the user even if it is opaque (if the extension requested such
  /// permissions).
  String get userId {
    if (_frontendManager == null) {
      _logger.severe('TwitchFrontendManager is not ready yet');
      throw Exception('TwitchFrontendManager is not ready yet');
    }

    return _frontendManager!.authenticator.opaqueUserId;
  }

  bool get userHasGrantedIdAccess =>
      _frontendManager?.authenticator.userId != null;

  void requestIdShare() {
    if (_frontendManager == null) {
      _logger.severe('TwitchFrontendManager is not ready yet');
      throw Exception('TwitchFrontendManager is not ready yet');
    }

    _frontendManager!.authenticator.requestIdShare();
  }

  ///
  /// Post a request to pardon the stealer. No confirmation is received from
  /// the EBS. If the request is successful, the stealer is pardoned and a message
  /// is sent to PubSub.
  Future<bool> pardonStealer() async {
    final response = await _sendMessageToApp(ToAppMessages.pardonRequest)
        .timeout(const Duration(seconds: 5),
            onTimeout: () => MessageProtocol(
                to: MessageTo.frontend,
                from: MessageFrom.ebs,
                type: MessageTypes.response,
                isSuccess: false));
    return response.isSuccess ?? false;
  }

  ///
  /// Post a request to pardon the stealer. No confirmation is received from
  /// the EBS. If the request is successful, the stealer is pardoned and a message
  /// is sent to PubSub.
  Future<bool> boostTrain() async {
    final response =
        await _sendMessageToApp(ToAppMessages.boostRequest).timeout(
      const Duration(seconds: 5),
      onTimeout: () => MessageProtocol(
          to: MessageTo.frontend,
          from: MessageFrom.ebs,
          type: MessageTypes.response,
          isSuccess: false),
    );
    return response.isSuccess ?? false;
  }

  Future<bool> changeLane() async {
    TwitchManager.instance.frontendManager.bits.useBits('change_lane');
    // We cannot know if the transaction was successful, so we return true
    return true;
  }

  Future<bool> attemptTheBigHeist() async {
    TwitchManager.instance.frontendManager.bits.useBits('big_heist');
    // We cannot know if the transaction was successful, so we return true
    return true;
  }

  Future<bool> celebrate() async {
    TwitchManager.instance.frontendManager.bits.useBits('celebrate');
    // We cannot know if the transaction was successful, so we return true
    return true;
  }

  Future<bool> revealTileAt({required int index}) async {
    final response = await _sendMessageToApp(ToAppMessages.revealTileAt,
            data: {'index': index})
        .timeout(const Duration(seconds: 5),
            onTimeout: () => MessageProtocol(
                to: MessageTo.frontend,
                from: MessageFrom.ebs,
                type: MessageTypes.response,
                isSuccess: false));
    return response.isSuccess ?? false;
  }

  Future<bool> _redeemBitsTransaction(
      tm.BitsTransactionObject transaction) async {
    final response = await _sendMessageToApp(ToAppMessages.bitsRedeemed,
            transaction: transaction)
        .timeout(const Duration(seconds: 5),
            onTimeout: () => MessageProtocol(
                to: MessageTo.frontend,
                from: MessageFrom.ebs,
                type: MessageTypes.response,
                isSuccess: false));
    return response.isSuccess ?? false;
  }

  ///
  /// Callback to know when the TwitchManager has connected to the Twitch
  /// backend services.
  bool get isInitialized => _onHasInitialized.isCompleted;
  Future<bool> get onHasInitialized => _onHasInitialized.future;
  final _onHasInitialized = Completer<bool>();
  Future<void> _onFinishedInitializing() async {
    _logger.info('Connected to Twitch service');
    _onHasInitialized.complete(true);
  }

  ///
  /// Declare the singleton instance of the TwitchManager, calling this method
  /// automatically initializes the TwitchManager. However, ones is encouraged
  /// to call [TwitchManager.initialize()] before using the TwitchManager to make
  /// sure that the TwitchManager is configured correctly.

  static TwitchManager get instance {
    if (_instance == null) {
      _logger.severe('TwitchManager is not initialized, please call '
          'TwitchManager.initialize() before using the instance');
      throw Exception('TwitchManager is not initialized, please call '
          'TwitchManager.initialize() before using the instance');
    }
    return _instance!;
  }

  TwitchManager._({required this.useLocalEbs}) {
    _callTwitchFrontendManagerFactory();
  }

  Future<void> _callTwitchFrontendManagerFactory() async {
    _frontendManager = await tm.TwitchFrontendManager.factory(
        appInfo: tm.TwitchFrontendInfo(
          appName: 'Train de mots',
          ebsUri: Uri.parse(useLocalEbs
              ? 'ws://localhost:3010'
              : 'wss://twitchserver.pariterre.net:3010'),
        ),
        isTwitchUserIdRequired: true);

    await _onFinishedInitializing();

    _frontendManager!.onMessageReceived.listen(_onPubSubMessageReceived);
    _frontendManager!.onStreamerHasConnected.listen(() {
      GameManager.instance.startGame();
      _requestGameStatus();
    });
    _frontendManager!.onStreamerHasDisconnected
        .listen(GameManager.instance.stopGame);

    _frontendManager!.bits.onTransactionCompleted
        .listen(_onBitsTransactionCompleted);

    _logger.info('TwitchFrontendManager is ready');
  }

  Future<void> _onPubSubMessageReceived(MessageProtocol message) async {
    try {
      switch (ToFrontendMessages.values.byName(message.data!['type'])) {
        case ToFrontendMessages.gameState:
          _logger.info('Update from game state received');

          GameManager.instance.updateGameState(
              SerializableGameState.deserialize(message.data!['game_state']));

          break;

        case ToFrontendMessages.pardonResponse:
        case ToFrontendMessages.boostResponse:
          _logger.severe('This message should not be received by Pubsub');
          break;
      }
    } catch (e) {
      // The message is not a valid JSON, ignore it
    }
  }

  Future<void> _onBitsTransactionCompleted(
      tm.BitsTransactionObject transaction) async {
    _logger.info('Bits transaction completed');
    _logger.info('Transaction: ${transaction.toJson()}');
    _redeemBitsTransaction(transaction);
  }

  Future<void> _requestGameStatus() async {
    final response = await _sendMessageToApp(ToAppMessages.gameStateRequest)
        .timeout(const Duration(seconds: 5),
            onTimeout: () => MessageProtocol(
                to: MessageTo.frontend,
                from: MessageFrom.ebs,
                type: MessageTypes.response,
                isSuccess: false));
    final isSuccess = response.isSuccess ?? false;
    if (!isSuccess) {
      _logger.info('Cannot get game status');
      return;
    }

    _logger.info('Game status received');
    GameManager.instance.updateGameState(
        SerializableGameState.deserialize(response.data!['game_state']));
  }

  ///
  /// Send a message to the App based on the [type] of message.
  Future<MessageProtocol> _sendMessageToApp(
    ToAppMessages request, {
    Map<String, dynamic>? data,
    tm.BitsTransactionObject? transaction,
  }) async {
    if (!isInitialized) {
      _logger.severe('TwitchManager is not initialized');
      throw Exception('TwitchManager is not initialized');
    }

    return await _frontendManager!.sendMessageToApp(
        MessageProtocol(
            to: MessageTo.app,
            from: MessageFrom.frontend,
            type: MessageTypes.get,
            data: {'type': request.name}..addAll(data ?? {})),
        transaction: transaction);
  }
}

class TwitchManagerMock extends TwitchManager {
  TwitchManagerMock({required super.useLocalEbs}) : super._() {
    _logger.info('WARNING: Using TwitchManagerMock');
    _onFinishedInitializing();
  }

  @override
  bool get isInitialized => true;

  bool _acceptPardon = true;
  bool _acceptBoost = true;

  @override
  Future<void> _callTwitchFrontendManagerFactory() async {
    // Uncomment the next line to simulate a connexion of the App with the EBS
    _requestGameStatus();

    // // Uncomment the next line to simulate that the user can pardon in 1 second
    // Future.delayed(const Duration(seconds: 3))
    //     .then((_) => GameManager.instance.updateGameState(SerializableGameState(
    //           status: WordsTrainGameStatus.roundStarted,
    //           round: 11,
    //           isRoundSuccess: true,
    //           timeRemaining: const Duration(seconds: 83),
    //           newCooldowns: {userId: const Duration(seconds: 5)},
    //           letterProblem: SerializableLetterProblem(
    //             letters: ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J'],
    //             scrambleIndices: [3, 1, 2, 0, 4, 5, 6, 7, 8, 9],
    //             uselessLetterStatuses: List.generate(
    //                 10,
    //                 (index) =>
    //                     index == 9 ? LetterStatus.hidden : LetterStatus.normal),
    //             hiddenLetterStatuses: List.generate(
    //                 10,
    //                 (index) =>
    //                     index == 2 ? LetterStatus.hidden : LetterStatus.normal),
    //           ),
    //           pardonRemaining: 1,
    //           pardonners: [userId],
    //           boostRemaining: 1,
    //           boostStillNeeded: 0,
    //           boosters: [],
    //           canAttemptTheBigHeist: true,
    //           isAttemptingTheBigHeist: false,
    //           configuration: SerializableConfiguration(showExtension: true),
    //           miniGameState: null,
    //         )));

    // Future.delayed(const Duration(seconds: 8))
    //     .then((_) => GameManager.instance.updateGameState(SerializableGameState(
    //           status: WordsTrainGameStatus.roundStarted,
    //           round: 11,
    //           isRoundSuccess: true,
    //           timeRemaining: const Duration(seconds: 3),
    //           newCooldowns: {userId: const Duration(seconds: 5)},
    //           letterProblem: SerializableLetterProblem(
    //             letters: ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J'],
    //             scrambleIndices: [3, 1, 2, 0, 4, 5, 6, 7, 8, 9],
    //             uselessLetterStatuses: List.generate(
    //                 10,
    //                 (index) =>
    //                     index == 9 ? LetterStatus.hidden : LetterStatus.normal),
    //             hiddenLetterStatuses: List.generate(
    //                 10,
    //                 (index) =>
    //                     index == 2 ? LetterStatus.hidden : LetterStatus.normal),
    //           ),
    //           pardonRemaining: 1,
    //           pardonners: [userId],
    //           boostRemaining: 1,
    //           boostStillNeeded: 0,
    //           boosters: [],
    //           canAttemptTheBigHeist: true,
    //           isAttemptingTheBigHeist: false,
    //           configuration: SerializableConfiguration(showExtension: true),
    //           miniGameState: null,
    //         )));

    // // Uncomment the next line to simulate the start of minigame in 3 seconds
    // Future.delayed(const Duration(seconds: 3)).then((_) =>
    //     GameManager.instance.updateGameState(SerializableGameState(
    //       status: WordsTrainGameStatus.miniGameStarted,
    //       round: 11,
    //       isRoundSuccess: true,
    //       timeRemaining: const Duration(seconds: 83),
    //       newCooldowns: {userId: const Duration(seconds: 5)},
    //       letterProblem: SerializableLetterProblem(
    //         letters: ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J'],
    //         scrambleIndices: [3, 1, 2, 0, 4, 5, 6, 7, 8, 9],
    //         uselessLetterStatuses: List.generate(
    //             10,
    //             (index) =>
    //                 index == 9 ? LetterStatus.hidden : LetterStatus.normal),
    //         hiddenLetterStatuses: List.generate(
    //             10,
    //             (index) =>
    //                 index == 2 ? LetterStatus.hidden : LetterStatus.normal),
    //       ),
    //       pardonRemaining: 1,
    //       pardonners: [userId],
    //       boostRemaining: 1,
    //       boostStillNeeded: 0,
    //       boosters: [],
    //       canAttemptTheBigHeist: true,
    //       isAttemptingTheBigHeist: false,
    //       configuration: SerializableConfiguration(showExtension: true),
    //       miniGameState: SerializableTreasureHuntGameState(
    //         grid: Grid.random(rowCount: 20, columnCount: 10, rewardsCount: 40),
    //         isTimerRunning: false,
    //         timeRemaining: const Duration(seconds: 30),
    //         triesRemaining: 10,
    //       ),
    //     )));

    // // Uncomment the next line to simulate the end of minigame in 3 seconds
    // Future.delayed(const Duration(seconds: 10)).then((_) =>
    //     GameManager.instance.updateGameState(SerializableGameState(
    //       status: WordsTrainGameStatus.roundStarted,
    //       round: 11,
    //       isRoundSuccess: true,
    //       timeRemaining: const Duration(seconds: 83),
    //       newCooldowns: {userId: const Duration(seconds: 5)},
    //       letterProblem: SerializableLetterProblem(
    //         letters: ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J'],
    //         scrambleIndices: [3, 1, 2, 0, 4, 5, 6, 7, 8, 9],
    //         uselessLetterStatuses: List.generate(
    //             10,
    //             (index) =>
    //                 index == 9 ? LetterStatus.hidden : LetterStatus.normal),
    //         hiddenLetterStatuses: List.generate(
    //             10,
    //             (index) =>
    //                 index == 2 ? LetterStatus.hidden : LetterStatus.normal),
    //       ),
    //       pardonRemaining: 1,
    //       pardonners: [userId],
    //       boostRemaining: 1,
    //       boostStillNeeded: 0,
    //       boosters: [],
    //       canAttemptTheBigHeist: true,
    //       isAttemptingTheBigHeist: false,
    //       configuration: SerializableConfiguration(showExtension: true),
    //       miniGameState: SerializableTreasureHuntGameState(
    //         grid: Grid.random(rowCount: 20, columnCount: 10, rewardsCount: 40),
    //         isTimerRunning: false,
    //         timeRemaining: const Duration(seconds: 30),
    //         triesRemaining: 10,
    //       ),
    //     )));

    // Uncomment the next line to simulate that the App refused the pardon
    _acceptPardon = false;

    // Uncomment the next line to simulate that the App refused the boost
    _acceptBoost = true;
  }

  @override
  String get userId => 'U0123456789';

  @override
  bool get userHasGrantedIdAccess => true;

  @override
  void requestIdShare() {
    _logger.info('Requesting ID share');
  }

  @override
  Future<bool> changeLane() async {
    return true;
  }

  @override
  Future<bool> attemptTheBigHeist() async {
    _onPubSubMessageReceived(MessageProtocol(
        to: MessageTo.frontend,
        from: MessageFrom.app,
        type: MessageTypes.response,
        isSuccess: true,
        data: jsonDecode(jsonEncode({
          'type': ToFrontendMessages.gameState.name,
          'game_state': SerializableGameState(
            status: WordsTrainGameStatus.roundEnding,
            round: 11,
            isRoundSuccess: true,
            timeRemaining: const Duration(seconds: 83),
            newCooldowns: {userId: const Duration(seconds: 5)},
            letterProblem: SerializableLetterProblem(
              letters: ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J'],
              scrambleIndices: [3, 1, 2, 0, 4, 5, 6, 7, 8, 9],
              uselessLetterStatuses: List.generate(
                  10,
                  (index) =>
                      index == 9 ? LetterStatus.hidden : LetterStatus.normal),
              hiddenLetterStatuses: List.generate(
                  10,
                  (index) =>
                      index == 2 ? LetterStatus.hidden : LetterStatus.normal),
            ),
            pardonRemaining: 1,
            pardonners: [userId],
            boostRemaining: 1,
            boostStillNeeded: 0,
            boosters: [],
            canAttemptTheBigHeist: false,
            isAttemptingTheBigHeist: true,
            configuration: SerializableConfiguration(showExtension: true),
            miniGameState: null,
          ).serialize(),
        }))));
    return true;
  }

  @override
  Future<bool> celebrate() async {
    return true;
  }

  @override
  Future<MessageProtocol> _sendMessageToApp(
    ToAppMessages request, {
    Map<String, dynamic>? data,
    tm.BitsTransactionObject? transaction,
  }) async {
    switch (request) {
      case ToAppMessages.pardonRequest:
        return MessageProtocol(
            to: MessageTo.frontend,
            from: MessageFrom.app,
            type: MessageTypes.response,
            isSuccess: _acceptPardon);
      case ToAppMessages.boostRequest:
        return MessageProtocol(
            to: MessageTo.frontend,
            from: MessageFrom.app,
            type: MessageTypes.response,
            isSuccess: _acceptBoost);
      case ToAppMessages.gameStateRequest:
        return MessageProtocol(
            to: MessageTo.frontend,
            from: MessageFrom.app,
            type: MessageTypes.response,
            isSuccess: true,
            data: jsonDecode(jsonEncode({
              'game_state': SerializableGameState(
                status: WordsTrainGameStatus.miniGameStarted,
                round: 1,
                isRoundSuccess: true,
                timeRemaining: const Duration(seconds: 83),
                newCooldowns: {userId: const Duration(seconds: 5)},
                letterProblem: SerializableLetterProblem(
                  letters: ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J'],
                  scrambleIndices: [3, 1, 2, 0, 4, 5, 6, 7, 8, 9],
                  uselessLetterStatuses: List.generate(
                      10,
                      (index) => index == 9
                          ? LetterStatus.hidden
                          : LetterStatus.normal),
                  hiddenLetterStatuses: List.generate(
                      10,
                      (index) => index == 2
                          ? LetterStatus.hidden
                          : LetterStatus.normal),
                ),
                pardonRemaining: 1,
                pardonners: [],
                boostRemaining: 0,
                boostStillNeeded: 0,
                boosters: [],
                canAttemptTheBigHeist: false,
                isAttemptingTheBigHeist: false,
                configuration: SerializableConfiguration(showExtension: true),
                miniGameState: SerializableTreasureHuntGameState(
                  grid: Grid.random(
                      rowCount: 20, columnCount: 10, rewardsCount: 40),
                  isTimerRunning: false,
                  timeRemaining: const Duration(seconds: 30),
                  triesRemaining: 10,
                ),
              ).serialize(),
            })));
      case ToAppMessages.fireworksRequest:
      case ToAppMessages.attemptTheBigHeist:
      case ToAppMessages.changeLaneRequest:
        throw Exception('These are bits transactions and should only be called '
            'with the method _redeemBitsTransaction');

      case ToAppMessages.bitsRedeemed:
        return MessageProtocol(
            to: MessageTo.frontend,
            from: MessageFrom.app,
            type: MessageTypes.response,
            isSuccess: true);

      case ToAppMessages.revealTileAt:
        return MessageProtocol(
            to: MessageTo.frontend,
            from: MessageFrom.app,
            type: MessageTypes.response,
            isSuccess: true);
    }
  }
}
