import 'package:common/generic/models/generic_listener.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:train_de_mots/mocks_configuration.dart';
import 'package:twitch_manager/twitch_app.dart';
import 'package:twitch_manager/twitch_utils.dart';

final _logger = Logger('TwitchManager');

class TwitchManager {
  final onTwitchManagerHasTriedConnecting =
      GenericListener<Function({required bool isSuccess})>();
  final onTwitchManagerHasDisconnected = GenericListener();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  TwitchManager({required this.appInfo}) {
    _asyncInitializations();
  }

  Future<void> _asyncInitializations() async {
    _logger.config('Initializing...');
    _isInitialized = true;
    _tryAutomaticConnect();
    _logger.config('Ready');
  }

  ///
  /// Get if the manager is connected or not
  bool get isConnected => _manager != null && _manager!.isConnected;
  bool get isNotConnected => !isConnected;
  bool _isConnecting = false;
  bool get isConnecting => _isConnecting;

  ///
  /// Call all the listeners when a message is received
  void addChatListener(Function(String sender, String message) callback) {
    _logger.info('Adding chat listener');
    _chatListeners.listen(callback);
  }

  ///
  /// Provide an easy access to the Debug Overlay Widget
  TwitchAppDebugOverlay debugOverlay({required child}) =>
      TwitchAppDebugOverlay(manager: _manager!, child: child);

  Future<void> _tryAutomaticConnect() async {
    _isConnecting = true;
    _manager = await (_useMocker
        ? TwitchManagerMock.factory(
            appInfo: appInfo,
            debugPanelOptions: MocksConfiguration.twitchDebugPanelOptions)
        : TwitchAppManager.factory(appInfo: appInfo, reload: true));

    _isConnecting = false;
    _finalizeConnexion();
  }

  ///
  /// Provide an easy access to the TwitchManager connect dialog
  Future<bool> showConnectManagerDialog(BuildContext context,
      {bool reloadIfPossible = true}) async {
    _logger.info('Showing connect manager dialog...');

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
      onConnexionEstablished: (manager) {
        if (context.mounted) Navigator.of(context).pop(manager);
      },
      onCancelConnexion: () => Navigator.of(context).pop(),
      appInfo: appInfo,
      reload: reloadIfPossible,
    );
    _isConnecting = false;
    _finalizeConnexion();
    return true;
  }

  void _finalizeConnexion() {
    onTwitchManagerHasTriedConnecting
        .notifyListeners((callback) => callback(isSuccess: isConnected));
    if (isNotConnected) return;

    _manager!.chat.onMessageReceived.listen(_onMessageReceived);
    _logger.info('TwitchManager connected');
  }

  Future<bool> disconnect() {
    if (_manager == null) {
      _logger.warning('TwitchManager already disconnected');
      return Future.value(true);
    }

    _manager!.disconnect();
    _manager = null;
    onTwitchManagerHasDisconnected.notifyListeners((callback) => callback());

    _logger.info('TwitchManager disconnected');
    return Future.value(true);
  }

  /// -------- ///
  /// INTERNAL ///
  /// -------- ///
  TwitchAppManager? _manager;

  ///
  /// Twitch options
  bool get _useMocker => this is TwitchManagerMocked;
  final TwitchAppInfo appInfo;

  ///
  /// Get the broadcaster id
  int get broadcasterId => _manager!.api.streamerId;

  ///
  /// Holds the callback to call when a message is received
  final _chatListeners =
      TwitchListener<Function(String sender, String message)>();
  void _onMessageReceived(String sender, String message) =>
      _chatListeners.notifyListeners((callback) => callback(sender, message));
}

class TwitchManagerMocked extends TwitchManager {
  TwitchManagerMocked({required super.appInfo});
}
