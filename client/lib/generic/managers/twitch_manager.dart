import 'dart:math';

import 'package:common/generic/models/generic_listener.dart';
import 'package:common/generic/models/serializable_game_state.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:train_de_mots/mocks_configuration.dart';
import 'package:twitch_manager/twitch_app.dart';

final _logger = Logger('TwitchManager');

abstract class IntegrationManager {
  IntegrationManagerType get type => IntegrationManagerType.none;

  String get broadcasterId;

  final onHasTriedConnecting =
      GenericListener<Function({required bool isSuccess})>();
  final onHasDisconnected = GenericListener();

  bool get isInitialized;

  bool get isConnected;
  bool get isNotConnected => !isConnected;

  Future<void> connect();

  Future<bool> disconnect();

  Widget debugOverlay({required Widget child});

  void addChatListener(Function(String login, String message) callback);

  Future<String?> displayNameFromLogin(String login);
}

class NoIntegrationManager extends IntegrationManager {
  @override
  IntegrationManagerType get type => IntegrationManagerType.noIntegration;

  String? _broadcasterId;
  @override
  String get broadcasterId {
    if (isNotConnected) {
      throw Exception(
          'The manager is not connected, broadcaster ID is not available');
    }

    return _broadcasterId!;
  }

  @override
  bool get isInitialized => true;

  bool _isConnected = false;
  @override
  bool get isConnected => _isConnected;

  @override
  Future<void> connect({BuildContext? context}) async {
    if (context == null) {
      throw Exception('No context provided for TwitchManager connect dialog');
    }

    // Create a random broadcaster ID consisting of Alphanumeric characters
    final random = Random();
    _broadcasterId = List.generate(6, (index) {
      const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
      return chars[random.nextInt(chars.length)];
    }).join();

    _isConnected = _broadcasterId != null;
    await onHasTriedConnecting
        .notifyListeners((callback) => callback(isSuccess: isConnected));
    return;
  }

  @override
  Future<bool> disconnect() async {
    _isConnected = false;
    await onHasDisconnected.notifyListeners((callback) => callback());
    return true;
  }

  @override
  Widget debugOverlay({required Widget child}) {
    return Stack(
      children: [
        child,
      ],
    );
  }

  @override
  void addChatListener(Function(String login, String message) callback) {
    // No integration, so no chat to listen to
  }

  @override
  Future<String?> displayNameFromLogin(String login) async {
    return login;
  }
}

class TwitchIntegrationManager extends IntegrationManager {
  @override
  IntegrationManagerType get type => IntegrationManagerType.twitch;

  bool _isInitialized = false;
  @override
  bool get isInitialized => _isInitialized;
  TwitchIntegrationManager({required this.appInfo}) {
    _asyncInitializations();
  }

  Future<void> _asyncInitializations() async {
    _logger.config('Initializing...');
    _isInitialized = true;
    await _tryAutomaticConnect();
    _logger.config('Ready');
    return Future.value();
  }

  ///
  /// Get if the manager is connected or not
  @override
  bool get isConnected => _manager != null && _manager!.isConnected;
  bool _isConnecting = false;
  bool get isConnecting => _isConnecting;

  ///
  /// Call all the listeners when a message is received
  @override
  void addChatListener(Function(String login, String message) callback) {
    _logger.info('Adding chat listener');
    _chatListeners.listen(callback);
  }

  @override
  Future<String?> displayNameFromLogin(String login) async {
    if (isNotConnected) {
      _logger.warning(
          'Cannot get display name from login $login because TwitchManager is not connected');
      return null;
    }
    final user = await _manager!.api.user(login: login);
    return user?.displayName;
  }

  ///
  /// Provide an easy access to the Debug Overlay Widget
  @override
  Widget debugOverlay({required Widget child}) =>
      TwitchAppDebugOverlay(manager: _manager!, child: child);

  Future<void> _tryAutomaticConnect() async {
    _isConnecting = true;
    _manager = await (_useMocker
        ? TwitchAppManagerMock.factory(
            appInfo: appInfo,
            debugPanelOptions: MocksConfiguration.twitchDebugPanelOptions)
        : TwitchAppManager.factory(appInfo: appInfo, reload: true));

    _isConnecting = false;
    await _finalizeConnexion();
  }

  ///
  /// Provide an easy access to the TwitchManager connect dialog
  @override
  Future<bool> connect(
      {BuildContext? context, bool reloadIfPossible = true}) async {
    _logger.info('Showing connect manager dialog...');
    if (context == null) {
      throw Exception('No context provided for TwitchManager connect dialog');
    }

    if (isConnected) {
      // Already connected
      _logger.warning('TwitchManager already connected');
      return true;
    }
    _isConnecting = true;

    _manager = await showTwitchAppAuthenticationDialog(
      context,
      useMocker: _useMocker,
      debugPanelOptions: MocksConfiguration.twitchDebugPanelOptions,
      appInfo: appInfo,
      reload: reloadIfPossible,
    );
    _isConnecting = false;
    await _finalizeConnexion();
    return true;
  }

  Future<void> _finalizeConnexion() async {
    await onHasTriedConnecting
        .notifyListeners((callback) => callback(isSuccess: isConnected));
    if (isNotConnected) return;

    _manager!.chat.onMessageReceived.listen(_onMessageReceived);
    _logger.info('TwitchManager connected');
  }

  @override
  Future<bool> disconnect() {
    if (_manager == null) {
      _logger.warning('TwitchManager already disconnected');
      return Future.value(true);
    }

    _manager!.disconnect();
    _manager = null;
    onHasDisconnected.notifyListeners((callback) => callback());

    _logger.info('TwitchManager disconnected');
    return Future.value(true);
  }

  /// -------- ///
  /// INTERNAL ///
  /// -------- ///
  TwitchAppManager? _manager;

  ///
  /// Twitch options
  bool get _useMocker => this is TwitchIntegrationManagerMocked;
  final TwitchAppInfo appInfo;

  ///
  /// Get the broadcaster id
  @override
  String get broadcasterId => _manager!.api.streamerId;

  ///
  /// Holds the callback to call when a message is received
  final _chatListeners =
      TwitchListener<Function(String login, String message)>();
  void _onMessageReceived(String login, String message) =>
      _chatListeners.notifyListeners((callback) => callback(login, message));
}

class TwitchIntegrationManagerMocked extends TwitchIntegrationManager {
  TwitchIntegrationManagerMocked({required super.appInfo});
}
