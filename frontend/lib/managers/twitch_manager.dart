import 'dart:async';
import 'dart:convert';

import 'package:common/models/ebs_helpers.dart';
import 'package:frontend/managers/game_manager.dart';
import 'package:logging/logging.dart';
import 'package:twitch_manager/twitch_manager.dart' as tm;

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
    final response =
        await _sendMessageToEbs(FromFrontendToEbsMessages.pardonRequest);
    return response.isSuccess ?? false;
  }

  ///
  /// Callback to know when the TwitchManager has connected to the Twitch
  /// backend services.
  final _isInitializedCompleter = Completer();
  Future<void> get onFinishedInitializing => _isInitializedCompleter.future;
  bool get isInitialized => _isInitializedCompleter.isCompleted;
  Future<void> _onFinishedInitializing() async {
    _logger.info('Connected to Twitch service');
    _isInitializedCompleter.complete();
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

    // Try to register to the game. This will fail if the game has not started,
    // but we don't care about that. If the game is indeed started, we will be
    // registered to it.
    _registerToGame();
  }

  Future<void> _onPubSubMessageReceived(String raw) async {
    try {
      final message = jsonDecode(raw.replaceAll('\'', '"'));
      final type = FromEbsToFrontendMessages.values[message['type']];
      final data = message['data'];

      switch (type) {
        case FromEbsToFrontendMessages.ping:
          _logger.info('PING received');
          break;

        case FromEbsToFrontendMessages.gameStarted:
          // Register to the game when the game has started
          _registerToGame();
          break;

        case FromEbsToFrontendMessages.pardonStatusUpdate:
          _pardonnersChanged(data);
          break;

        case FromEbsToFrontendMessages.gameEnded:
          // TODO : Show the game ended screen
          break;
      }
    } catch (e) {
      _logger.severe('Message from Twitch: $raw');
    }
  }

  Future<void> _registerToGame() async {
    final response =
        await _sendMessageToEbs(FromFrontendToEbsMessages.registerToGame);
    final isSuccess = response.isSuccess ?? false;
    if (!isSuccess) {
      _logger.info('No game started yet');
      return;
    }

    _logger.info('Registered to game');
    GameManager.instance.startGame();
  }

  Future<void> _pardonnersChanged(Map<String, dynamic> data) async {
    GameManager.instance
        .newPardonners(List<String>.from(data['pardonner_user_id']));
  }

  ///
  /// Send a message to the EBS based on the [fromTo] of message.
  Future<MessageProtocol> _sendMessageToEbs(
      FromFrontendToEbsMessages fromTo) async {
    if (!isInitialized) {
      _logger.severe('TwitchManager is not initialized');
      throw Exception('TwitchManager is not initialized');
    }

    try {
      final message = MessageProtocol(fromTo: fromTo);
      final response = await _frontendManager!.apiToEbs
          .postRequest(fromTo.asEndpoint(), message.toJson());
      _logger.info('Message sent to EBS: $response');
      return MessageProtocol.fromJson(response);
    } catch (e) {
      _logger.severe('Failed to send message to EBS: $e');
      return MessageProtocol(fromTo: fromTo, isSuccess: false);
    }
  }
}

class TwitchManagerMock extends TwitchManager {
  TwitchManagerMock() : super._() {
    _onFinishedInitializing();
  }

  @override
  Future<void> _callTwitchFrontendManagerFactory() async {
    // Try to register to the game. This will fail if the game has not started,
    // but we don't care about that. If the game is indeed started, we will be
    // registered to it.
    _registerToGame();
  }

  @override
  String get opaqueUserId => 'U0123456789';

  @override
  Future<MessageProtocol> _sendMessageToEbs(
      FromFrontendToEbsMessages fromTo) async {
    switch (fromTo) {
      case FromFrontendToEbsMessages.registerToGame:
        return MessageProtocol(
            fromTo: FromFrontendToEbsMessages.registerToGame, isSuccess: true);
      case FromFrontendToEbsMessages.pardonRequest:
        return MessageProtocol(
            fromTo: FromFrontendToEbsMessages.pardonRequest, isSuccess: true);
    }
  }
}
