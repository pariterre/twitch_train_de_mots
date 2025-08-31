import 'package:common/generic/widgets/background.dart';
import 'package:flutter/material.dart';
import 'package:train_de_mots/generic/managers/managers.dart';
import 'package:twitch_manager/twitch_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Managers.initialize(
    twitchAppInfo: TwitchAppInfo(
      appName: 'Train de mots',
      twitchClientId: '75yy5xbnj3qn2yt27klxrqm6zbbr4l',
      scope: const [
        TwitchAppScope.chatRead,
        TwitchAppScope.readFollowers,
      ],
      twitchRedirectUri: Uri.https(
          'twitchauthentication.pariterre.net', 'twitch_redirect.html'),
      authenticationServerUri:
          Uri.https('twitchserver.pariterre.net:3000', 'token'),
      authenticationFlow: TwitchAuthenticationFlow.implicit,
      ebsUri: Uri.parse('ws://localhost:3010'),
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: DebugScreen());
  }
}

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  static const route = '/debug-screen';

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  Future<void> _setTwitchManager() async {
    await Managers.instance.twitch.showConnectManagerDialog(context);
    setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Managers.instance.twitch.isNotConnected) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _setTwitchManager());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Background(
      backgroundLayer: Image.asset(
        'packages/common/assets/images/train.png',
        height: MediaQuery.of(context).size.height,
        opacity: const AlwaysStoppedAnimation(0.05),
        fit: BoxFit.cover,
      ),
      child: Managers.instance.twitch.debugOverlay(
        child: const Center(child: Text('Coucou')),
      ),
    ));
  }
}
