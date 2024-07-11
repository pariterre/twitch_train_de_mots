import 'package:train_de_mots/managers/database_manager.dart';
import 'package:train_de_mots/managers/game_manager.dart';
import 'package:train_de_mots/models/letter_problem.dart';
import 'package:train_de_mots/models/player.dart';
import 'package:train_de_mots/models/success_level.dart';
import 'package:train_de_mots/models/word_solution.dart';
import 'package:twitch_manager/twitch_manager.dart';

class MocksConfiguration {
  static bool showDebugOptions = false;

  static bool useDatabaseMock = false;
  static bool useDatabaseEmulators = false;
  static bool useGameManagerMock = false;
  static bool useProblemMock = false;
  static bool useTwitchManagerMock = false;

  static LetterProblemMock get letterProblemMock => LetterProblemMock(
      letters: 'BJOONUR',
      solutions: WordSolutions([
        WordSolution(word: 'repa'),
        WordSolution(word: 'repb'),
        WordSolution(word: 'repc'),
        WordSolution(word: 'repd'),
        WordSolution(word: 'repe'),
        WordSolution(word: 'repf'),
        WordSolution(word: 'repg'),
        WordSolution(word: 'reph'),
        WordSolution(word: 'repi'),
        WordSolution(word: 'repj'),
        WordSolution(word: 'repk'),
        WordSolution(word: 'repl'),
        WordSolution(word: 'repm'),
        WordSolution(word: 'repn'),
        WordSolution(word: 'repo'),
        WordSolution(word: 'repp'),
        WordSolution(word: 'repq'),
        WordSolution(word: 'repaa'),
        WordSolution(word: 'repab'),
        WordSolution(word: 'repac'),
        WordSolution(word: 'repad'),
        WordSolution(word: 'repae'),
        WordSolution(word: 'repaf'),
        WordSolution(word: 'repag'),
        WordSolution(word: 'repah'),
        WordSolution(word: 'repai'),
        WordSolution(word: 'repaj'),
        WordSolution(word: 'repak'),
        WordSolution(word: 'repal'),
        WordSolution(word: 'repaaa'),
        WordSolution(word: 'repaab'),
        WordSolution(word: 'repaac'),
        WordSolution(word: 'repaad'),
        WordSolution(word: 'repaae'),
        WordSolution(word: 'repaaaa'),
        WordSolution(word: 'repaaab'),
        WordSolution(word: 'repaaac'),
        WordSolution(word: 'repaaaaa'),
        WordSolution(word: 'repaaaab'),
        WordSolution(word: 'repaaaac'),
      ]));

  static Future<void> initializeGameManagerMocks(
      {LetterProblemMock? letterProblemMock}) async {
    GameManagerMock.initialize(
      gameStatus: GameStatus.roundPreparing,
      problem: letterProblemMock,
      players: [
        Player(name: 'Player 1')..score = 100,
        Player(name: 'Player 2')
          ..score = 200
          ..addToStealCount(),
        Player(name: 'Player 3')..score = 300,
        Player(name: 'Player 4')..score = 150,
        Player(name: 'Player 5')
          ..score = 250
          ..addToStealCount()
          ..addToStealCount(),
        Player(name: 'Player 6')..score = 350,
        Player(name: 'PlayerWithAVeryVeryVeryLongName')
          ..score = 400
          ..addToStealCount()
          ..addToStealCount(),
        Player(name: 'AnotherPlayerWithAVeryVeryVeryLongName')..score = 350,
      ],
      roundCount: 10,
      successLevel: SuccessLevel.failed,
    );
  }

  static Future<void> initializeDatabaseMocks() async {
    DatabaseManagerMock.initialize(
      dummyIsSignedIn: true,
      emailIsVerified: true,
      dummyTeamName: 'Les Bleuets',
      dummyBestStationResults: {
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
        'Les Bleuets': 4,
      },
      dummyBestPlayerResults: {
        'Player 1': (300, 'Les Verts'),
        'Player 2': (250, 'Les Oranges'),
        'Player 3': (600, 'Les Roses'),
        'Player 4': (500, 'Les Jaunes'),
        'Player 5': (600, 'Les Blancs'),
        'Player 6': (250, 'Les Bleus'),
        'PlayerWithAVeryVeryVeryLongName': (400, 'Les Noirs'),
        'AnotherPlayerWithAVeryVeryVeryLongName': (350, 'Les Rouges'),
        'Viewer3': (2, 'Les Bleuets'),
      },
    );
  }

  static TwitchDebugPanelOptions get twitchDebugPanelOptions =>
      TwitchDebugPanelOptions(chatters: [
        TwitchChatterMock(displayName: 'Viewer1'),
        TwitchChatterMock(displayName: 'Viewer2'),
        TwitchChatterMock(displayName: 'Viewer3'),
        TwitchChatterMock(displayName: 'ViewerWithAVeryVeryVeryLongName'),
      ]);
}
