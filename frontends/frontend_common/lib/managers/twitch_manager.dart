import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:common/blueberry_war/models/blueberry_agent.dart';
import 'package:common/blueberry_war/models/blueberry_war_game_manager_helpers.dart';
import 'package:common/blueberry_war/models/serializable_blueberry_war_game_state.dart';
import 'package:common/fix_tracks/models/fix_tracks_grid.dart'
    as fix_tracks_grid;
import 'package:common/fix_tracks/models/serializable_fix_tracks_game_state.dart';
import 'package:common/generic/managers/serializable_controllable_timer.dart';
import 'package:common/generic/misc/misc.dart';
import 'package:common/generic/models/ebs_helpers.dart';
import 'package:common/generic/models/game_status.dart';
import 'package:common/generic/models/map_extension.dart';
import 'package:common/generic/models/serializable_game_state.dart';
import 'package:common/generic/models/serializable_mini_game_state.dart';
import 'package:common/generic/models/success_level.dart';
import 'package:common/treasure_hunt/models/serializable_treasure_hunt_game_state.dart';
import 'package:common/treasure_hunt/models/treasure_hunt_grid.dart'
    as treasure_hunt_grid;
import 'package:common/warehouse_cleaning/models/agent.dart';
import 'package:common/warehouse_cleaning/models/avatar_agent.dart';
import 'package:common/warehouse_cleaning/models/box_agent.dart';
import 'package:common/warehouse_cleaning/models/letter_agent.dart';
import 'package:common/warehouse_cleaning/models/serializable_warehouse_cleaning_game_state.dart';
import 'package:common/warehouse_cleaning/models/warehouse_cleaning_game_manager_helpers.dart';
import 'package:common/warehouse_cleaning/models/warehouse_cleaning_grid.dart'
    as warehouse_cleaning_grid;
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:frontend_common/managers/game_manager.dart';
import 'package:logging/logging.dart';
import 'package:twitch_manager/common/communication_protocols.dart';
import 'package:twitch_manager/twitch_frontend.dart' as tm;
import 'package:vector_math/vector_math.dart' as vector_math;
import 'package:vector_math/vector_math.dart';

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
  final bool useTwitchAuthenticatorMock;

  Map<String, dynamic> _previousGameState = {};
  String? _displayName;
  String? get displayName => _displayName;

  ///
  /// Initialize the TwitchManager
  static Future<void> initialize({
    bool useEbsMock = false,
    bool useTwitchAuthenticatorMock = false,
    bool useLocalEbs = false,
  }) async =>
      useEbsMock
          ? _instance = TwitchManagerMock(
              useLocalEbs: useLocalEbs,
              useTwitchAuthenticatorMock: useTwitchAuthenticatorMock)
          : _instance = TwitchManager._(
              useLocalEbs: useLocalEbs,
              useTwitchAuthenticatorMock: useTwitchAuthenticatorMock);

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

  Future<bool> tryWord(String word) async {
    final response =
        await _sendMessageToApp(MessagesToApp.tryWord, data: {'word': word})
            .timeout(const Duration(seconds: 5),
                onTimeout: () => tm.MessageProtocol(
                    to: tm.MessageTo.frontend,
                    from: tm.MessageFrom.ebs,
                    type: tm.MessageTypes.response,
                    isSuccess: false));
    return response.isSuccess ?? false;
  }

  ///
  /// Post a request to pardon the stealer. No confirmation is received from
  /// the EBS. If the request is successful, the stealer is pardoned and a message
  /// is sent to PubSub.
  Future<bool> pardonStealer() async {
    final response = await _sendMessageToApp(MessagesToApp.pardonRequest)
        .timeout(const Duration(seconds: 5),
            onTimeout: () => tm.MessageProtocol(
                to: tm.MessageTo.frontend,
                from: tm.MessageFrom.ebs,
                type: tm.MessageTypes.response,
                isSuccess: false));
    return response.isSuccess ?? false;
  }

  ///
  /// Post a request to pardon the stealer. No confirmation is received from
  /// the EBS. If the request is successful, the stealer is pardoned and a message
  /// is sent to PubSub.
  Future<bool> boostTrain() async {
    final response =
        await _sendMessageToApp(MessagesToApp.boostRequest).timeout(
      const Duration(seconds: 5),
      onTimeout: () => tm.MessageProtocol(
          to: tm.MessageTo.frontend,
          from: tm.MessageFrom.ebs,
          type: tm.MessageTypes.response,
          isSuccess: false),
    );
    return response.isSuccess ?? false;
  }

  ///
  /// Request to change lanes during main game.
  Future<bool> changeLane() async {
    // Annonce to App that a change of lane request is being redeemed
    final response =
        await _sendMessageToApp(MessagesToApp.changeLaneRequest).timeout(
      const Duration(seconds: 5),
      onTimeout: () => tm.MessageProtocol(
          to: tm.MessageTo.frontend,
          from: tm.MessageFrom.ebs,
          type: tm.MessageTypes.response,
          isSuccess: false),
    );
    if (!(response.isSuccess ?? false)) return false;

    return _useBits(Sku.changeLane);
  }

  ///
  /// Request to attempt the big heist during the break.
  Future<bool> attemptTheBigHeist() async {
    // Annonce to App that a big heist request is being redeemed
    final response =
        await _sendMessageToApp(MessagesToApp.attemptTheBigHeist).timeout(
      const Duration(seconds: 5),
      onTimeout: () => tm.MessageProtocol(
          to: tm.MessageTo.frontend,
          from: tm.MessageFrom.ebs,
          type: tm.MessageTypes.response,
          isSuccess: false),
    );
    if (!(response.isSuccess ?? false)) return false;

    return _useBits(Sku.bigHeist);
  }

  ///
  /// Request to attempt the end of railway minigame during the break.
  Future<bool> attemptFixTracksMiniGame() async {
    // Annonce to App that an end of railway mini game request is being redeemed
    final response =
        await _sendMessageToApp(MessagesToApp.fixTracksMiniGameRequest).timeout(
      const Duration(seconds: 5),
      onTimeout: () => tm.MessageProtocol(
          to: tm.MessageTo.frontend,
          from: tm.MessageFrom.ebs,
          type: tm.MessageTypes.response,
          isSuccess: false),
    );
    if (!(response.isSuccess ?? false)) return false;

    return _useBits(Sku.fixTracks);
  }

  ///
  /// Send a celebration request during the break
  Future<bool> celebrate() async {
    // Annonce to App that a celebrate request is being redeemed
    final response =
        await _sendMessageToApp(MessagesToApp.fireworksRequest).timeout(
      const Duration(seconds: 5),
      onTimeout: () => tm.MessageProtocol(
          to: tm.MessageTo.frontend,
          from: tm.MessageFrom.ebs,
          type: tm.MessageTypes.response,
          isSuccess: false),
    );
    if (!(response.isSuccess ?? false)) return false;

    return _useBits(Sku.celebrate);
  }

  ///
  /// Request to reveal a tile in the Treasure Hunt minigame.
  Future<bool> revealTileAt({required int index}) async {
    final response = await _sendMessageToApp(MessagesToApp.revealTileAt,
            data: {'index': index})
        .timeout(const Duration(seconds: 5),
            onTimeout: () => tm.MessageProtocol(
                to: tm.MessageTo.frontend,
                from: tm.MessageFrom.ebs,
                type: tm.MessageTypes.response,
                isSuccess: false));
    return response.isSuccess ?? false;
  }

  ///
  /// Request to slingshot a blueberry in the Blueberry War minigame.
  Future<bool> slingShotBlueberryWar(
      {required BlueberryAgent blueberry,
      required Vector2 requestedVelocity}) async {
    final response =
        await _sendMessageToApp(MessagesToApp.slingShotBlueberryWar, data: {
      'id': blueberry.id.toString(),
      'velocity': [requestedVelocity.x, requestedVelocity.y]
    }).timeout(const Duration(seconds: 5),
            onTimeout: () => tm.MessageProtocol(
                to: tm.MessageTo.frontend,
                from: tm.MessageFrom.ebs,
                type: tm.MessageTypes.response,
                isSuccess: false));
    return response.isSuccess ?? false;
  }

  ///
  /// Request to slingshot an avatar in the Warehouse Cleaning minigame.
  Future<bool> slingShotAvatarWareHouse(
      {required AvatarAgent avatar, required Vector2 requestedVelocity}) async {
    final response =
        await _sendMessageToApp(MessagesToApp.slingShotAvatarWareHouse, data: {
      'id': avatar.id.toString(),
      'velocity': [requestedVelocity.x, requestedVelocity.y]
    }).timeout(const Duration(seconds: 5),
            onTimeout: () => tm.MessageProtocol(
                to: tm.MessageTo.frontend,
                from: tm.MessageFrom.ebs,
                type: tm.MessageTypes.response,
                isSuccess: false));
    return response.isSuccess ?? false;
  }

  Future<bool> _redeemBitsTransaction(
      tm.BitsTransactionObject transaction) async {
    final response = await _sendMessageToApp(MessagesToApp.bitsRedeemed,
            transaction: transaction)
        .timeout(const Duration(seconds: 5),
            onTimeout: () => tm.MessageProtocol(
                to: tm.MessageTo.frontend,
                from: tm.MessageFrom.ebs,
                type: tm.MessageTypes.response,
                isSuccess: false));
    return response.isSuccess ?? false;
  }

  ///
  /// Callback to know when the TwitchManager has connected to the Twitch
  /// backend services.
  bool get isInitialized => _onHasInitialized.isCompleted;
  Future<bool> get onHasInitialized => _onHasInitialized.future;
  final _onHasInitialized = Completer<bool>();
  void _onFinishedInitializing() {
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

  TwitchManager._(
      {required this.useLocalEbs, required this.useTwitchAuthenticatorMock}) {
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
      isTwitchUserIdRequired: true,
      mockedAuthenticatorInitializer: useTwitchAuthenticatorMock
          ? () => MockedTwitchJwtAuthenticator()
          : null,
    );

    _onFinishedInitializing();

    _frontendManager!.onMessageReceived.listen(_onMessageReceived);
    _frontendManager!.onStreamerHasConnected.listen(() {
      GameManager.instance.startGame();
      _requestCurrentDisplayName();
      _requestGameStatus();
    });
    _frontendManager!.onStreamerHasDisconnected
        .listen(GameManager.instance.stopGame);

    _frontendManager!.bits.onTransactionCompleted
        .listen(_onBitsTransactionCompleted);

    _logger.info('TwitchFrontendManager is ready');
  }

  void _onMessageReceived(tm.MessageProtocol message) {
    try {
      switch (MessagesToFrontend.values.byName(message.data!['type'])) {
        case MessagesToFrontend.gameStateResponse:
          _onGameStateReceived(message);
          break;

        case MessagesToFrontend.pardonResponse:
        case MessagesToFrontend.boostResponse:
          _logger.severe('This message should not be received by Pubsub');
          break;
      }
    } catch (e) {
      // The message is not a valid JSON, ignore it
    }
  }

  ///
  /// Use bits cannot be blocking as it does not confirm anything. If successful
  /// the onTransactionCompleted callback will be automatically called.
  bool _useBits(Sku sku) {
    TwitchManager.instance.frontendManager.bits.useBits(sku.toString());

    if (_frontendManager!.authenticator is MockedTwitchJwtAuthenticator) {
      // Simulate a successful transaction after 1000 milliseconds
      Future.delayed(const Duration(milliseconds: 1000)).then((_) {
        _onBitsTransactionCompleted(tm.BitsTransactionObject.generateMocked(
            userId: _frontendManager!.authenticator.userId!,
            sku: sku.toString(),
            sharedSecret: mockedSharedSecret));
      });
    }
    return true;
  }

  Future<void> _onBitsTransactionCompleted(
      tm.BitsTransactionObject transaction) async {
    _logger.info('Bits transaction completed');
    final isSuccess = await _redeemBitsTransaction(transaction);
    if (!isSuccess) return;

    // Tell the GameManager that bits were used
    switch (
        Sku.fromString(transaction.extractedUnverifiedReceipt.product.sku)) {
      case Sku.changeLane:
        GameManager.instance.changeLaneGranted();
        break;
      case Sku.bigHeist:
      case Sku.fixTracks:
      case Sku.celebrate:
        break;
    }
  }

  Future<void> _requestCurrentDisplayName() async {
    while (_displayName == null) {
      final response =
          await _sendMessageToEbs(MessagesToEbs.opaqueToDisplayName)
              .timeout(const Duration(seconds: 5),
                  onTimeout: () => tm.MessageProtocol(
                      to: tm.MessageTo.frontend,
                      from: tm.MessageFrom.ebs,
                      type: tm.MessageTypes.response,
                      isSuccess: false))
              .onError((e, st) => tm.MessageProtocol(
                  to: tm.MessageTo.frontend,
                  from: tm.MessageFrom.ebs,
                  type: tm.MessageTypes.response,
                  isSuccess: false));
      if (response.isSuccess ?? false) {
        _displayName = response.data?['display_name'] as String?;
      }

      await Future.delayed(const Duration(seconds: 5));
    }
  }

  Future<void> _requestGameStatus() async {
    final response = await _sendMessageToEbs(MessagesToEbs.gameStateRequest)
        .timeout(const Duration(seconds: 5),
            onTimeout: () => tm.MessageProtocol(
                to: tm.MessageTo.frontend,
                from: tm.MessageFrom.ebs,
                type: tm.MessageTypes.response,
                isSuccess: false));
    final isSuccess = response.isSuccess ?? false;
    if (!isSuccess) {
      _logger.info('Cannot get game status');
      return;
    }

    _onGameStateReceived(response, retryOnFail: false);
  }

  Future<void> _onGameStateReceived(MessageProtocol message,
      {bool retryOnFail = true}) async {
    _logger.fine('Game state received');
    final patch = message.data?['game_state'] == null
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(message.data!['game_state']);

    final newGameState =
        applyPatch<Map<String, dynamic>>(_previousGameState, patch);

    if (newGameState.checksum() != message.data!['checksum']) {
      if (retryOnFail) {
        _logger
            .info('Game state checksum mismatch, requesting full game status');
        _requestGameStatus();
      } else {
        _previousGameState = {};
      }
      return;
    }

    GameManager.instance
        .updateGameState(SerializableGameState.deserialize(newGameState));
    _previousGameState = newGameState;
  }

  ///
  /// Send a message to the App based on the [type] of message.
  Future<tm.MessageProtocol> _sendMessageToApp(
    MessagesToApp request, {
    Map<String, dynamic>? data,
    tm.BitsTransactionObject? transaction,
  }) async {
    if (!isInitialized) {
      _logger.severe('TwitchManager is not initialized');
      throw Exception('TwitchManager is not initialized');
    }

    return await _frontendManager!.sendMessageToApp(
        tm.MessageProtocol(
            to: tm.MessageTo.app,
            from: tm.MessageFrom.frontend,
            type: tm.MessageTypes.get,
            data: {'type': request.name}..addAll(data ?? {})),
        transaction: transaction);
  }

  ///
  /// Send a message to the App based on the [type] of message.
  Future<tm.MessageProtocol> _sendMessageToEbs(
    MessagesToEbs request, {
    Map<String, dynamic>? data,
    tm.BitsTransactionObject? transaction,
  }) async {
    if (!isInitialized) {
      _logger.severe('TwitchManager is not initialized');
      throw Exception('TwitchManager is not initialized');
    }

    return await _frontendManager!.sendMessageToEbs(
        tm.MessageProtocol(
            to: tm.MessageTo.ebs,
            from: tm.MessageFrom.frontend,
            type: tm.MessageTypes.get,
            data: {'type': request.name}..addAll(data ?? {})),
        transaction: transaction);
  }
}

