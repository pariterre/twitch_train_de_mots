import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:train_de_mots/managers/mocks_configuration.dart';
import 'package:train_de_mots/models/custom_callback.dart';
import 'package:twitch_manager/models/twitch_listener.dart';
import 'package:twitch_manager/twitch_manager.dart' as tm;

final _logger = Logger('TwitchManager');

class TwitchManager {
  final onTwitchManagerReady = CustomCallback();

  void initialize({bool useMock = false}) {
    _isMockActive = useMock;
  }

  ///
  /// Get if the manager is connected or not
  bool get hasManager => _manager != null;
  bool get hasNotManager => !hasManager;

  ///
  /// Call all the listeners when a message is received
  void addChatListener(Function(String sender, String message) callback) {
    _logger.info('Adding chat listener');
    _chatListeners.startListening(callback);
  }

  ///
  /// Provide an easy access to the Debug Overlay Widget
  tm.TwitchAppDebugOverlay debugOverlay({required child}) =>
      tm.TwitchAppDebugOverlay(manager: _manager!, child: child);

  ///
  /// Provide an easy access to the TwitchManager connect dialog
  Future<bool> showConnectManagerDialog(BuildContext context) async {
    _logger.info('Showing connect manager dialog...');

    if (_manager != null) {
      // Already connected
      _logger.warning('Manager already connected');
      return true;
    }

    final manager = await showDialog<tm.TwitchAppManager>(
        context: context,
        builder: (context) => tm.TwitchAppAuthenticationDialog(
              isMockActive: _isMockActive,
              debugPanelOptions: MocksConfiguration.twitchDebugPanelOptions,
              onConnexionEstablished: (manager) =>
                  Navigator.of(context).pop(manager),
              appInfo: _appInfo,
              reload: true,
            ));
    if (manager == null) return false;

    _manager = manager;
    _manager!.chat.onMessageReceived.startListening(_onMessageReceived);
    onTwitchManagerReady.notifyListeners();

    _logger.info('Manager connected');
    return true;
  }

  /// -------- ///
  /// INTERNAL ///
  /// -------- ///
  tm.TwitchAppManager? _manager;

  ///
  /// Declare the singleton
  static final TwitchManager _instance = TwitchManager._internal();
  TwitchManager._internal();
  static TwitchManager get instance => _instance;

  ///
  /// Twitch options
  bool _isMockActive = false;
  final _appInfo = tm.TwitchAppInfo(
      appName: 'Train de mots',
      twitchClientId: '75yy5xbnj3qn2yt27klxrqm6zbbr4l',
      scope: const [
        tm.TwitchScope.chatRead,
        tm.TwitchScope.readFollowers,
      ],
      twitchRedirectUri: Uri.https(
          'twitchauthentication.pariterre.net', 'twitch_redirect.html'),
      authenticationServerUri:
          Uri.https('twitchserver.pariterre.net:3000', 'token'));

  ///
  /// Get the broadcaster id
  int get broadcasterId => _manager!.api.streamerId;

  ///
  /// Holds the callback to call when a message is received
  final _chatListeners =
      TwitchGenericListener<Function(String sender, String message)>();
  void _onMessageReceived(String sender, String message) =>
      _chatListeners.notifyListeners((callback) => callback(sender, message));
}
