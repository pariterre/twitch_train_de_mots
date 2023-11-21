import 'package:flutter/material.dart';
import 'package:twitch_manager/models/twitch_listener.dart';
import 'package:twitch_manager/twitch_manager.dart';

class TwitchInterface {
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
  TwitchDebugOverlay debugOverlay({required child}) => TwitchDebugOverlay(
        manager: _manager!,
        child: child,
      );

  ///
  /// Provide an easy access to the TwitchManager connect dialog
  Future<bool> showConnectManagerDialog(BuildContext context) async {
    if (_manager != null) return true; // Already connected

    final manager = await showDialog<TwitchManager>(
        context: context,
        builder: (context) => TwitchAuthenticationScreen(
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
    return true;
  }

  /// -------- ///
  /// INTERNAL ///
  /// -------- ///
  TwitchManager? _manager;

  ///
  /// Declare the singleton
  static final TwitchInterface _instance = TwitchInterface._internal();
  TwitchInterface._internal();
  static TwitchInterface get instance => _instance;

  ///
  /// Twitch options
  final _isMockActive = true;
  final _debugOptions = TwitchDebugPanelOptions(chatters: [
    TwitchChatterMock(displayName: 'Viewer1'),
    TwitchChatterMock(displayName: 'Viewer2'),
    TwitchChatterMock(displayName: 'Viewer3'),
  ]);
  final _appInfo = TwitchAppInfo(
    appName: 'Train de mots',
    twitchAppId: '75yy5xbnj3qn2yt27klxrqm6zbbr4l',
    scope: const [
      TwitchScope.chatRead,
      TwitchScope.readFollowers,
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
