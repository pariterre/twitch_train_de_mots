import 'package:common/generic/widgets/background.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:train_de_mots/blueberry_war/screens/blueberry_war_game_screen.dart';
import 'package:train_de_mots/generic/managers/managers.dart';
import 'package:train_de_mots/mocks_configuration.dart';
import 'package:twitch_manager/twitch_app.dart';

final _logger = Logger('Main');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set up logging
  Logger.root.level = Level.INFO; // Set the logging level
  Logger.root.onRecord.listen((record) {
    debugPrint('${record.level.name}: ${record.time}: ${record.message}');
  });
  _logger.info('Starting Twitch Blueberry War App');

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
  await Managers.instance.miniGames.blueberryWar.initialize();
  await Managers.instance.miniGames.blueberryWar.start();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: Scaffold(
          body: Background(
              withSnowfall: false,
              backgroundLayer: Image.asset(
                'packages/common/assets/images/train.png',
                height: MediaQuery.of(context).size.height,
                opacity: const AlwaysStoppedAnimation(0.05),
                fit: BoxFit.cover,
              ),
              child: const _MainScreen(child: BlueberryWarGameScreen()))),
    );
  }
}

class _MainScreen extends StatefulWidget {
  const _MainScreen({
    required this.child,
  });

  final Widget child;

  @override
  State<_MainScreen> createState() => __MainScreenState();
}

class __MainScreenState extends State<_MainScreen> {
  Future<void> _setTwitchManager({required bool reloadIfPossible}) async {
    await Managers.instance.twitch
        .showConnectManagerDialog(context, reloadIfPossible: reloadIfPossible);
    setState(() {});
  }

  void _reconnectedAfterDisconnect() =>
      _setTwitchManager(reloadIfPossible: false);

  @override
  void initState() {
    Managers.instance.twitch.onTwitchManagerHasDisconnected
        .listen(_reconnectedAfterDisconnect);

    super.initState();
  }

  @override
  void dispose() {
    Managers.instance.twitch.onTwitchManagerHasDisconnected
        .cancel(_reconnectedAfterDisconnect);

    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Managers.instance.twitch.isNotConnected) {
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => _setTwitchManager(reloadIfPossible: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
