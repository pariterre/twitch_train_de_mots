import 'package:train_de_mots/models/word_problem.dart';
import 'package:twitch_manager/twitch_manager.dart';

class Configuration {
  final int nbLetterInSmallestWord = 5;
  final int minimumWordLetter = 6;
  final int maximumWordLetter = 8;
  final int minimumWordsNumber = 12;
  final int maximumWordsNumber = 20;

  static final Configuration _instance = Configuration._internal();
  Configuration._internal();
  static Configuration get instance => _instance;

  Future<void> initialize() async {
    await WordProblem.initialize();
  }

  final isTwitchMockActive = true;
  final twitchDebugOptions = TwitchDebugPanelOptions(chatters: [
    TwitchChatterMock(displayName: 'Viewer1'),
    TwitchChatterMock(displayName: 'Viewer2'),
    TwitchChatterMock(displayName: 'Viewer3'),
  ]);
  final twitchAppInfo = TwitchAppInfo(
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
}
