import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_de_mots/managers/game_manager.dart';
import 'package:train_de_mots/models/custom_callback.dart';
import 'package:train_de_mots/models/exceptions.dart';
import 'package:train_de_mots/models/word_problem.dart';

const _showAnswersTooltipDefault = false;
const _showLeaderBoardDefault = false;

const _roundDurationDefault = 180;
const _cooldownPeriodDefault = 15;
const _cooldownPeriodAfterStealDefault = 30;
const _timeBeforeScramblingLettersDefault = 15;

const _nbLetterInSmallestWordDefault = 4;
const _minimumWordLetterDefault = 6;
const _maximumWordLetterDefault = 7;
const _minimumWordsNumberDefault = 25;
const _maximumWordsNumberDefault = 35;

const _levelAddingUselessLetterDefault = 10;

const _canStealDefault = true;

const _musicVolumeDefault = 0.3;
const _soundVolumeDefault = 1.0;

class ConfigurationManager {
  ///
  /// Declare the singleton
  static ConfigurationManager get instance {
    if (_instance == null) {
      throw ManagerNotInitializedException(
          "ConfigurationManager must be initialized before being used");
    }
    return _instance!;
  }

  static ConfigurationManager? _instance;
  ConfigurationManager._internal();

  static Future<void> initialize() async {
    if (_instance != null) {
      throw ManagerAlreadyInitializedException(
          "ConfigurationManager should not be initialized twice");
    }
    _instance = ConfigurationManager._internal();

    instance._loadConfiguration();
    // We must wait for the GameManager to be initialized before listening to
    Future.delayed(Duration.zero, () => instance._listenToGameManagerEvents());
  }

  ///
  /// Connect to callbacks to get notified when the configuration changes
  final onChanged = CustomCallback();
  final onMusicChanged = CustomCallback();
  final onSoundChanged = CustomCallback();

  ///
  /// The current algorithm used to generate the problems
  final Future<WordProblem> Function({
    required int nbLetterInSmallestWord,
    required int minLetters,
    required int maxLetters,
    required int minimumNbOfWords,
    required int maximumNbOfWords,
    required bool addUselessLetter,
  }) _problemGenerator = WordProblem.generateFromRandom;
  Future<WordProblem> Function({
    required int nbLetterInSmallestWord,
    required int minLetters,
    required int maxLetters,
    required int minimumNbOfWords,
    required int maximumNbOfWords,
    required bool addUselessLetter,
  }) get problemGenerator => _problemGenerator;

  bool _showAnswersTooltip = _showAnswersTooltipDefault;
  bool get showAnswersTooltip => _showAnswersTooltip;
  set showAnswersTooltip(bool value) {
    _showAnswersTooltip = value;
    _saveConfiguration();
  }

  bool _showLeaderBoard = _showLeaderBoardDefault;
  bool get showLeaderBoard => _showLeaderBoard;
  set showLeaderBoard(bool value) {
    _showLeaderBoard = value;
    _saveConfiguration();
  }

  Duration _roundDuration = const Duration(seconds: _roundDurationDefault);
  Duration get roundDuration => _roundDuration;
  set roundDuration(Duration value) {
    _roundDuration = value;
    _saveConfiguration();
  }

  Duration _cooldownPeriod = const Duration(seconds: _cooldownPeriodDefault);
  Duration get cooldownPeriod => _cooldownPeriod;
  set cooldownPeriod(Duration value) {
    _cooldownPeriod = value;
    _saveConfiguration();
  }

  Duration _cooldownPeriodAfterSteal =
      const Duration(seconds: _cooldownPeriodAfterStealDefault);
  Duration get cooldownPeriodAfterSteal => _cooldownPeriodAfterSteal;
  set cooldownPeriodAfterSteal(Duration value) {
    _cooldownPeriodAfterSteal = value;
    _saveConfiguration();
  }

  Duration _timeBeforeScramblingLetters =
      const Duration(seconds: _timeBeforeScramblingLettersDefault);
  Duration get timeBeforeScramblingLetters => _timeBeforeScramblingLetters;
  set timeBeforeScramblingLetters(Duration value) {
    _timeBeforeScramblingLetters = value;
    _saveConfiguration();
  }