class TwitchManagerMock extends TwitchManager {
  TwitchManagerMock(
      {required super.useLocalEbs, required super.useTwitchAuthenticatorMock})
      : super._() {
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
    Future.delayed(const Duration(milliseconds: 100))
        .then((_) => _requestGameStatus());

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
    //           canRequestTheBigHeist: true,
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
    //           canRequestTheBigHeist: true,
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
    //       canRequestTheBigHeist: true,
    //       isAttemptingTheBigHeist: false,
    //       configuration: SerializableConfiguration(showExtension: true),
    //       miniGameState: SerializableTreasureHuntGameState(
    //         grid: Grid.random(rowCount: 20, columnCount: 10, rewardCount: 40),
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
    //       canRequestTheBigHeist: true,
    //       isAttemptingTheBigHeist: false,
    //       configuration: SerializableConfiguration(showExtension: true),
    //       miniGameState: SerializableTreasureHuntGameState(
    //         grid: Grid.random(rowCount: 20, columnCount: 10, rewardCount: 40),
    //         isTimerRunning: false,
    //         timeRemaining: const Duration(seconds: 30),
    //         triesRemaining: 10,
    //       ),
    //     )));

    // // Uncomment the next line to simulate the sling shoot of a player agent in 3 seconds
    // Future.delayed(const Duration(seconds: 3)).then((_) {
    //   final oldGameState = GameManager.instance.gameStateCopy;
    //   final oldMiniGameState =
    //       oldGameState.miniGameState as SerializableBlueberryWarGameState?;
    //   final oldAllAgents = [...(oldMiniGameState?.allAgents ?? <Agent>[])];
    //   oldAllAgents[0].velocity = Vector2(400, 100);

    //   final newGameState = oldGameState.copyWith(
    //       miniGameState: oldMiniGameState?.copyWith(allAgents: oldAllAgents));
    //   GameManager.instance.updateGameState(newGameState);
    // });

    // // Uncomment the next line to simulate the new grid in track fix
    // Future.delayed(const Duration(seconds: 3)).then((_) {
    //   final oldGameState = GameManager.instance.gameStateCopy;
    //   final oldMiniGameState =
    //       oldGameState.miniGameState as SerializableFixTracksGameState?;

    //   final segment = oldMiniGameState?.grid.segments[0];
    //   final wordLength = segment?.length ?? 0;
    //   final firstLetter = oldMiniGameState?.grid
    //       .tileOfSegmentAt(segment: segment!, index: 0)
    //       ?.letter;
    //   segment?.word = DictionaryManager.wordsWithAtLeast(4).firstWhere(
    //       (word) => word.length == wordLength && word[0] == firstLetter);
    //   for (int i = 0; i < wordLength; i++) {
    //     oldMiniGameState!.grid
    //         .tileOfSegmentAt(segment: segment!, index: i)
    //         ?.letter = segment.word![i];
    //   }

    //   final newGameState = oldGameState.copyWith(
    //       miniGameState:
    //           oldMiniGameState?.copyWith(grid: oldMiniGameState.grid));
    //   GameManager.instance.updateGameState(newGameState);
    // });

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
  bool _useBits(Sku sku) {
    switch (sku) {
      case Sku.changeLane:
      case Sku.fixTracks:
      case Sku.celebrate:
        // Simulate a successful transaction after 1000 milliseconds
        Future.delayed(const Duration(milliseconds: 1000)).then((_) {
          _onBitsTransactionCompleted(tm.BitsTransactionObject.generateMocked(
              userId: userId,
              sku: sku.toString(),
              sharedSecret: mockedSharedSecret));
        });
        return true;
      case Sku.bigHeist:
        _onMessageReceived(tm.MessageProtocol(
            to: tm.MessageTo.frontend,
            from: tm.MessageFrom.app,
            type: tm.MessageTypes.response,
            isSuccess: true,
            data: jsonDecode(jsonEncode({
              'type': MessagesToFrontend.gameStateResponse.name,
              'game_state': SerializableGameState(
                hasPlayedAtLeastOnce: true,
                roundCount: 11,
                gameStatus: WordsTrainGameStatus.roundStarted,
                isRoundAMiniGame: true,
                successLevel: SuccessLevel.oneStar,
                roundSuccesses: [],
                roundTimer: SerializableControllableTimer(
                    isInitialized: true,
                    startedAt: DateTime.now(),
                    endsAt: DateTime.now().add(const Duration(seconds: 83)),
                    pausedAt: null),
                players: {},
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
                playersWhoCanPardon: [userId],
                boostRemaining: 1,
                boostStillNeeded: 0,
                boosters: [],
                canChangeLane: true,
                canRequestFireworks: false,
                canRequestTheBigHeist: false,
                isAttemptingTheBigHeist: true,
                canRequestFixTracksMiniGame: true,
                isAttemptingFixTracksMiniGame: false,
                configuration: SerializableConfiguration(showExtension: true),
                miniGameState: SerializableMiniGameStateNone(),
              ).serialize(),
            }))));
        return true;
    }
  }

  @override
  Future<tm.MessageProtocol> _sendMessageToApp(
    MessagesToApp request, {
    Map<String, dynamic>? data,
    tm.BitsTransactionObject? transaction,
  }) async {
    switch (request) {
      case MessagesToApp.pardonRequest:
        return tm.MessageProtocol(
            to: tm.MessageTo.frontend,
            from: tm.MessageFrom.app,
            type: tm.MessageTypes.response,
            isSuccess: _acceptPardon);
      case MessagesToApp.tryWord:
        final word = data?['word'] as String?;
        return tm.MessageProtocol(
            to: tm.MessageTo.frontend,
            from: tm.MessageFrom.app,
            type: tm.MessageTypes.response,
            isSuccess: word != null && word.length % 2 == 0);
      case MessagesToApp.boostRequest:
        return tm.MessageProtocol(
            to: tm.MessageTo.frontend,
            from: tm.MessageFrom.app,
            type: tm.MessageTypes.response,
            isSuccess: _acceptBoost);
      case MessagesToApp.fireworksRequest:
      case MessagesToApp.attemptTheBigHeist:
      case MessagesToApp.changeLaneRequest:
      case MessagesToApp.fixTracksMiniGameRequest:
        return tm.MessageProtocol(
            to: tm.MessageTo.frontend,
            from: tm.MessageFrom.app,
            type: tm.MessageTypes.response,
            isSuccess: true);

      case MessagesToApp.bitsRedeemed:
        return tm.MessageProtocol(
            to: tm.MessageTo.frontend,
            from: tm.MessageFrom.app,
            type: tm.MessageTypes.response,
            isSuccess: true);

      case MessagesToApp.revealTileAt:
        return tm.MessageProtocol(
            to: tm.MessageTo.frontend,
            from: tm.MessageFrom.app,
            type: tm.MessageTypes.response,
            isSuccess: true);

      case MessagesToApp.slingShotBlueberryWar:
        return tm.MessageProtocol(
            to: tm.MessageTo.frontend,
            from: tm.MessageFrom.app,
            type: tm.MessageTypes.response,
            isSuccess: true);

      case MessagesToApp.slingShotAvatarWareHouse:
        return tm.MessageProtocol(
            to: tm.MessageTo.frontend,
            from: tm.MessageFrom.app,
            type: tm.MessageTypes.response,
            isSuccess: true);

      case MessagesToApp.isExtensionActive:
      case MessagesToApp.fullGameStateRequest:
        throw 'Request should not come from frontend';
    }
  }

  @override
  Future<tm.MessageProtocol> _sendMessageToEbs(
    MessagesToEbs request, {
    Map<String, dynamic>? data,
    tm.BitsTransactionObject? transaction,
  }) async {
    switch (request) {
      case MessagesToEbs.opaqueToDisplayName:
        return tm.MessageProtocol(
            to: tm.MessageTo.frontend,
            from: tm.MessageFrom.ebs,
            type: tm.MessageTypes.response,
            isSuccess: true,
            data: {'display_name': 'Viewer1'});
      case MessagesToEbs.gameStateRequest:
        {
          final gameState = SerializableGameState.empty()
              .copyWith(
                hasPlayedAtLeastOnce: true,
                roundCount: 13,
                gameStatus: WordsTrainGameStatus.roundStarted,
                isRoundAMiniGame: true,
                successLevel: SuccessLevel.failed,
                roundSuccesses: [],
                roundTimer: SerializableControllableTimer(
                    isInitialized: true,
                    startedAt: DateTime.now(),
                    endsAt: DateTime.now().add(const Duration(seconds: 83)),
                    pausedAt: DateTime.now()),
                players: {},
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
                playersWhoCanPardon: [],
                boostRemaining: 0,
                boostStillNeeded: 0,
                boosters: [],
                canChangeLane: true,
                canRequestTheBigHeist: false,
                isAttemptingTheBigHeist: false,
                canRequestFireworks: false,
                canRequestFixTracksMiniGame: true,
                isAttemptingFixTracksMiniGame: false,
                configuration: SerializableConfiguration(showExtension: true),
                miniGameState: warehouseCleaningDummyMiniGame(isPaused: false),
              )
              .serialize();

          return tm.MessageProtocol(
              to: tm.MessageTo.frontend,
              from: tm.MessageFrom.app,
              type: tm.MessageTypes.response,
              isSuccess: true,
              data: jsonDecode(jsonEncode({
                'game_state': gameState,
                'checksum': gameState.checksum(),
              })));
        }
      case MessagesToEbs.newLetterProblemRequest:
      case MessagesToEbs.patchGameState:
        throw 'Request should not come from frontend';
    }
  }

  SerializableMiniGameState treasureHuntDummyMiniGame(
      {required bool isPaused}) {
    final problem = SerializableLetterProblem(
      letters: ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J'],
      scrambleIndices: [3, 1, 2, 0, 4, 5, 6, 7, 8, 9],
      uselessLetterStatuses: List.generate(
          10, (i) => i == 5 ? LetterStatus.revealed : LetterStatus.normal),
      hiddenLetterStatuses: List.generate(10, (_) => LetterStatus.hidden),
    );

    return SerializableTreasureHuntGameState(
        roundTimer: SerializableControllableTimer(
            isInitialized: true,
            startedAt: DateTime.now(),
            endsAt: DateTime.now().add(const Duration(seconds: 30)),
            pausedAt: isPaused ? DateTime.now() : null),
        triesRemaining: 10,
        problem: problem,
        grid: treasure_hunt_grid.TreasureHuntGrid.random(
            rowCount: 20, columnCount: 10, rewardCount: 40, problem: problem));
  }

  SerializableMiniGameState blueberryWarDummyMiniGame(
          {required bool isPaused}) =>
      SerializableBlueberryWarGameState(
          roundTimer: SerializableControllableTimer(
              isInitialized: true,
              startedAt: DateTime.now(),
              endsAt: DateTime.now().add(const Duration(seconds: 30)),
              pausedAt: isPaused ? DateTime.now() : null),
          allAgents: {
            for (var id in List.generate(10, (id) => id + 1000))
              id.toString(): BlueberryAgent(
                id: id,
                position: BlueberryAgent.generateRandomStartingPosition(
                  blueberryFieldSize: BlueberryWarConfig.blueberryFieldSize,
                  blueberryRadius: BlueberryWarConfig.blueberryRadius,
                ),
                velocity: Vector2.zero(),
                isInField: false,
                maxVelocity: BlueberryWarConfig.blueberryMaxVelocity,
                radius: BlueberryWarConfig.blueberryRadius,
                mass: 3.0,
                coefficientOfFriction: 0.8,
                wasSlingShot: false,
                wasTeleported: false,
              )
          },
          problem: SerializableLetterProblem(
            letters: ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J'],
            scrambleIndices: [3, 1, 2, 0, 4, 5, 6, 7, 8, 9],
            uselessLetterStatuses: List.generate(10,
                (i) => i == 5 ? LetterStatus.revealed : LetterStatus.normal),
            hiddenLetterStatuses: List.generate(10, (_) => LetterStatus.hidden),
          ));

  SerializableMiniGameState warehouseCleaningDummyMiniGame(
      {required bool isPaused}) {
    final problem = SerializableLetterProblem(
      letters: ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J'],
      scrambleIndices: [3, 1, 2, 0, 4, 5, 6, 7, 8, 9],
      uselessLetterStatuses: List.generate(
          10, (i) => i == 5 ? LetterStatus.revealed : LetterStatus.normal),
      hiddenLetterStatuses: List.generate(10, (_) => LetterStatus.hidden),
    );

    final grid = warehouse_cleaning_grid.WarehouseCleaningGrid.random(
        rowCount: WarehouseCleaningConfig.rowCount,
        columnCount: WarehouseCleaningConfig.columnCount,
        problem: problem,
        startingRow: WarehouseCleaningConfig.startingRow,
        startingCol: WarehouseCleaningConfig.startingCol);

    ///
    /// Avatar position
    warehouse_cleaning_grid.Tile? tileFromPosition(
            vector_math.Vector2 position) =>
        grid.tileAt(
            row: (position.y / WarehouseCleaningConfig.tileSize).round(),
            col: (position.x / WarehouseCleaningConfig.tileSize).round());

    // Populate the agents list with the avatar
    final startingPosition = vector_math.Vector2(
      WarehouseCleaningConfig.startingCol.toDouble() *
          WarehouseCleaningConfig.tileSize,
      WarehouseCleaningConfig.startingRow.toDouble() *
          WarehouseCleaningConfig.tileSize,
    );
    final startingTile = tileFromPosition(startingPosition);
    if (startingTile == null) {
      throw "Starting tile should not be null";
    }

    final allAgents = <String, Agent>{};
    for (int i = 0; i < WarehouseCleaningConfig.initialAvatarCount; i++) {
      allAgents[i.toString()] = AvatarAgent(
        id: i,
        tileIndex: startingTile.index,
        position: startingPosition,
        radius: WarehouseCleaningConfig.avatarRadius,
        maxVelocity: WarehouseCleaningConfig.avatarMaxVelocity,
        velocity: vector_math.Vector2.zero(),
        coefficientOfFriction:
            WarehouseCleaningConfig.avatarFrictionCoefficient,
        wasSlingShot: false,
      );
    }

    // Populate the agents list with the boxes and letters
    int currentIndex = WarehouseCleaningConfig.initialAvatarCount;
    for (int index = 0; index < grid.cellCount; index++) {
      final tile = grid.tileAt(index: index);
      if (tile == null) {
        continue;
      } else if (tile.isLetter) {
        allAgents[currentIndex.toString()] = LetterAgent(
          id: currentIndex,
          tileIndex: tile.index,
          value: tile.letter!,
          position: vector_math.Vector2(
            tile.col.toDouble() * WarehouseCleaningConfig.tileSize,
            tile.row.toDouble() * WarehouseCleaningConfig.tileSize,
          ),
          radius: WarehouseCleaningConfig.boxRadius,
          isCollected: false,
        );
      } else if (tile.isBox) {
        allAgents[currentIndex.toString()] = BoxAgent(
          id: currentIndex,
          tileIndex: tile.index,
          position: vector_math.Vector2(
            tile.col.toDouble() * WarehouseCleaningConfig.tileSize,
            tile.row.toDouble() * WarehouseCleaningConfig.tileSize,
          ),
          radius: WarehouseCleaningConfig.boxRadius,
        );
      }
      currentIndex++;
    }

    // Perform an initial reveal of the fog of war around the avatar starting position
    final avatars =
        allAgents.values.whereType<AvatarAgent>().toList(growable: false);
    final avatarTile = tileFromPosition(avatars.first.position);
    avatarTile == null ? null : grid.revealAt(index: avatarTile.index);

    return SerializableWarehouseCleaningGameState(
        roundTimer: SerializableControllableTimer(
            isInitialized: true,
            startedAt: DateTime.now(),
            endsAt: DateTime.now().add(const Duration(seconds: 30)),
            pausedAt: isPaused ? DateTime.now() : null),
        triesRemaining: 40,
        allAgents: allAgents,
        grid: grid,
        problem: problem);
  }

  SerializableMiniGameState fixTrackDummyMiniGame({required bool isPaused}) =>
      SerializableFixTracksGameState(
          roundTimer: SerializableControllableTimer(
              isInitialized: true,
              startedAt: DateTime.now(),
              endsAt: DateTime.now().add(const Duration(seconds: 30)),
              pausedAt: isPaused ? DateTime.now() : null),
          grid: fix_tracks_grid.FixTracksGrid.random(
            rowCount: 20,
            columnCount: 10,
            minimumSegmentLength: 4,
            maximumSegmentLength: 8,
            segmentCount: 9,
            segmentsWithLetterCount: 5,
          ));
}

///
/// The JWT key is for the Frontend of a Twitch extension.
class MockedTwitchJwtAuthenticator extends tm.TwitchJwtAuthenticator {
  MockedTwitchJwtAuthenticator();

