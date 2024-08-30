import 'package:logging/logging.dart';
import 'package:twitch_manager/twitch_manager.dart' as tm;

final _logger = Logger('TwitchManagerMain');

class TwitchManager {
  tm.TwitchFrontendManager? _frontendManager;

  // Declare the singleton instance of the TwitchManager
  static final _instance = TwitchManager._();
  static TwitchManager get instance => _instance;
  TwitchManager._() {
    tm.TwitchFrontendManager.factory(
        appInfo: tm.TwitchFrontendInfo(
          appName: 'Train de mots',
          ebsUri: Uri.parse('http://localhost:3010/frontend'),
        ),
        onHasConnectedCallback: () async {
          final answer = await _frontendManager?.api.coucou();
          _logger.info('Message from the server: ${answer?['message']}');
        }).then((manager) => _frontendManager = manager);
  }

  // Initialize the TwitchManager
  static Future<void> initialize() async => instance;
}
