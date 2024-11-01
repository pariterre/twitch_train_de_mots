import 'package:common/managers/theme_manager.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:train_de_mots/managers/configuration_manager.dart';
import 'package:train_de_mots/managers/database_manager.dart';
import 'package:train_de_mots/managers/game_manager.dart';
import 'package:train_de_mots/managers/mocks_configuration.dart';
import 'package:train_de_mots/managers/sound_manager.dart';
import 'package:train_de_mots/managers/ebs_server_manager.dart';
import 'package:train_de_mots/managers/twitch_manager.dart';
import 'package:train_de_mots/screens/main_screen.dart';

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

  if (MocksConfiguration.useDatabaseMock) {
    await MocksConfiguration.initializeDatabaseMocks();
  } else {
    await DatabaseManager.initialize();
  }

  await ConfigurationManager.initialize();

  if (MocksConfiguration.useGameManagerMock) {
    await MocksConfiguration.initializeGameManagerMocks(
        letterProblemMock: MocksConfiguration.useProblemMock
            ? MocksConfiguration.letterProblemMock
            : null);
  } else {
    await GameManager.initialize();
  }

  await Future.wait([
    SoundManager.initialize(),
    ThemeManager.initialize(),
  ]);

  MocksConfiguration.useTwitchManagerMock
      ? TwitchManager.instance.initialize(useMock: true)
      : TwitchManager.instance.initialize();

  await EbsServerManager.initialize(
      ebsUri: MocksConfiguration.useLocalEbs
          ? Uri.parse('ws://localhost:3010')
          : Uri.parse('wss://twitchserver.pariterre.net:3010'));

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: MainScreen());
  }
}
