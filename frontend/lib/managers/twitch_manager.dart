import 'package:twitch_manager/twitch_manager.dart' as tm;

class TwitchManager {
  // Declare the singleton instance of the TwitchManager
  static final _instance = TwitchManager._();
  static TwitchManager get instance => _instance;
  TwitchManager._() {
    tm.TwitchFrontendManager.factory(
      appInfo: tm.TwitchFrontendInfo(
        appName: 'Train de mots',
        ebsUri: Uri.parse('http://localhost:3010/frontend'),
      ),
    );
  }

  // Initialize the TwitchManager
  static Future<void> initialize() async => instance;
}
