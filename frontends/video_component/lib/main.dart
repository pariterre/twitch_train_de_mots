import 'package:common/managers/theme_manager.dart';
import 'package:flutter/material.dart';
import 'package:frontend/managers/game_manager.dart';
import 'package:frontend/managers/twitch_manager.dart';
import 'package:frontend/screens/main_screen.dart';
import 'package:frontend/screens/non_authorized_screen.dart';
import 'package:frontend/widgets/main_window.dart';
import 'package:frontend/widgets/opaque_on_hover.dart';
import 'package:logging/logging.dart';

void main() async {
  Logger.root.onRecord.listen((record) {
    final message = 'TRAIN DE MOTS - ${record.time}: ${record.message}';
    debugPrint(message);
  });
  await TwitchManager.initialize(useMocker: true, useLocalEbs: false);
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeManager.initialize();

  runApp(const MyApp(isFullScreen: false));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, required this.isFullScreen});

  final bool isFullScreen;

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
        body: OpaqueOnHover(
          opacityMin: GameManager.instance.isRoundRunning ? 0.1 : 0.5,
          opacityMax: 1.0,
          child: MainWindow(
            initialSize: (widget.isFullScreen) ? null : const Size(320, 320),
            child: FutureBuilder(
                future: TwitchManager.instance.onInitialized,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!TwitchManager.instance.userHasGrantedIdAccess) {
                    if (TwitchManager.instance is! TwitchManagerMock) {
                      TwitchManager
                          .instance.frontendManager.authenticator.onHasConnected
                          .listen(_reloadOnConnection);
                    }
                    return const NonAuthorizedScreen();
                  }

                  return const MainScreen();
                }),
          ),
        ),
      ),
    );
  }
}