  int _nbLetterInSmallestWord = _nbLetterInSmallestWordDefault;
  int get nbLetterInSmallestWord => _nbLetterInSmallestWord;
  set nbLetterInSmallestWord(int value) {
    if (_nbLetterInSmallestWord == value) return;
    _nbLetterInSmallestWord = value;

    _saveConfiguration();
  }

  int _minimumWordLetter = _minimumWordLetterDefault;
  int get minimumWordLetter => _minimumWordLetter;
  set minimumWordLetter(int value) {
    if (_minimumWordLetter == value) return;
    if (value > maximumWordLetter) return;
    _minimumWordLetter = value;

    _tellGameManagerToRepickProblem();
    _saveConfiguration();
  }

  int _maximumWordLetter = _maximumWordLetterDefault;
  int get maximumWordLetter => _maximumWordLetter;
  set maximumWordLetter(int value) {
    if (_maximumWordLetter == value) return;
    if (value < minimumWordLetter) return;
    _maximumWordLetter = value;

    _tellGameManagerToRepickProblem();
    _saveConfiguration();
  }

  int _minimumWordsNumber = _minimumWordsNumberDefault;
  int get minimumWordsNumber => _minimumWordsNumber;
  set minimumWordsNumber(int value) {
    if (_minimumWordsNumber == value) return;
    if (value > maximumWordsNumber) return;
    _minimumWordsNumber = value;

    _tellGameManagerToRepickProblem();
    _saveConfiguration();
  }

  int _maximumWordsNumber = _maximumWordsNumberDefault;
  int get maximumWordsNumber => _maximumWordsNumber;
  set maximumWordsNumber(int value) {
    if (_maximumWordsNumber == value) return;
    if (value < minimumWordsNumber) return;
    _maximumWordsNumber = value;

    _tellGameManagerToRepickProblem();
    _saveConfiguration();
  }

  int _levelAddingUselessLetter = _levelAddingUselessLetterDefault;
  int get levelAddingUselessLetter => _levelAddingUselessLetter;
  set levelAddingUselessLetter(int value) {
    if (_levelAddingUselessLetter == value) return;
    _levelAddingUselessLetter = value;

    _saveConfiguration();
  }

  bool _canSteal = _canStealDefault;
  bool get canSteal => _canSteal;
  set canSteal(bool value) {
    _canSteal = value;
    _saveConfiguration();
  }

  double _musicVolume = _musicVolumeDefault;
  double get musicVolume => _musicVolume;
  set musicVolume(double value) {
    _musicVolume = value;
    onMusicChanged.notifyListeners();
    _saveConfiguration();
  }

  double _soundVolume = _soundVolumeDefault;
  double get soundVolume => _soundVolume;
  set soundVolume(double value) {
    _soundVolume = value;
    onSoundChanged.notifyListeners();
    _saveConfiguration();
  }

  //// LISTEN TO GAME MANAGER ////
  void _listenToGameManagerEvents() {
    final gm = GameManager.instance;
    gm.onRoundIsPreparing.addListener(_reactToGameManagerEvent);
    gm.onNextProblemReady.addListener(_reactToGameManagerEvent);
    gm.onRoundStarted.addListener(_reactToGameManagerEvent);
    gm.onRoundIsOver.addListener(_reactToGameManagerEvent);
  }

  void _reactToGameManagerEvent() => onChanged.notifyListeners();

  //// LOAD AND SAVE ////

  ///
  /// Serialize the configuration to a map
  Map<String, dynamic> serialize() {
    return {
      'showAnswersTooltip': showAnswersTooltip,
      'showLeaderBoard': showLeaderBoard,
      'roundDuration': roundDuration.inSeconds,
      'cooldownPeriod': cooldownPeriod.inSeconds,
      'cooldownPeriodAfterSteal': cooldownPeriodAfterSteal.inSeconds,
      'timeBeforeScramblingLetters': timeBeforeScramblingLetters.inSeconds,
      'nbLetterInSmallestWord': nbLetterInSmallestWord,
      'minimumWordLetter': minimumWordLetter,
      'maximumWordLetter': maximumWordLetter,
      'minimumWordsNumber': minimumWordsNumber,
      'maximumWordsNumber': maximumWordsNumber,
      'canSteal': canSteal,
      'musicVolume': musicVolume,
      'soundVolume': soundVolume,
    };
  }

