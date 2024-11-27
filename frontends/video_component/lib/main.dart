import 'package:common/managers/theme_manager.dart';
import 'package:flutter/material.dart';
import 'package:frontend/managers/twitch_manager.dart';
import 'package:frontend/screens/main_screen.dart';
import 'package:frontend/screens/non_authorized_screen.dart';
import 'package:logging/logging.dart';

void main() async {
  Logger.root.onRecord.listen((record) {
    final message = 'TRAIN DE MOTS - ${record.time}: ${record.message}';
    debugPrint(message);
  });
  await TwitchManager.initialize(useMocker: false, useLocalEbs: false);
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeManager.initialize();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  void _reloadOnConnection() {
    TwitchManager.instance.frontendManager.authenticator.onHasConnected
        .cancel(_reloadOnConnection);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.transparent,
        body: FutureBuilder(
            future: TwitchManager.instance.onInitialized,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!TwitchManager.instance.userHasGrantedIdAccess) {
                TwitchManager
                    .instance.frontendManager.authenticator.onHasConnected
                    .listen(_reloadOnConnection);
                return const NonAuthorizedScreen();
              }

              return const MainScreen();
            }),
      ),
    );
  }
}
