import 'dart:async';
import 'dart:convert';

import 'package:common/models/ebs_helpers.dart';
import 'package:logging/logging.dart';
import 'package:twitch_manager/twitch_manager.dart' as tm;
import 'package:twitch_manager/models/twitch_listener.dart';

final _logger = Logger('TwitchManagerMain');

class TwitchManager {
  ///
  /// Flag to check if the frontend is connected to the EBS. This is used to
  /// prevent the programmer from calling the methods before the Twitch
  /// frontend has connected to the EBS. If ones need to know when the
  /// frontend has connected to the EBS, they can listen to the
  /// [onHasConnectedToEbs] stream.
  bool _isConnectedToEbs = false;
  final _hasConnectedToEbsCompleter = Completer<bool>();
  Future<bool> get onHasConnectedToEbs => _hasConnectedToEbsCompleter.future;

  ///
  /// Interface reference to the TwitchFrontendManager.
  tm.TwitchFrontendManager? _frontendManager;

  ///
  /// Setup listeners for all the messages that come from the EBS.
  final onPardonStatusUpdate = TwitchGenericListener();

  String get opaqueUserId {
    if (_frontendManager == null) {
      _logger.severe('TwitchManager is not initialized');
      throw Exception('TwitchManager is not initialized');
    }

    return _frontendManager!.authenticator.opaqueUserId;
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
        ebsUri: Uri.parse('http://localhost:3010/frontend'),
      ),
      initializeEndpoint: '/initialize',
      isTwitchUserIdRequired: true,
      onHasConnectedCallback: () async {
        _logger.info('Connected to Twitch');
        _isConnectedToEbs = true;
        _hasConnectedToEbsCompleter.complete(_isConnectedToEbs);
      },
      pubSubCallback: _onPubSubMessageReceived,
    ).then((manager) {
      _frontendManager = manager;
      // Try to register to the game. This will fail if the game has not started.
      _sendMessageToEbs(FromFrontendToEbsMessages.registerToGame);
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
          _sendMessageToEbs(FromFrontendToEbsMessages.registerToGame);
          break;

        case FromEbsToFrontendMessages.pardonStatusUpdate:
          final users = List<String>.from(data['users_who_can_pardon']);
          onPardonStatusUpdate.notifyListeners((callback) => callback(users));
          break;
      }
    } catch (e) {
      _logger.severe('Error parsing message from EBS: $raw');
    }
  }

  ///
  /// Post a request to pardon the stealer. No confirmation is received from
  /// the EBS. If the request is successful, the stealer is pardoned and a message
  /// is sent to PubSub.
  Future<void> pardonStealer() async =>
      await _sendMessageToEbs(FromFrontendToEbsMessages.pardonRequest);

  ///
  /// Send a message to the EBS based on the [type] of message.
  Future<Map<String, dynamic>> _sendMessageToEbs(
      FromFrontendToEbsMessages type) async {
    if (!_isInitialized) {
      _logger.severe('TwitchManager is not initialized');
      throw Exception('TwitchManager is not initialized');
    }

    return await _frontendManager!.apiToEbs.post(type.asEndpoint());
  }

  bool get _isInitialized {
    // If the programmer forgets to call TwitchManager.initialize()
    if (_frontendManager == null) return false;

    // If the programmer calls the pardon method before the TwitchManager has connected
    if (!_isConnectedToEbs) return false;

    return true;
  }

  // Initialize the TwitchManager
  static Future<void> initialize() async => instance;
}
