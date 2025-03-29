import 'package:common/managers/theme_manager.dart';
import 'package:common/models/exceptions.dart';
import 'package:train_de_mots/generic/managers/configuration_manager.dart';
import 'package:train_de_mots/generic/managers/database_manager.dart';
import 'package:train_de_mots/generic/managers/ebs_server_manager.dart';
import 'package:train_de_mots/generic/managers/mini_games_manager.dart';
import 'package:train_de_mots/generic/managers/sound_manager.dart';
import 'package:train_de_mots/generic/managers/twitch_manager.dart';
import 'package:train_de_mots/mocks_configuration.dart';
import 'package:train_de_mots/words_train/managers/words_train_game_manager.dart';
import 'package:twitch_manager/twitch_app.dart' as twitch_app;

class Managers {
  ///
  /// Singleton instance
  bool _isInitialized = false;
  static final Managers _instance = Managers._();
  Managers._();
  static Managers get instance {
    if (!_instance._isInitialized) {
      throw ManagerNotInitializedException(
          'Managers are not initialized. Please call Managers.initialize() before using it.');
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
          'Managers are already initialized.');
    }
    // We need to allow access to managers already because they need each other
    // to be initialized
    _instance._isInitialized = true;

    // Initialize the database manager
    _instance._database = MocksConfiguration.useDatabaseMock
        ? await MocksConfiguration.gedDatabaseMocked()
        : await DatabaseManager.factory();

    // Initialize the Twitch manager
    _instance._twitch = MocksConfiguration.useTwitchManagerMock
        ? await TwitchManagerMock.factory(appInfo: twtichAppInfo)
        : await TwitchManager.factory(appInfo: twtichAppInfo);

    // Initialize the configuration manager
    _instance._configuration = await ConfigurationManager.factory();

    // Initialize the main game manager
    _instance._train = MocksConfiguration.useGameManagerMock
        ? await MocksConfiguration.getWordsTrainGameManagerMocked()
        : await WordsTrainGameManager.factory();

    // Initialize the mini game manager
    _instance._miniGames = await MiniGamesManager.factory();

    // Initialize the sound manager
    _instance._sound = await SoundManager.factory();

    // Initialize the theme manager
    _instance._theme = await ThemeManager.factory();

    // Initialize the EBS server manager
    _instance._ebs = await EbsServerManager.factory(ebsUri: ebsUri);

    // Wait for all the manager to be ready
    while (!(_instance._database?.isInitialized ?? false) ||
        !(_instance._configuration?.isInitialized ?? false) ||
        !(_instance._train?.isInitialized ?? false) ||
        !(_instance._miniGames?.isInitialized ?? false) ||
        !(_instance._sound?.isInitialized ?? false) ||
        !(_instance._theme?.isInitialized ?? false) ||
        !(_instance._twitch?.isInitialized ?? false) ||
        !(_instance._ebs?.isInitialized ?? false)) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  DatabaseManager? _database;
  DatabaseManager get database {
    if (_database == null) {
      throw ManagerNotInitializedException(
          'DatabaseManager is not initialized. Please call Managers.initialize() before using it.');
    }
    return _database!;
  }

  ConfigurationManager? _configuration;
  ConfigurationManager get configuration {
    if (_configuration == null) {
      throw ManagerNotInitializedException(
          'ConfigurationManager is not initialized. Please call Managers.initialize() before using it.');
    }
    return _configuration!;
  }

  WordsTrainGameManager? _train;
  WordsTrainGameManager get train {
    if (_train == null) {
      throw ManagerNotInitializedException(
          'GamesManager is not initialized. Please call Managers.initialize() before using it.');
    }
    return _train!;
  }

  MiniGamesManager? _miniGames;
  MiniGamesManager get miniGames {
    if (_miniGames == null) {
      throw ManagerNotInitializedException(
          'MiniGamesManager is not initialized. Please call Managers.initialize() before using it.');
    }
    return _miniGames!;
  }

  SoundManager? _sound;
  SoundManager get sound {
    if (_sound == null) {
      throw ManagerNotInitializedException(
          'SoundManager is not initialized. Please call Managers.initialize() before using it.');
    }
    return _sound!;
  }

  ThemeManager? _theme;
  ThemeManager get theme {
    if (_theme == null) {
      throw ManagerNotInitializedException(
          'ThemeManager is not initialized. Please call Managers.initialize() before using it.');
    }
    return _theme!;
  }

  TwitchManager? _twitch;
  TwitchManager get twitch {
    if (_twitch == null) {
      throw ManagerNotInitializedException(
          'TwitchManager is not initialized. Please call Managers.initialize() before using it.');
    }
    return _twitch!;
  }

  EbsServerManager? _ebs;
  EbsServerManager get ebs {
    if (_ebs == null) {
      throw ManagerNotInitializedException(
          'EbsServerManager is not initialized. Please call Managers.initialize() before using it.');
    }
    return _ebs!;
  }
}