  ///
  /// Save the configuration to the device
  void _saveConfiguration() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('gameConfiguration', jsonEncode(serialize()));
    onChanged.notifyListeners();
  }

  ///
  /// Load the configuration from the device
  void _loadConfiguration() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('gameConfiguration');
    if (data != null) {
      final map = jsonDecode(data);

      _showAnswersTooltip =
          map['showAnswersTooltip'] ?? _showAnswersTooltipDefault;
      _showLeaderBoard = map['showLeaderBoard'] ?? _showLeaderBoardDefault;

      _roundDuration =
          Duration(seconds: map['roundDuration'] ?? _roundDurationDefault);
      _cooldownPeriod =
          Duration(seconds: map['cooldownPeriod'] ?? _cooldownPeriodDefault);
      _cooldownPeriodAfterSteal = Duration(
          seconds: map['cooldownPeriodAfterSteal'] ??
              _cooldownPeriodAfterStealDefault);
      _timeBeforeScramblingLetters = Duration(
          seconds: map['timeBeforeScramblingLetters'] ??
              _timeBeforeScramblingLettersDefault);

      _nbLetterInSmallestWord =
          map['nbLetterInSmallestWord'] ?? _nbLetterInSmallestWordDefault;
      _minimumWordLetter =
          map['minimumWordLetter'] ?? _minimumWordLetterDefault;
      _maximumWordLetter =
          map['maximumWordLetter'] ?? _maximumWordLetterDefault;
      _minimumWordsNumber =
          map['minimumWordsNumber'] ?? _minimumWordsNumberDefault;
      _maximumWordsNumber =
          map['maximumWordsNumber'] ?? _maximumWordsNumberDefault;

      _levelAddingUselessLetter =
          map['levelAddingUselessLetter'] ?? _levelAddingUselessLetterDefault;

      _canSteal = map['canSteal'] ?? _canStealDefault;

      _musicVolume = map['musicVolume'] ?? _musicVolumeDefault;
      _soundVolume = map['soundVolume'] ?? _soundVolumeDefault;

      _tellGameManagerToRepickProblem();
    }
  }

  ///
  /// Reset the configuration to the default values
  void resetConfiguration() {
    _showAnswersTooltip = _showAnswersTooltipDefault;
    _showLeaderBoard = _showLeaderBoardDefault;

    _roundDuration = const Duration(seconds: _roundDurationDefault);
    _cooldownPeriod = const Duration(seconds: _cooldownPeriodDefault);
    _cooldownPeriodAfterSteal =
        const Duration(seconds: _cooldownPeriodAfterStealDefault);
    _timeBeforeScramblingLetters =
        const Duration(seconds: _timeBeforeScramblingLettersDefault);

    _nbLetterInSmallestWord = _nbLetterInSmallestWordDefault;
    _minimumWordLetter = _minimumWordLetterDefault;
    _maximumWordLetter = _maximumWordLetterDefault;
    _minimumWordsNumber = _minimumWordsNumberDefault;
    _maximumWordsNumber = _maximumWordsNumberDefault;

    _levelAddingUselessLetter = _levelAddingUselessLetterDefault;

    _canSteal = _canStealDefault;

    _musicVolume = _musicVolumeDefault;
    _soundVolume = _soundVolumeDefault;

    _tellGameManagerToRepickProblem();
    _saveConfiguration();
  }

  //// MODIFYING THE CONFIGURATION ////

  ///
  /// If it is currently possible to change the duration of the round
  bool get canChangeDurations =>
      GameManager.instance.gameStatus != GameStatus.roundStarted;

  ///
  /// If it is currently possible to change the problem picker rules
  bool get canChangeProblem =>
      GameManager.instance.gameStatus == GameStatus.initializing ||
      GameManager.instance.gameStatus == GameStatus.roundReady;

  void _tellGameManagerToRepickProblem() =>
      GameManager.instance.rulesHasChanged(shoulRepickProblem: true);

  void finalizeConfigurationChanges() {
    GameManager.instance.rulesHasChanged(repickNow: true);
  }
}
