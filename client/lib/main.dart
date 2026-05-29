import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:train_de_mots/generic/managers/managers.dart';
import 'package:train_de_mots/generic/screens/main_screen.dart';
import 'package:train_de_mots/mocks_configuration.dart';
import 'package:train_de_mots/release_notes.dart';
import 'package:twitch_manager/twitch_app.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

final _logger = Logger('Main');

void main() {
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    // Print to a file
    final message =
        '${record.time}: ${record.loggerName}: ${record.level.name}: ${record.message}';
    debugPrint(message);
  });

  _logger.info('Bienvenue au Train de mots !');
  _logger.info(
      'La version utilisée est la suivante : ${releaseNotes.last.version}');

  // Initialize singleton
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const GlobalTicker());
}

class GlobalTicker extends StatefulWidget {
  const GlobalTicker({super.key});

  @override
  State<GlobalTicker> createState() => _GlobalTickerState();
}

class _GlobalTickerState extends State<GlobalTicker>
    with SingleTickerProviderStateMixin {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      supportedLocales: [Locale('fr', '')],
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        final images = [
          'packages/common/assets/images/train.png',
          'packages/common/assets/images/parchment.png',
          'packages/common/assets/images/treasure_hunt/blueberries.png',
          'packages/common/assets/images/treasure_hunt/grass.png',
          'packages/common/assets/images/treasure_hunt/open_grass.png',
          'packages/common/assets/images/blueberry_war/blueberries.png',
          'packages/common/assets/images/warehouse_cleaning/box.png',
          'packages/common/assets/images/warehouse_cleaning/floor.png',
          'packages/common/assets/images/track_fix/grass.png',
          'packages/common/assets/images/track_fix/open_grass.png',
        ];

        for (final image in images) {
          precacheImage(AssetImage(image), context);
        }

        return child!;
      },
      home: FutureBuilder(
        future: Managers.initialize(
          vsync: this,
          twitchAppInfo: TwitchAppInfo(
            appName: 'Train de mots',
            twitchClientId: '539pzk7h6vavyzmklwy6msq6k3068x',
            scope: const [
              TwitchAppScope.chatRead,
              TwitchAppScope.readFollowers,
            ],
            twitchRedirectUri: Uri.https(
                'twitchauthentication.pariterre.net', 'twitch_redirect.html'),
            authenticationServerUri:
                Uri.https('twitchserver.pariterre.net:3000', 'token'),
            authenticationFlow: TwitchAuthenticationFlow.authorizationCode,
            ebsUri: MocksConfiguration.useLocalEbs
                ? Uri.parse('ws://localhost:3011')
                : Uri.parse('wss://twitchserver.pariterre.net:3011'),
          ),
        ),
        builder: (context, state) {
          return state.connectionState != ConnectionState.done
              ? Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              : MainScreen();
        },
      ),
    );
  }
}
