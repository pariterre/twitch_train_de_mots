import 'package:flutter/material.dart';
import 'package:train_de_mots/managers/configuration_manager.dart';
import 'package:train_de_mots/managers/database_manager.dart';
import 'package:train_de_mots/managers/game_manager.dart';
import 'package:train_de_mots/managers/mocks_configuration.dart';
import 'package:train_de_mots/managers/sound_manager.dart';
import 'package:train_de_mots/managers/theme_manager.dart';
import 'package:train_de_mots/managers/train_de_mots_server_manager.dart';
import 'package:train_de_mots/managers/twitch_manager.dart';
import 'package:train_de_mots/screens/main_screen.dart';

void main() async {
  // Initialize singleton
  WidgetsFlutterBinding.ensureInitialized();

  await TrainDeMotsServerManager.initialize(
      uri: Uri.parse(MocksConfiguration.useLocalTrainDeMotsServer
          ? 'http://localhost:3010'
          : 'https://twitchserver.pariterre.net:3010'));

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

  if (MocksConfiguration.useTwitchManagerMock) {
    TwitchManager.instance.initialize(useMock: true);
  } else {
    TwitchManager.instance.initialize();
  }

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
