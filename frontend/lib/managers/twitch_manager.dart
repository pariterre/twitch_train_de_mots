import 'dart:async';
import 'dart:convert';

import 'package:common/models/ebs_helpers.dart';
import 'package:frontend/managers/game_manager.dart';
import 'package:logging/logging.dart';
import 'package:twitch_manager/twitch_manager.dart' as tm;

final _logger = Logger('TwitchManagerMain');

class TwitchManager {
  ///
  /// Interface reference to the TwitchFrontendManager.
  tm.TwitchFrontendManager? _frontendManager;

  ///
  /// Initialize the TwitchManager
  static Future<void> initialize() async => instance;

  ///
  /// Get the opaque user ID of the current user. This is the ID that is used
  /// to identify the user in the game. The EBS is well aware of this ID and
  /// can use it to identify the user even if it is opaque.
  String get opaqueUserId {
    if (_frontendManager == null) {
      _logger.severe('TwitchManager is not initialized');
      throw Exception('TwitchManager is not initialized');
    }

    return _frontendManager!.authenticator.opaqueUserId;
  }

  ///
  /// Post a request to pardon the stealer. No confirmation is received from
  /// the EBS. If the request is successful, the stealer is pardoned and a message
  /// is sent to PubSub.
  Future<void> pardonStealer() async =>
      await _sendMessageToEbs(FromFrontendToEbsMessages.pardonRequest);

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
  static final _instance = TwitchManager._();
  static TwitchManager get instance => _instance;
  TwitchManager._() {
    tm.TwitchFrontendManager.factory(
      appInfo: tm.TwitchFrontendInfo(
          appName: 'Train de mots',
          ebsUri: Uri.parse('http://localhost:3010/frontend')),
      isTwitchUserIdRequired: true,
      onConnectedToTwitchService: _onFinishedInitializing,
      pubSubCallback: _onPubSubMessageReceived,
    ).then((manager) {
      _frontendManager = manager;

      // Try to register to the game. This will fail if the game has not started,
      // but we don't care about that. If the game is indeed started, we will be
      // registered to it.
      _hasRegisteredToGame();
    });
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
          _hasRegisteredToGame();
          break;

        case FromEbsToFrontendMessages.pardonStatusUpdate:
          _pardonnersChanged(data);
          break;
      }
    } catch (e) {
      _logger.severe('Message from Twitch: $raw');
    }
  }

  Future<void> _hasRegisteredToGame() async {
    final response =
        await _sendMessageToEbs(FromFrontendToEbsMessages.registerToGame);
    if (response?['status'] != 'OK') {
      _logger.info('No game started yet');
      return;
    }

    _logger.info('Registered to game');
    GameManager.instance.startGame();
  }

  Future<void> _pardonnersChanged(Map<String, dynamic> data) async {
    GameManager.instance
        .newPardonners(List<String>.from(data['users_who_can_pardon']));
  }

  ///
  /// Send a message to the EBS based on the [type] of message.
  Future<Map<String, dynamic>?> _sendMessageToEbs(
      FromFrontendToEbsMessages type) async {
    if (!isInitialized) {
      _logger.severe('TwitchManager is not initialized');
      throw Exception('TwitchManager is not initialized');
    }

    try {
      return await _frontendManager!.apiToEbs.postRequest(type.asEndpoint());
    } catch (e) {
      _logger.severe('Error sending message to EBS: $e');
      return null;
    }
  }
}
