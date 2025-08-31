import 'package:common/generic/models/exceptions.dart';
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
      {required twitch_app.TwitchAppInfo twitchAppInfo}) async {
    if (_instance._isInitialized) {
      throw ManagerAlreadyInitializedException(
          'Managers are already initialized.');
    }
    if (twitchAppInfo.ebsUri == null) {
      throw ManagerNotInitializedException(
          'EbsServerManager cannot be initialized because no EBS URI is provided in TwitchAppInfo.');
    }

    // We need to allow access to managers already because they need each other
    // to be initialized
    _instance._isInitialized = true;

    // Initialize the database manager
    _instance._database = MocksConfiguration.useDatabaseMock
        ? MocksConfiguration.getDatabaseMocked()
        : DatabaseManager();

    // Initialize the Twitch manager
    _instance._twitch = MocksConfiguration.useTwitchManagerMock
        ? TwitchManagerMocked(appInfo: twitchAppInfo)
        : TwitchManager(appInfo: twitchAppInfo);

    // Initialize the configuration manager
    _instance._configuration = ConfigurationManager();

    // Initialize the main game manager
    _instance._train = MocksConfiguration.useGameManagerMock
        ? MocksConfiguration.getWordsTrainGameManagerMocked()
        : WordsTrainGameManager();

    // Initialize the mini game manager
    _instance._miniGames = MiniGamesManager();

    // Initialize the sound manager
    _instance._sound = SoundManager();

    // Initialize the EBS server manager
    _instance._ebs = EbsServerManager(appInfo: twitchAppInfo);

    // Wait for all the manager to be ready
    while (!(_instance._database?.isInitialized ?? false) ||
        !(_instance._configuration?.isInitialized ?? false) ||
        !(_instance._train?.isInitialized ?? false) ||
        !(_instance._miniGames?.isInitialized ?? false) ||
        !(_instance._sound?.isInitialized ?? false) ||
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