  ///
  /// ebsToken is the token that is used to authenticate the EBS to the Twitch API
  @override
  tm.AppToken? get ebsToken {
    return tm.AppToken.fromSerialized(JWT({
      'twitch_access_token': JWT({
        'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'exp': (DateTime.now().millisecondsSinceEpoch ~/ 1000) + 3600,
        'channel_id': channelId,
        'user_id': userId,
        'opaque_user_id': opaqueUserId,
        'role': 'external',
        'is_unlinked': false,
      }).sign(SecretKey(mockedSharedSecret, isBase64Encoded: true)),
      'channel_id': channelId,
      'opaque_user_id': opaqueUserId,
      'user_id': userId
    }).sign(SecretKey(mockedSharedSecret, isBase64Encoded: true)));
  }

  ///
  /// The id of the channel that the frontend is connected to
  @override
  String get channelId => '1234567890';

  ///
  /// The obfuscted user id of the frontend
  @override
  String get opaqueUserId => 'MyMockedOpaqueUserId';

  ///
  /// The non-obfuscated user id of the frontend. This required [isTwitchUserIdRequired]
  /// to be true when calling the [connect] method
  final _userId = (Random().nextInt(8000000) + 1000000000).toString();
  @override
  String? get userId => 'Mocked_$_userId';

  @override
  void requestIdShare() {
    // Do nothing
  }

  bool _isConnected = false;
  @override
  bool get isConnected => _isConnected;
  @override
  Future<void> connect({
    required tm.TwitchFrontendInfo appInfo,
    bool isTwitchUserIdRequired = false,
  }) async {
    // Do nothing, as this is a mock
    _isConnected = true;
    onHasConnected.notifyListeners((callback) => callback());
  }

  @override
  Future<void> listenToPubSub(
      String target, Function(tm.MessageProtocol message) callback) async {
    // Do nothing, as this is a mock
  }
}
