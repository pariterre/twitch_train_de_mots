import 'package:common/models/custom_callback.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:train_de_mots/generic/managers/mocks_configuration.dart';
import 'package:twitch_manager/twitch_app.dart';
import 'package:twitch_manager/twitch_utils.dart';

final _logger = Logger('TwitchManager');

class TwitchManager {
  final onTwitchManagerHasConnected = CustomCallback();
  final onTwitchManagerHasDisconnected = CustomCallback();

  static Future<TwitchManager> factory({required TwitchAppInfo appInfo}) async {
    return TwitchManager._(appInfo: appInfo);
  }

  ///
  /// Get if the manager is connected or not
  bool get isConnected => _manager != null;
  bool get isNotConnected => !isConnected;

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

  ///
  /// Provide an easy access to the TwitchManager connect dialog
  Future<bool> showConnectManagerDialog(BuildContext context,
      {bool reloadIfPossible = true}) async {
    _logger.info('Showing connect manager dialog...');

    if (_manager != null) {
      // Already connected
      _logger.warning('TwitchManager already connected');
      return true;
    }

    final manager = await showDialog<TwitchAppManager>(
        context: context,
        builder: (context) => TwitchAppAuthenticationDialog(
              useMocker: _useMocker,
              debugPanelOptions: MocksConfiguration.twitchDebugPanelOptions,
              onConnexionEstablished: (manager) {
                if (context.mounted) Navigator.of(context).pop(manager);
              },
              appInfo: appInfo,
              reload: reloadIfPossible,
            ));
    if (manager == null) return false;

    _manager = manager;
    _manager!.chat.onMessageReceived.listen(_onMessageReceived);
    onTwitchManagerHasConnected.notifyListeners();

    _logger.info('TwitchManager connected');
    return true;
  }

  Future<bool> disconnect() {
    if (_manager == null) {
      _logger.warning('TwitchManager already disconnected');
      return Future.value(true);
    }

    _manager!.disconnect();
    _manager = null;
    onTwitchManagerHasDisconnected.notifyListeners();

    _logger.info('TwitchManager disconnected');
    return Future.value(true);
  }

  /// -------- ///
  /// INTERNAL ///
  /// -------- ///
  TwitchAppManager? _manager;

  ///
  /// Declare the singleton
  TwitchManager._({required this.appInfo});

  ///
  /// Twitch options
  bool _useMocker = false;
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

class TwitchManagerMock extends TwitchManager {
  TwitchManagerMock._({required super.appInfo}) : super._();

  static Future<TwitchManagerMock> factory(
      {required TwitchAppInfo appInfo}) async {
    final instance = TwitchManagerMock._(appInfo: appInfo);
    instance._useMocker = true;
    return instance;
  }
}
