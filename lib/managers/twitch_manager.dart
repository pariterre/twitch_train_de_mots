import 'package:flutter/material.dart';
import 'package:train_de_mots/models/custom_callback.dart';
import 'package:twitch_manager/models/twitch_listener.dart';
import 'package:twitch_manager/twitch_manager.dart' as tm;

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
  void addChatListener(Function(String sender, String message) callback) =>
      _chatListeners.add(callback.hashCode.toString(), callback);

  ///
  /// Provide an easy access to the Debug Overlay Widget
  tm.TwitchDebugOverlay debugOverlay({required child}) =>
      tm.TwitchDebugOverlay(manager: _manager!, child: child);

  ///
  /// Provide an easy access to the TwitchManager connect dialog
  Future<bool> showConnectManagerDialog(BuildContext context) async {
    if (_manager != null) return true; // Already connected

    final manager = await showDialog<tm.TwitchManager>(
        context: context,
        builder: (context) => tm.TwitchAuthenticationScreen(
              isMockActive: _isMockActive,
              debugPanelOptions: _debugOptions,
              onFinishedConnexion: (manager) {
                Navigator.of(context).pop(manager);
              },
              appInfo: _appInfo,
              reload: true,
            ));
    if (manager == null) return false;

    _manager = manager;
    _manager!.chat.onMessageReceived(_onMessageReceived);
    onTwitchManagerReady.notifyListeners();
    return true;
  }

  /// -------- ///
  /// INTERNAL ///
  /// -------- ///
  tm.TwitchManager? _manager;

  ///
  /// Declare the singleton
  static final TwitchManager _instance = TwitchManager._internal();
  TwitchManager._internal();
  static TwitchManager get instance => _instance;

  ///
  /// Twitch options
  bool _isMockActive = false;
  final _debugOptions = tm.TwitchDebugPanelOptions(chatters: [
    tm.TwitchChatterMock(displayName: 'Viewer1'),
    tm.TwitchChatterMock(displayName: 'Viewer2'),
    tm.TwitchChatterMock(displayName: 'Viewer3'),
  ]);
  final _appInfo = tm.TwitchAppInfo(
    appName: 'Train de mots',
    twitchAppId: '75yy5xbnj3qn2yt27klxrqm6zbbr4l',
    scope: const [
      tm.TwitchScope.chatRead,
      tm.TwitchScope.readFollowers,
    ],
    redirectAddress: 'https://twitchauthentication.pariterre.net:3000',
    useAuthenticationService: true,
    authenticationServiceAddress:
        'wss://twitchauthentication.pariterre.net:3002',
  );

  ///
  /// Holds the callback to call when a message is received
  final _chatListeners =
      TwitchGenericListener<Function(String sender, String message)>();
  void _onMessageReceived(String sender, String message) {
    for (final listener in _chatListeners.listeners.values) {
      listener(sender, message);
    }
  }
}
