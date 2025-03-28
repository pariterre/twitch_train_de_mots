import 'package:common/managers/theme_manager.dart';
import 'package:common/models/exceptions.dart';
import 'package:train_de_mots/generic/managers/configuration_manager.dart';
import 'package:train_de_mots/generic/managers/database_manager.dart';
import 'package:train_de_mots/generic/managers/ebs_server_manager.dart';
import 'package:train_de_mots/generic/managers/mocks_configuration.dart';
import 'package:train_de_mots/generic/managers/sound_manager.dart';
import 'package:train_de_mots/generic/managers/twitch_manager.dart';
import 'package:train_de_mots/words_train/managers/words_train_game_manager.dart';
import 'package:twitch_manager/twitch_app.dart' as twitch_app;

class MiniGameManager {
  static Future<MiniGameManager> factory() async {
    return MiniGameManager._();
  }

  MiniGameManager._();

  int get timeRemaining => 30;
}

class Managers {
  ///
  /// Singleton instance
  bool _isInitialized = false;
  static final Managers _instance = Managers._();
  Managers._();
  static Managers get instance {
    if (!_instance._isInitialized) {
      throw ManagerNotInitializedException(
          'GamesManager is not initialized. Please call initialize() before using it.');
    }
    return _instance;
  }

  ///
  /// Initialize all the managers
  static Future<void> initialize(
      {required twitch_app.TwitchAppInfo twtichAppInfo,
      required Uri ebsUri}) async {
    if (_instance._isInitialized) {
      throw ManagerAlreadyInitializedException(
          'GamesManager is already initialized.');
    }

    // Initialize the database manager
    _instance._database = MocksConfiguration.useDatabaseMock
        ? await MocksConfiguration.gedDatabaseMocked()
        : await DatabaseManager.factory();

    // Initialize the configuration manager
    await ConfigurationManager.factory();

    // Initialize the main game manager
    _instance._train = MocksConfiguration.useGameManagerMock
        ? await MocksConfiguration.getWordsTrainGameManagerMocked()
        : await WordsTrainGameManager.factory();

    // Initialize the mini game manager
    _instance._miniGame = await MiniGameManager.factory();

    // Initialize the sound manager
    _instance._sound = await SoundManager.factory();

    // Initialize the theme manager
    _instance._theme = await ThemeManager.factory();

    // Initialize the Twitch manager
    _instance._twitch = MocksConfiguration.useTwitchManagerMock
        ? await TwitchManagerMock.factory(appInfo: twtichAppInfo)
        : await TwitchManager.factory(appInfo: twtichAppInfo);

    // Initialize the EBS server manager
    await EbsServerManager.factory(ebsUri: ebsUri);

    _instance._isInitialized = true;
  }

  DatabaseManager? _database;
  DatabaseManager get database {
    if (!_isInitialized) {
      throw ManagerNotInitializedException(
          'GamesManager is not initialized. Please call initialize() before using it.');
    }
    return _database!;
  }

  ConfigurationManager? _configuration;
  ConfigurationManager get configuration {
    if (!_isInitialized) {
      throw ManagerNotInitializedException(
          'GamesManager is not initialized. Please call initialize() before using it.');
    }
    return _configuration!;
  }

  WordsTrainGameManager? _train;
  WordsTrainGameManager get train {
    if (!_isInitialized) {
      throw ManagerNotInitializedException(
          'GamesManager is not initialized. Please call initialize() before using it.');
    }
    return _train!;
  }

  MiniGameManager? _miniGame;
  MiniGameManager get miniGame {
    if (!_isInitialized) {
      throw ManagerNotInitializedException(
          'GamesManager is not initialized. Please call initialize() before using it.');
    }
    return _miniGame!;
  }

  SoundManager? _sound;
  SoundManager get sound {
    if (!_isInitialized) {
      throw ManagerNotInitializedException(
          'GamesManager is not initialized. Please call initialize() before using it.');
    }
    return _sound!;
  }

  ThemeManager? _theme;
  ThemeManager get theme {
    if (!_isInitialized) {
      throw ManagerNotInitializedException(
          'GamesManager is not initialized. Please call initialize() before using it.');
    }
    return _theme!;
  }

  TwitchManager? _twitch;
  TwitchManager get twitch {
    if (!_isInitialized) {
      throw ManagerNotInitializedException(
          'GamesManager is not initialized. Please call initialize() before using it.');
    }
    return _twitch!;
  }

  EbsServerManager? _ebs;
  EbsServerManager get ebs {
    if (!_isInitialized) {
      throw ManagerNotInitializedException(
          'GamesManager is not initialized. Please call initialize() before using it.');
    }
    return _ebs!;
  }
}
