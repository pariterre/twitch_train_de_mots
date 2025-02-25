import 'package:common/managers/theme_manager.dart';
import 'package:common/widgets/background.dart';
import 'package:flutter/material.dart';
import 'package:train_de_mots/managers/configuration_manager.dart';
import 'package:train_de_mots/managers/game_manager.dart';
import 'package:train_de_mots/managers/sound_manager.dart';
import 'package:train_de_mots/managers/twitch_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ConfigurationManager.initialize();
  await GameManager.initialize();
  await ThemeManager.initialize();
  await SoundManager.initialize();
  TwitchManager.instance.initialize(useMock: true);

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
    await TwitchManager.instance.showConnectManagerDialog(context);
    setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (TwitchManager.instance.isNotConnected) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _setTwitchManager());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Background(
      backgroundLayer: Image.asset(
        'assets/images/train.png',
        height: MediaQuery.of(context).size.height,
        opacity: const AlwaysStoppedAnimation(0.05),
        fit: BoxFit.cover,
      ),
      child: TwitchManager.instance.debugOverlay(
        child: const Center(child: Text('Coucou')),
      ),
    ));
  }
}
