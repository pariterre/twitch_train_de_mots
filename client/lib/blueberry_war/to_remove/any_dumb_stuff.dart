import 'package:train_de_mots/blueberry_war/managers/blueberry_war_game_manager.dart';

class TrainManager {
  Duration previousRoundTimeRemaining = Duration(seconds: 10);
}

class MiniGameManager {}

class MiniGamesManager {
  final blueberryWar = BlueberryWarGameManager();
  MiniGamesManager() {
    // Initialize the blueberry war game manager
    blueberryWar.initialize();
  }
}

class ConfigurationManager {
  bool autoplay = true;
}

class Managers {
  /// Singleton instance of Managers
  ///
  /// This class is used to manage various game managers in the application.
  /// It provides a single point of access to all managers, ensuring that they
  /// are initialized and can be accessed throughout the app.
  bool _isInitialized = false;
  static final Managers _instance = Managers._();
  Managers._();
  static Managers get instance {
    if (!_instance._isInitialized) {
      throw ManagerNotInitializedException(
        'Managers are not initialized. Please call Managers.initialize() before using it.',
      );
    }
    return _instance;
  }

  static void initialize() {
    if (_instance._isInitialized) return;
    _instance._isInitialized = true;

    _instance._trainManager = TrainManager();
    _instance._miniGameManager = MiniGamesManager();
    _instance._configurationManager = ConfigurationManager();
  }

  TrainManager? _trainManager;
  TrainManager get train => _trainManager!;

  MiniGamesManager? _miniGameManager;
  MiniGamesManager get miniGames => _miniGameManager!;

  ConfigurationManager? _configurationManager;
  ConfigurationManager get configuration => _configurationManager!;

  /// Returns true if all managers are initialized and ready to use
}

class LetterProblem {
  final List<String> letters;
  LetterProblem(this.letters);
}

class ManagerNotInitializedException implements Exception {
  final String message;
  ManagerNotInitializedException(this.message);

  @override
  String toString() => 'ManagerNotInitializedException: $message';
}

class DictionaryManager {
  static List<String> wordsWithAtLeast(int length) {
    // Example implementation returning dummy 11-letter words
    return ['RESPONSABILITE'];
  }
}

class SerializableLetterProblem {
  final List<String> letters;
  final List<int> scrambleIndices;
  final List<LetterStatus> uselessLetterStatuses;
  final List<LetterStatus> hiddenLetterStatuses;

  SerializableLetterProblem({
    required this.letters,
    required this.scrambleIndices,
    required this.uselessLetterStatuses,
    required this.hiddenLetterStatuses,
  });
}

enum LetterStatus { normal, revealed, hidden }
