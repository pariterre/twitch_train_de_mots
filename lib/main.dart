import 'package:flutter/material.dart';
import 'package:train_de_mots/managers/configuration_manager.dart';
import 'package:train_de_mots/managers/database_manager.dart';
import 'package:train_de_mots/managers/game_manager.dart';
import 'package:train_de_mots/managers/sound_manager.dart';
import 'package:train_de_mots/managers/theme_manager.dart';
import 'package:train_de_mots/models/player.dart';
import 'package:train_de_mots/models/word_problem.dart';
import 'package:train_de_mots/screens/main_screen.dart';

bool _useMocks = true;

void main() async {
  // Initialize singleton
  WidgetsFlutterBinding.ensureInitialized();

  await ConfigurationManager.initialize();
  if (_useMocks) {
    await DatabaseManagerMock.initialize(isLoggedIn: true);
    await GameManagerMock.initialize(
      gameStatus: GameStatus.roundPreparing,
      problem: WordProblemMock(successLevel: SuccessLevel.failed),
      players: [
        Player(name: 'Player 1')..score = 100,
        Player(name: 'Player 2')
          ..score = 200
          ..hasStolen(),
        Player(name: 'Player 3')..score = 300,
        Player(name: 'Player 4')..score = 150,
        Player(name: 'Player 5')
          ..score = 250
          ..hasStolen()
          ..hasStolen(),
        Player(name: 'Player 6')..score = 350,
      ],
    );
  } else {
    await DatabaseManager.initialize();
    await GameManager.initialize();
  }

  await Future.wait([
    SoundManager.initialize(),
    ThemeManager.initialize(),
  ]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: MainScreen.route,
      routes: {MainScreen.route: (ctx) => const MainScreen()},
    );
  }
}
