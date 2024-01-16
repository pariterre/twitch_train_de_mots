import 'package:flutter/material.dart';
import 'package:train_de_mots/managers/configuration_manager.dart';
import 'package:train_de_mots/managers/database_manager.dart';
import 'package:train_de_mots/managers/game_manager.dart';
import 'package:train_de_mots/managers/sound_manager.dart';
import 'package:train_de_mots/managers/theme_manager.dart';
import 'package:train_de_mots/managers/twitch_manager.dart';
import 'package:train_de_mots/models/player.dart';
import 'package:train_de_mots/models/success_level.dart';
import 'package:train_de_mots/models/letter_problem.dart';
import 'package:train_de_mots/screens/main_screen.dart';

bool _useDatabaseMock = true;
bool _useGameManagerMock = true;
bool _useProblemMock = true;
bool _useTwitchManagerMock = true;

void main() async {
  // Initialize singleton
  WidgetsFlutterBinding.ensureInitialized();

  if (_useDatabaseMock) {
    await DatabaseManagerMock.initialize(
      dummyIsSignedIn: true,
      emailIsVerified: true,
      dummyTeamName: 'Les Bleuets',
      dummyResults: {
        'Les Verts': 3,
        'Les Oranges': 6,
        'Les Roses': 1,
        'Les Jaunes': 5,
        'Les Blancs': 1,
        'Les Bleus': 0,
        'Les Noirs': 1,
        'Les Rouges': 2,
        'Les Violets': 3,
        'Les Gris': 0,
        'Les Bruns': 0,
      },
    );
  } else {
    await DatabaseManager.initialize();
  }

  await ConfigurationManager.initialize();

  if (_useGameManagerMock) {
    await GameManagerMock.initialize(
      gameStatus: GameStatus.roundPreparing,
      problem: _useProblemMock ? LetterProblemMock() : null,
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
      roundCount: 10,
      successLevel: SuccessLevel.oneStar,
    );
  } else {
    await GameManager.initialize();
  }

  await Future.wait([
    SoundManager.initialize(),
    ThemeManager.initialize(),
  ]);

  if (_useTwitchManagerMock) {
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
    return MaterialApp(
      initialRoute: MainScreen.route,
      routes: {MainScreen.route: (ctx) => const MainScreen()},
    );
  }
}
