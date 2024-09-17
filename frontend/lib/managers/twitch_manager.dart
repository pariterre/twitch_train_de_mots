import 'dart:async';
import 'dart:convert';

import 'package:common/models/ebs_helpers.dart';
import 'package:common/models/game_status.dart';
import 'package:common/models/simplified_game_state.dart';
import 'package:frontend/managers/game_manager.dart';
import 'package:logging/logging.dart';
import 'package:twitch_manager/ebs/network/communication_protocols.dart';
import 'package:twitch_manager/twitch_frontend.dart' as tm;

final _logger = Logger('TwitchManagerMain');

TwitchManager? _instance;

class TwitchManager {
  ///
  /// Interface reference to the TwitchFrontendManager.
  tm.TwitchFrontendManager? _frontendManager;

  ///
  /// Initialize the TwitchManager
  static Future<void> initialize({bool useMocker = false}) async => useMocker
      ? _instance = TwitchManagerMock()
      : _instance = TwitchManager._();

  ///
  /// Get the opaque user ID of the current user. This is the ID that is used
  /// to identify the user in the game. The EBS is well aware of this ID and
  /// can use it to identify the user even if it is opaque.
  String get opaqueUserId {
    if (_frontendManager == null) {
      _logger.severe('TwitchFrontendManager is not ready yet');
      throw Exception('TwitchFrontendManager is not ready yet');
    }

    return _frontendManager!.authenticator.opaqueUserId;
  }

  ///
  /// Post a request to pardon the stealer. No confirmation is received from
  /// the EBS. If the request is successful, the stealer is pardoned and a message
  /// is sent to PubSub.
  Future<bool> pardonStealer() async {
    final response = await _sendMessageToApp(ToAppMessages.pardonRequest);
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
          from: MessageFrom.ebsIsolated,
          to: MessageTo.frontend,
          type: MessageTypes.response,
          isSuccess: false),
    );
    return response.isSuccess ?? false;
  }

  ///
  /// Callback to know when the TwitchManager has connected to the Twitch
  /// backend services.
  bool get isInitialized => _onInitialized.isCompleted;
  Future<bool> get onInitialized => _onInitialized.future;
  final _onInitialized = Completer<bool>();
  Future<void> _onFinishedInitializing() async {
    _logger.info('Connected to Twitch service');
    _onInitialized.complete(true);
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

  TwitchManager._() {
    _callTwitchFrontendManagerFactory();
  }

  Future<void> _callTwitchFrontendManagerFactory() async {
    _frontendManager = await tm.TwitchFrontendManager.factory(
      appInfo: tm.TwitchFrontendInfo(
          appName: 'Train de mots',
          ebsUri: Uri.parse('http://localhost:3010/frontend')),
      isTwitchUserIdRequired: true,
      onConnectedToTwitchService: _onFinishedInitializing,
      pubSubCallback: _onPubSubMessageReceived,
    );
    _logger.info('TwitchFrontendManager is ready');

    // Try to get the game status. This will fail if the game has not started yet
    // but it is not a problem, the game will send a message to the frontend when
    // it is ready.
    await _requestGameStatus();
  }

  Future<void> _onPubSubMessageReceived(MessageProtocol message) async {
    try {
      switch (ToFrontendMessages.values.byName(message.data!['type'])) {
        case ToFrontendMessages.streamerHasConnected:
          _logger.info('Streamer connected to the game');
          await _requestGameStatus();
          break;

        case ToFrontendMessages.streamerHasDisconnected:
          _logger.info('Streamer disconnected from the game');
          final gm = GameManager.instance;
          gm.updateGameState(
              gm.gameState.copyWith(status: GameStatus.initializing));
          break;

        case ToFrontendMessages.gameState:
          _logger.info('Round started by streamer');

          GameManager.instance.updateGameState(
              SimplifiedGameState.deserialize(message.data!['game_state']));

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

  Future<void> _requestGameStatus() async {
    final response = await _sendMessageToApp(ToAppMessages.gameStateRequest);
    final isSuccess = response.isSuccess ?? false;
    if (!isSuccess) {
      _logger.info('Cannot get game status');
      return;
    }

    _logger.info('Game status received');
    GameManager.instance.updateGameState(
        SimplifiedGameState.deserialize(response.data!['game_state']));
  }

  ///
  /// Send a message to the App based on the [type] of message.
  Future<MessageProtocol> _sendMessageToApp(ToAppMessages request) async {
    if (!isInitialized) {
      _logger.severe('TwitchManager is not initialized');
      throw Exception('TwitchManager is not initialized');
    }

    return await _frontendManager!.sendMessageToApp(MessageProtocol(
        from: MessageFrom.frontend,
        to: MessageTo.app,
        type: MessageTypes.get,
        data: {'type': request.name}));
  }
}

class TwitchManagerMock extends TwitchManager {
  TwitchManagerMock() : super._() {
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

    // Uncomment the next line to simulate that the user can pardon in 1 second
    Future.delayed(const Duration(seconds: 1))
        .then((_) => GameManager.instance.updateGameState(SimplifiedGameState(
              status: GameStatus.roundStarted,
              round: 1,
              pardonRemaining: 1,
              pardonners: [opaqueUserId],
              boostRemaining: 0,
              boostStillNeeded: 0,
            )));

    // Uncomment the next line to simulate that the App refused the pardon
    _acceptPardon = false;

    // Uncomment the next line to simulate that the App refused the boost
    _acceptBoost = false;
  }

  @override
  String get opaqueUserId => 'U0123456789';

  @override
  Future<MessageProtocol> _sendMessageToApp(ToAppMessages request) async {
    switch (request) {
      case ToAppMessages.pardonRequest:
        return MessageProtocol(
            from: MessageFrom.app,
            to: MessageTo.frontend,
            type: MessageTypes.response,
            isSuccess: _acceptPardon);
      case ToAppMessages.boostRequest:
        return MessageProtocol(
            from: MessageFrom.app,
            to: MessageTo.frontend,
            type: MessageTypes.response,
            isSuccess: _acceptBoost);
      case ToAppMessages.gameStateRequest:
        return MessageProtocol(
            from: MessageFrom.app,
            to: MessageTo.frontend,
            type: MessageTypes.response,
            isSuccess: true,
            data: jsonDecode(jsonEncode({
              'game_state': SimplifiedGameState(
                status: GameStatus.roundStarted,
                round: 1,
                pardonRemaining: 1,
                pardonners: [],
                boostRemaining: 0,
                boostStillNeeded: 0,
              ).serialize(),
            })));
    }
  }
}
