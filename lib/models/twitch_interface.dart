import 'package:twitch_manager/models/twitch_listener.dart';
import 'package:twitch_manager/twitch_manager.dart';

class TwitchInterface {
  // Declare the singleton
  static final TwitchInterface _instance = TwitchInterface._internal();
  TwitchInterface._internal();
  static TwitchInterface get instance => _instance;

  // Twitch manager section
  bool get hasManager => _manager != null;
  bool get hasNotManager => !hasManager;
  TwitchManager? _manager;
  set manager(TwitchManager value) {
    if (_manager != null) {
      throw Exception('Cannot set the twitch manager twice');
    }
    _manager = value;
    _manager!.chat.onMessageReceived((sender, message) {
      for (final listener in _chatListeners.listeners.values) {
        listener(sender, message);
      }
    });
  }

  // Twitch mocker
  TwitchDebugOverlay debugOverlay({required child}) => TwitchDebugOverlay(
        manager: _manager!,
        child: child,
      );
  final isMockActive = true;
  final debugOptions = TwitchDebugPanelOptions(chatters: [
    TwitchChatterMock(displayName: 'Viewer1'),
    TwitchChatterMock(displayName: 'Viewer2'),
    TwitchChatterMock(displayName: 'Viewer3'),
  ]);
  final appInfo = TwitchAppInfo(
    appName: 'Train de mots',
    twitchAppId: 'YOUR_APP_ID_HERE',
    scope: const [
      TwitchScope.chatRead,
      TwitchScope.readFollowers,
    ],
    redirectAddress: 'TO_FILL',
    useAuthenticationService: true,
    authenticationServiceAddress: 'wss://localhost:3002',
  );

  final _chatListeners =
      TwitchGenericListener<Function(String sender, String message)>();
  void addChatListener(Function(String sender, String message) callback) =>
      _chatListeners.add(callback.hashCode.toString(), callback);
}
