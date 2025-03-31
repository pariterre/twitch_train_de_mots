import 'package:common/models/game_status.dart';
import 'package:train_de_mots/generic/managers/database_manager.dart';
import 'package:train_de_mots/generic/models/mini_games.dart';
import 'package:train_de_mots/words_train/managers/words_train_game_manager.dart';
import 'package:train_de_mots/words_train/models/letter_problem.dart';
import 'package:train_de_mots/words_train/models/player.dart';
import 'package:train_de_mots/words_train/models/success_level.dart';
import 'package:train_de_mots/words_train/models/word_solution.dart';
import 'package:twitch_manager/twitch_app.dart';

class MocksConfiguration {
  // Useful for developpers
  static bool showDebugOptions = false;
  static bool useLocalEbs = false;
  static bool useDatabaseMock = false;
  static bool useTwitchManagerMock = false;

  // Nice to have for developpers
  static bool useDatabaseEmulators = false;
  static bool useGameManagerMock = false;
  static bool useProblemMock = false;

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

  static WordsTrainGameManagerMock getWordsTrainGameManagerMocked() =>
      WordsTrainGameManagerMock(
        gameStatus: WordsTrainGameStatus.roundPreparing,
        problem: MocksConfiguration.useProblemMock
            ? MocksConfiguration.letterProblemMock
            : null,
        players: [
          Player(name: 'Player 1')
            ..score = 100
            ..starsCollected = 1,
          Player(name: 'Player 2')
            ..score = 200
            ..starsCollected = 2
            ..addToStealCount(),
          Player(name: 'Player 3')..score = 300,
          Player(name: 'Player 4')..score = 150,
          Player(name: 'Player 5')
            ..score = 250
            ..addToStealCount()
            ..addToStealCount()
            ..addToStealCount(),
          Player(name: 'Player 6')..score = 350,
          Player(name: 'PlayerWithAVeryVeryVeryLongName')
            ..score = 400
            ..addToStealCount()
            ..addToStealCount(),
          Player(name: 'AnotherPlayerWithAVeryVeryVeryLongName')
            ..addToStealCount()
            ..addToStealCount()
            ..addToStealCount()
            ..score = 350,
        ],
        roundCount: 14,
        successLevel: SuccessLevel.threeStars,
        shouldAttemptTheBigHeist: false,
        shouldChangeLane: true,
        isNextRoundAMiniGame: true,
        nextMiniGame: MiniGames.treasureHunt,
      );

  static DatabaseManagerMock getDatabaseMocked() => DatabaseManagerMock(
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
        dummyBestPlayerScore: {
          'Viewer 1': (300, 'Les Verts'),
          'Viewer 2': (250, 'Les Oranges'),
          'Viewer 3': (600, 'Les Roses'),
          'Viewer 4': (500, 'Les Jaunes'),
          'Viewer 5': (600, 'Les Blancs'),
          'Viewer 6': (250, 'Les Bleuets'),
          'PlayerWithAVeryVeryVeryLongName': (400, 'Les Noirs'),
          'AnotherPlayerWithAVeryVeryVeryLongName': (350, 'Les Rouges'),
          'Player 3': (2, 'Les Bleuets'),
        },
        dummyBestPlayerStars: {
          'Viewer 1': (3, 'Les Verts'),
          'Viewer 2': (2, 'Les Oranges'),
          'Viewer 3': (5, 'Les Roses'),
          'Viewer 4': (10, 'Les Jaunes'),
          'Viewer 5': (5, 'Les Blancs'),
          'Viewer 6': (2, 'Les Bleus'),
          'PlayerWithAVeryVeryVeryLongName': (0, 'Les Noirs'),
          'AnotherPlayerWithAVeryVeryVeryLongName': (1, 'Les Rouges'),
          'Player 3': (1, 'Les Bleuets'),
        },
      );

  static TwitchDebugPanelOptions get twitchDebugPanelOptions =>
      TwitchDebugPanelOptions(chatters: [
        TwitchChatterMock(displayName: 'Viewer1'),
        TwitchChatterMock(displayName: 'Viewer2'),
        TwitchChatterMock(displayName: 'Viewer3'),
        TwitchChatterMock(displayName: 'ViewerWithAVeryVeryVeryLongName'),
      ]);
}
