import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:train_de_mots/generic/managers/managers.dart';
import 'package:train_de_mots/generic/screens/main_screen.dart';
import 'package:train_de_mots/mocks_configuration.dart';
import 'package:twitch_manager/twitch_app.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    // Print to a file
    final message =
        '${record.time}: ${record.loggerName}: ${record.level.name}: ${record.message}';
    debugPrint(message);
  });

  // Initialize singleton
  WidgetsFlutterBinding.ensureInitialized();
  await Managers.initialize(
    twtichAppInfo: TwitchAppInfo(
        appName: 'Train de mots',
        twitchClientId: '75yy5xbnj3qn2yt27klxrqm6zbbr4l',
        scope: const [
          TwitchAppScope.chatRead,
          TwitchAppScope.readFollowers,
        ],
        twitchRedirectUri: Uri.https(
            'twitchauthentication.pariterre.net', 'twitch_redirect.html'),
        authenticationServerUri:
            Uri.https('twitchserver.pariterre.net:3000', 'token')),
    ebsUri: MocksConfiguration.useLocalEbs
        ? Uri.parse('ws://localhost:3010')
        : Uri.parse('wss://twitchserver.pariterre.net:3010'),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MainScreen(),
      supportedLocales: [Locale('fr', '')],
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
