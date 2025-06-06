import 'dart:convert';

import 'package:common/generic/managers/theme_manager.dart';
import 'package:common/generic/models/exceptions.dart';
import 'package:common/generic/models/game_status.dart';
import 'package:common/generic/models/generic_listener.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_de_mots/generic/managers/managers.dart';
import 'package:train_de_mots/mocks_configuration.dart';
import 'package:train_de_mots/words_train/models/difficulty.dart';
import 'package:train_de_mots/words_train/models/letter_problem.dart';

const String _lastReleaseNotesShownDefault = '';

const _useCustomAdvancedOptionsDefault = false;

const _autoplayDefault = true;
const _shouldShowAutoplayDialogDefault = false;
const _autoplayDurationDefault = 25;

const _showAnswersTooltipDefault = false;
const _showLeaderBoardDefault = false;

const _roundDurationDefault = 120;
const _postRoundGracePeriodDurationDefault = 6;
const _postRoundShowCaseDurationDefault = 9;
const _cooldownPeriodDefault = 12;
const _cooldownPenaltyAfterStealDefault = 5;
const _timeBeforeScramblingLettersDefault = 15;

const _goldenSolutionProbabilityDefault = 0.005;
const _goldenSolutionMinimumDurationDefault = 20;

const _minimumWordsNumberDefault = 20;
const _maximumWordsNumberDefault = 40;

const _canStealDefault = true;
const _oneStationMaxPerRoundDefault = false;

const _canUseControllerHelperDefault = true;

const _numberOfPardonsDefault = 1;
const _boostTimeDefault = 30;
const _numberOfBoostsDefault = 1;
const _numberOfBoostRequestsNeededDefault = 3;

const _musicVolumeDefault = 0.3;
const _soundVolumeDefault = 1.0;

const _showExtensionDefault = true;

final _logger = Logger('ConfigurationManager');

class ConfigurationManager {
  bool get useDebugOptions => MocksConfiguration.showDebugOptions;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  ConfigurationManager() {
    _asyncInitializations();
  }

  Future<void> _asyncInitializations() async {
    _logger.config('Initializing...');
    await _loadConfiguration();

    while (true) {
      try {
        final gm = Managers.instance.train;
        gm.onRoundIsPreparing.listen(_reactToGameManagerEvent);
        gm.onNextProblemReady.listen(_reactToGameManagerEvent);
        gm.onRoundStarted.listen(_reactToGameManagerEvent);
        gm.onRoundIsOver.listen(_reactToGameManagerEvent);
        break;
      } on ManagerNotInitializedException {
        // Wait and repeat
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }

    _isInitialized = true;
    _logger.config('Ready');
  }

  ///
  /// Connect to callbacks to get notified when the configuration changes
  final onChanged = GenericListener<Function()>();
  final onGameMusicVolumeChanged = GenericListener<Function()>();
  final onSoundVolumeChanged = GenericListener<Function()>();

  ///
  /// Connect to callback to get notified when hide extension is changed
  final onShowExtensionChanged = GenericListener();

  ///
  /// The current algorithm used to generate the problems
  final Future<LetterProblem> Function({
    required int nbLetterInSmallestWord,
    required int minLetters,
    required int maxLetters,
    required int minimumNbOfWords,
    required int maximumNbOfWords,
    required bool addUselessLetter,
    required Duration maxSearchingTime,
  }) _problemGenerator = ProblemGenerator.generateFromEbs;
  Future<LetterProblem> Function({
    required int nbLetterInSmallestWord,
    required int minLetters,
    required int maxLetters,
    required int minimumNbOfWords,
    required int maximumNbOfWords,
    required bool addUselessLetter,
    required Duration maxSearchingTime,
  }) get problemGenerator => _problemGenerator;

  String _lastReleaseNotesShown = _lastReleaseNotesShownDefault;
  String get lastReleaseNotesShown => _lastReleaseNotesShown;
  set lastReleaseNotesShown(String value) {
    _lastReleaseNotesShown = value;
    _saveConfiguration();
  }

  bool _useCustomAdvancedOptions = _useCustomAdvancedOptionsDefault;
  bool get useCustomAdvancedOptions => _useCustomAdvancedOptions;
  set useCustomAdvancedOptions(bool value) {
    _useCustomAdvancedOptions = value;

    _saveConfiguration();
  }

  bool _autoplay = _autoplayDefault;
  bool get autoplay => _autoplay;
  set autoplay(bool value) {
    _autoplay = value;
    _saveConfiguration();
  }

  bool _shouldShowAutoplayDialog = _shouldShowAutoplayDialogDefault;
  bool get shouldShowAutoplayDialog => _shouldShowAutoplayDialog;
  set shouldShowAutoplayDialog(bool value) {
    _shouldShowAutoplayDialog = value;
    _saveConfiguration();
  }

  Duration _autoplayDuration =
      const Duration(seconds: _autoplayDurationDefault);
  Duration get autoplayDuration => _autoplayDuration;
  set autoplayDuration(Duration value) {
    _autoplayDuration = value;
    _saveConfiguration();
  }

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
  Duration get roundDuration => useCustomAdvancedOptions
      ? _roundDuration
      : const Duration(seconds: _roundDurationDefault);
  set roundDuration(Duration value) {
    _roundDuration = value;
    _saveConfiguration();
  }

  Duration _postRoundGracePeriodDuration =
      const Duration(seconds: _postRoundGracePeriodDurationDefault);
  Duration get postRoundGracePeriodDuration => useCustomAdvancedOptions
      ? _postRoundGracePeriodDuration
      : const Duration(seconds: _postRoundGracePeriodDurationDefault);
  set postRoundGracePeriodDuration(Duration value) {
    _postRoundGracePeriodDuration = value;
    _saveConfiguration();
  }

  Duration _postRoundShowCaseDuration =
      const Duration(seconds: _postRoundShowCaseDurationDefault);
  Duration get postRoundShowCaseDuration => useCustomAdvancedOptions
      ? _postRoundShowCaseDuration
      : const Duration(seconds: _postRoundShowCaseDurationDefault);
  set postRoundShowCaseDuration(Duration value) {
    _postRoundShowCaseDuration = value;
    _saveConfiguration();
  }

  Duration _cooldownPeriod = const Duration(seconds: _cooldownPeriodDefault);
  Duration get cooldownPeriod => useCustomAdvancedOptions
      ? _cooldownPeriod
      : const Duration(seconds: _cooldownPeriodDefault);
  set cooldownPeriod(Duration value) {
    _cooldownPeriod = value;
    _saveConfiguration();
  }

  Duration _cooldownPenaltyAfterSteal =
      const Duration(seconds: _cooldownPenaltyAfterStealDefault);
  Duration get cooldownPenaltyAfterSteal => useCustomAdvancedOptions
      ? _cooldownPenaltyAfterSteal
      : const Duration(seconds: _cooldownPenaltyAfterStealDefault);
  set cooldownPenaltyAfterSteal(Duration value) {
    _cooldownPenaltyAfterSteal = value;
    _saveConfiguration();
  }

  Duration _timeBeforeScramblingLetters =
      const Duration(seconds: _timeBeforeScramblingLettersDefault);
  Duration get timeBeforeScramblingLetters => useCustomAdvancedOptions
      ? _timeBeforeScramblingLetters
      : const Duration(seconds: _timeBeforeScramblingLettersDefault);
  set timeBeforeScramblingLetters(Duration value) {
    _timeBeforeScramblingLetters = value;
    _saveConfiguration();
  }

  double _goldenSolutionProbability = _goldenSolutionProbabilityDefault;
  double get goldenSolutionProbability => _goldenSolutionProbability;
  set goldenSolutionProbability(double value) {
    _goldenSolutionProbability = value;
    _saveConfiguration();
  }

  Duration _goldenSolutionMinimumDuration =
      const Duration(seconds: _goldenSolutionMinimumDurationDefault);
  Duration get goldenSolutionMinimumDuration => _goldenSolutionMinimumDuration;
  set goldenSolutionMinimumDuration(Duration value) {
    _goldenSolutionMinimumDuration = value;
    _saveConfiguration();
  }

  int _minimumWordsNumber = _minimumWordsNumberDefault;
  int get minimumWordsNumber => useCustomAdvancedOptions
      ? _minimumWordsNumber
      : _minimumWordsNumberDefault;
  set minimumWordsNumber(int value) {
    if (_minimumWordsNumber == value) return;
    if (value > maximumWordsNumber) return;
    _minimumWordsNumber = value;

    _tellGameManagerToRepickProblem();
    _saveConfiguration();
  }

  int _maximumWordsNumber = _maximumWordsNumberDefault;
  int get maximumWordsNumber => useCustomAdvancedOptions
      ? _maximumWordsNumber
      : _maximumWordsNumberDefault;
  set maximumWordsNumber(int value) {
    if (_maximumWordsNumber == value) return;
    if (value < minimumWordsNumber) return;
    _maximumWordsNumber = value;

    _tellGameManagerToRepickProblem();
    _saveConfiguration();
  }

  bool _canSteal = _canStealDefault;
  bool get canSteal => useCustomAdvancedOptions ? _canSteal : _canStealDefault;
  set canSteal(bool value) {
    _canSteal = value;
    _saveConfiguration();
  }

  bool _oneStationMaxPerRound = _oneStationMaxPerRoundDefault;
  bool get oneStationMaxPerRound => useCustomAdvancedOptions
      ? _oneStationMaxPerRound
      : _oneStationMaxPerRoundDefault;
  set oneStationMaxPerRound(bool value) {
    _oneStationMaxPerRound = value;
    _saveConfiguration();
  }

  bool _canUseControllerHelper = _canUseControllerHelperDefault;
  bool get canUseControllerHelper => _canUseControllerHelper;
  set canUseControllerHelper(bool value) {
    _canUseControllerHelper = value;
    _saveConfiguration();
  }

  int _numberOfPardons = _numberOfPardonsDefault;
  int get numberOfPardons => _numberOfPardons;
  set numberOfPardons(int value) {
    _numberOfPardons = value;
    _saveConfiguration();
  }

  Duration _boostTime = const Duration(seconds: _boostTimeDefault);
  Duration get boostTime => _boostTime;
  set boostTime(Duration value) {
    _boostTime = value;
    _saveConfiguration();
  }

  int _numberOfBoosts = _numberOfBoostsDefault;
  int get numberOfBoosts => _numberOfBoosts;
  set numberOfBoosts(int value) {
    _numberOfBoosts = value;
    _saveConfiguration();
  }

  int _numberOfBoostRequestsNeeded = _numberOfBoostRequestsNeededDefault;
  int get numberOfBoostRequestsNeeded => _numberOfBoostRequestsNeeded;
  set numberOfBoostRequestsNeeded(int value) {
    _numberOfBoostRequestsNeeded = value;
    _saveConfiguration();
  }

  double _musicVolume = _musicVolumeDefault;
  double get musicVolume => _musicVolume;
  set musicVolume(double value) {
    _musicVolume = value;
    onGameMusicVolumeChanged.notifyListeners((callback) => callback());
    _saveConfiguration();
  }

  double _soundVolume = _soundVolumeDefault;
  double get soundVolume => _soundVolume;
  set soundVolume(double value) {
    _soundVolume = value;
    _saveConfiguration();
  }

  bool _showExtension = _showExtensionDefault;
  bool get showExtension => _showExtension;
  set showExtension(bool value) {
    _showExtension = value;
    onShowExtensionChanged.notifyListeners((callback) => callback());
    _saveConfiguration();
  }

  void _reactToGameManagerEvent() =>
      onChanged.notifyListeners((callback) => callback());

  //// LOAD AND SAVE ////

  ///
  /// Serialize the configuration to a map
  Map<String, dynamic> serialize() => {
        'lastReleaseNotesShown': lastReleaseNotesShown,
        'useDefaultAdvancedOptions': _useCustomAdvancedOptions,
        'autoplay': autoplay,
        'shouldShowAutoplayDialog': shouldShowAutoplayDialog,
        'autoplayDuration': autoplayDuration.inSeconds,
        'showAnswersTooltip': showAnswersTooltip,
        'showLeaderBoard': showLeaderBoard,
        'roundDuration': roundDuration.inSeconds,
        'postRoundGracePeriodDuration': postRoundGracePeriodDuration.inSeconds,
        'postRoundShowCaseDuration': postRoundShowCaseDuration.inSeconds,
        'cooldownPeriod': cooldownPeriod.inSeconds,
        'cooldownPenaltyAfterSteal': cooldownPenaltyAfterSteal.inSeconds,
        'timeBeforeScramblingLetters': timeBeforeScramblingLetters.inSeconds,
        'goldenSolutionProbability': goldenSolutionProbability,
        'goldenSolutionMinimumDuration':
            goldenSolutionMinimumDuration.inSeconds,
        'minimumWordsNumber': minimumWordsNumber,
        'maximumWordsNumber': maximumWordsNumber,
        'canSteal': canSteal,
        'oneStationMaxPerRound': oneStationMaxPerRound,
        'canUseControllerHelper': canUseControllerHelper,
        'numberOfPardons': numberOfPardons,
        'boostTime': boostTime.inSeconds,
        'numberOfBoosts': numberOfBoosts,
        'numberOfBoostRequestsNeeded': numberOfBoostRequestsNeeded,
        'musicVolume': musicVolume,
        'soundVolume': soundVolume,
        'showExtension': showExtension,
      };

  ///
  /// Save the configuration to the device
  void _saveConfiguration() async {
    _logger.config('Saving configuration to device...');

    final prefs = await SharedPreferences.getInstance();
    prefs.setString('gameConfiguration', jsonEncode(serialize()));
    onChanged.notifyListeners((callback) => callback());

    _logger.config('Configuration saved');
  }

  ///
  /// Load the configuration from the device
  Future<void> _loadConfiguration() async {
    _logger.config('Loading configuration from device...');

    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('gameConfiguration');
    if (data != null) {
      final map = jsonDecode(data);

      _useCustomAdvancedOptions =
          map['useDefaultAdvancedOptions'] ?? _useCustomAdvancedOptionsDefault;

      _lastReleaseNotesShown =
          map['lastReleaseNotesShown'] ?? _lastReleaseNotesShownDefault;

      _autoplay = map['autoplay'] ?? _autoplayDefault;
      _shouldShowAutoplayDialog =
          map['shouldShowAutoplayDialog'] ?? _shouldShowAutoplayDialogDefault;
      _autoplayDuration = Duration(
          seconds: map['autoplayDuration'] ?? _autoplayDurationDefault);

      _showAnswersTooltip = false;
      _showLeaderBoard = map['showLeaderBoard'] ?? _showLeaderBoardDefault;

      _roundDuration =
          Duration(seconds: map['roundDuration'] ?? _roundDurationDefault);
      _postRoundGracePeriodDuration = Duration(
          seconds: map['postRoundGracePeriodDuration'] ??
              _postRoundGracePeriodDurationDefault);
      _postRoundShowCaseDuration = Duration(
          seconds: map['postRoundShowCaseDuration'] ??
              _postRoundShowCaseDurationDefault);
      _cooldownPeriod =
          Duration(seconds: map['cooldownPeriod'] ?? _cooldownPeriodDefault);
      _cooldownPenaltyAfterSteal = Duration(
          seconds: map['cooldownPenaltyAfterSteal'] ??
              _cooldownPenaltyAfterStealDefault);
      _timeBeforeScramblingLetters = Duration(
          seconds: map['timeBeforeScramblingLetters'] ??
              _timeBeforeScramblingLettersDefault);

      _goldenSolutionProbability =
          map['goldenSolutionProbability'] ?? _goldenSolutionProbabilityDefault;
      _goldenSolutionMinimumDuration = Duration(
          seconds: map['goldenSolutionMinimumDuration'] ??
              _goldenSolutionMinimumDurationDefault);

      _minimumWordsNumber =
          map['minimumWordsNumber'] ?? _minimumWordsNumberDefault;
      _maximumWordsNumber =
          map['maximumWordsNumber'] ?? _maximumWordsNumberDefault;

      _canSteal = map['canSteal'] ?? _canStealDefault;
      _oneStationMaxPerRound =
          map['oneStationMaxPerRound'] ?? _oneStationMaxPerRoundDefault;

      _canUseControllerHelper =
          map['canUseControllerHelper'] ?? _canUseControllerHelperDefault;
      _numberOfPardons = map['numberOfPardon'] ?? _numberOfPardonsDefault;
      _boostTime = Duration(seconds: map['boostTime'] ?? _boostTimeDefault);
      _numberOfBoosts = map['numberOfBoost'] ?? _numberOfBoostsDefault;
      _numberOfBoostRequestsNeeded = map['numberOfBoostRequestNeeded'] ??
          _numberOfBoostRequestsNeededDefault;

      _musicVolume = map['musicVolume'] ?? _musicVolumeDefault;
      _soundVolume = map['soundVolume'] ?? _soundVolumeDefault;

      _showExtension = map['showExtension'] ?? _showExtensionDefault;

      _tellGameManagerToRepickProblem();
    }

    _logger.config('Configuration loaded');
  }

  ///
  /// Reset the configuration to the default values
  void resetConfiguration(
      {required bool advancedOptions, required bool userOptions}) {
    _logger.config(
        'Resetting configuration (userOptions: $userOptions, advancedOptions: $advancedOptions)...');
    if (userOptions) {
      _lastReleaseNotesShown = _lastReleaseNotesShownDefault;

      _autoplay = _autoplayDefault;
      _shouldShowAutoplayDialog = _shouldShowAutoplayDialogDefault;
      _autoplayDuration = const Duration(seconds: _autoplayDurationDefault);

      _showAnswersTooltip = _showAnswersTooltipDefault;
      _showLeaderBoard = _showLeaderBoardDefault;

      _musicVolume = _musicVolumeDefault;
      _soundVolume = _soundVolumeDefault;

      _showExtension = _showExtensionDefault;

      ThemeManager.instance.reset();
    }

    if (advancedOptions) {
      _useCustomAdvancedOptions = _useCustomAdvancedOptionsDefault;

      _minimumWordsNumber = _minimumWordsNumberDefault;
      _maximumWordsNumber = _maximumWordsNumberDefault;

      _roundDuration = const Duration(seconds: _roundDurationDefault);
      _postRoundGracePeriodDuration =
          const Duration(seconds: _postRoundGracePeriodDurationDefault);
      _postRoundShowCaseDuration =
          const Duration(seconds: _postRoundShowCaseDurationDefault);
      _timeBeforeScramblingLetters =
          const Duration(seconds: _timeBeforeScramblingLettersDefault);
      _goldenSolutionProbability = _goldenSolutionProbabilityDefault;
      _goldenSolutionMinimumDuration =
          const Duration(seconds: _goldenSolutionMinimumDurationDefault);
      _canSteal = _canStealDefault;
      _oneStationMaxPerRound = _oneStationMaxPerRoundDefault;
      _canUseControllerHelper = _canUseControllerHelperDefault;
      _numberOfPardons = _numberOfPardonsDefault;
      _boostTime = const Duration(seconds: _boostTimeDefault);
      _numberOfBoosts = _numberOfBoostsDefault;
      _numberOfBoostRequestsNeeded = _numberOfBoostRequestsNeededDefault;
      _cooldownPeriod = const Duration(seconds: _cooldownPeriodDefault);
      _cooldownPenaltyAfterSteal =
          const Duration(seconds: _cooldownPenaltyAfterStealDefault);

      _tellGameManagerToRepickProblem();
      finalizeConfigurationChanges();
    }

    _saveConfiguration();
    _logger.config('Configuration reset');
  }

  ///
  /// Get the difficulty for a given level
  final int lastLevelWithRules = 30;
  Difficulty difficulty(int level) {
    _logger.info('Getting difficulty for level $level...');

    if (level < 3) {
      // Levels 1, 2 and 3
      _logger.info('Got difficulty for level $level (level < 3)');
      return const Difficulty(
        nbLettersOfShortestWord: 4,
        nbLettersMinToDraw: 6,
        nbLettersMaxToDraw: 7,
        thresholdFactorOneStar: 0.35,
        thresholdFactorTwoStars: 0.5,
        thresholdFactorThreeStars: 0.75,
        hasUselessLetter: false,
        hasHiddenLetter: false,
        bigHeistProbability: 0,
      );
    } else if (level < 6) {
      // Levels 4, 5 and 6
      _logger.info('Got difficulty for level $level (level < 6)');
      return const Difficulty(
        nbLettersOfShortestWord: 4,
        nbLettersMinToDraw: 6,
        nbLettersMaxToDraw: 8,
        thresholdFactorOneStar: 0.5,
        thresholdFactorTwoStars: 0.65,
        thresholdFactorThreeStars: 0.85,
        message: 'Vous vous enfoncez de plus en plus au Nord et les stations '
            's\'éloignent les unes des autres...\n'
            'Le travail d\'équipe de vos cheminot\u00b7e\u00b7s sera de la plus '
            'haute importance!',
        hasUselessLetter: false,
        hasHiddenLetter: false,
        bigHeistProbability: 0,
      );
    } else if (level < 9) {
      // Levels 7, 8 and 9
      _logger.info('Got difficulty for level $level (level < 9)');
      return const Difficulty(
        nbLettersOfShortestWord: 4,
        nbLettersMinToDraw: 6,
        nbLettersMaxToDraw: 10,
        thresholdFactorOneStar: 0.5,
        thresholdFactorTwoStars: 0.65,
        thresholdFactorThreeStars: 0.85,
        message: 'Faites attention, cheminot\u00b7e\u00b7s, vous arrivez dans '
            'terres non défrichées!\n'
            'Malgré tous nos efforts, nous ne pouvons vous '
            'assurer que les lettres que vous recevrez vous seront toutes utiles!',
        hasUselessLetter: true,
        revealUselessLetterAtTimeLeft: 30,
        hasHiddenLetter: false,
        bigHeistProbability: 0,
      );
    } else if (level < 12) {
      // Levels 10, 11 and 12
      _logger.info('Got difficulty for level $level (level < 12)');
      return const Difficulty(
        nbLettersOfShortestWord: 4,
        nbLettersMinToDraw: 6,
        nbLettersMaxToDraw: 10,
        thresholdFactorOneStar: 0.5,
        thresholdFactorTwoStars: 0.65,
        thresholdFactorThreeStars: 0.85,
        message:
            'Votre chemin est tout bonnement incroyable, cheminot\u00b7e\u00b7s! '
            'Vous avez réussi à vous frayer un chemin dans des terres inconnues!\n'
            'Mais les rails sont de plus en plus difficiles à entretenir... '
            'ne vous surprenez pas s\'il en manque des bouts',
        hasUselessLetter: true,
        revealUselessLetterAtTimeLeft: 30,
        hasHiddenLetter: true,
        revealHiddenLetterAtTimeLeft: 30,
        bigHeistProbability: 0,
      );
    } else if (level < 15) {
      // Levels 13, 14 and 15
      _logger.info('Got difficulty for level $level (level < 15)');
      return const Difficulty(
        nbLettersOfShortestWord: 4,
        nbLettersMinToDraw: 7,
        nbLettersMaxToDraw: 12,
        thresholdFactorOneStar: 0.55,
        thresholdFactorTwoStars: 0.70,
        thresholdFactorThreeStars: 0.85,
        message:
            'Encore une fois, toutes mes félicitations, cheminot\u00b7e\u00b7s! '
            'Vous avez emmené le Petit Train du Nord où nul autre n\'a osé aller, enfin depuis longtemps!\n'
            'Il sera de plus en plus difficile de vous aidez, mais nous faisons '
            'au mieux pour encore révéler les lettres qui vous seront utiles!',
        hasUselessLetter: true,
        revealUselessLetterAtTimeLeft: 15,
        hasHiddenLetter: true,
        revealHiddenLetterAtTimeLeft: 30,
        bigHeistProbability: 0.3,
      );
    } else if (level < 18) {
      // Levels 16, 17 and 18
      _logger.info('Got difficulty for level $level (level < 18)');
      return const Difficulty(
        nbLettersOfShortestWord: 5,
        nbLettersMinToDraw: 7,
        nbLettersMaxToDraw: 12,
        thresholdFactorOneStar: 0.35,
        thresholdFactorTwoStars: 0.5,
        thresholdFactorThreeStars: 0.75,
        message:
            'Ô malheur cheminot\u00b7e\u00b7s! Le carburant se raréfie et les '
            'et les réserves s\'épuisent... Nous ne pouvons plus nous permettre '
            'des petites avancées! Il faudra donc trouver des mots plus longs '
            'pour avancer!\n'
            'Bonne chance pour la suite!',
        hasUselessLetter: true,
        revealUselessLetterAtTimeLeft: 15,
        hasHiddenLetter: true,
        revealHiddenLetterAtTimeLeft: 30,
        bigHeistProbability: 0.3,
      );
    } else if (level < 21) {
      // Levels 19, 20 and 21
      _logger.info('Got difficulty for level $level (level < 21)');
      return const Difficulty(
        nbLettersOfShortestWord: 5,
        nbLettersMinToDraw: 7,
        nbLettersMaxToDraw: 12,
        thresholdFactorOneStar: 0.5,
        thresholdFactorTwoStars: 0.65,
        thresholdFactorThreeStars: 0.85,
        message: 'Nous commençons à ne plus pouvoir suivre votre rythme, '
            'cheminot\u00b7e\u00b7s, et les communications deviennent difficiles...\n'
            'Notre équipe continue de faire de son mieux pour vous aider, mais '
            'ne comptez plus trop sur nous!',
        hasUselessLetter: true,
        hasHiddenLetter: true,
        revealHiddenLetterAtTimeLeft: 30,
        bigHeistProbability: 0.5,
      );
    } else if (level < 24) {
      // Levels 22, 23 and 24
      _logger.info('Got difficulty for level $level (level < 24)');
      return const Difficulty(
        nbLettersOfShortestWord: 5,
        nbLettersMinToDraw: 7,
        nbLettersMaxToDraw: 12,
        thresholdFactorOneStar: 0.65,
        thresholdFactorTwoStars: 0.75,
        thresholdFactorThreeStars: 0.9,
        message:
            'Cheminot\u00b7e\u00b7s, vou... atteignez maintenant la limit... '
            'de nos communicat... À partir d\'ici, vo... êtes seul\u00b7e\u00b7s '
            'dans cette aventu..!\n'
            'Nous vous souh...ons bonne chance dans votre quête du Nord!',
        hasUselessLetter: true,
        hasHiddenLetter: true,
        revealHiddenLetterAtTimeLeft: 15,
        bigHeistProbability: 0.5,
      );
    } else if (level < 27) {
      // Levels 25, 26 and 27
      _logger.info('Got difficulty for level $level (level < 27)');
      return const Difficulty(
        nbLettersOfShortestWord: 5,
        nbLettersMinToDraw: 7,
        nbLettersMaxToDraw: 12,
        thresholdFactorOneStar: 0.7,
        thresholdFactorTwoStars: 0.85,
        thresholdFactorThreeStars: 0.95,
        message: '... .., ... ..\n..... ... ..!',
        hasUselessLetter: true,
        hasHiddenLetter: true,
        revealHiddenLetterAtTimeLeft: 15,
        bigHeistProbability: 0.75,
      );
    } else {
      // Levels 28 and above
      _logger.info('Got difficulty for level $level (level >= 27)');
      return const Difficulty(
        nbLettersOfShortestWord: 6,
        nbLettersMinToDraw: 7,
        nbLettersMaxToDraw: 12,
        thresholdFactorOneStar: 0.75,
        thresholdFactorTwoStars: 0.90,
        thresholdFactorThreeStars: 1.0,
        message: 'OH! OH! OH!\n'
            'Bonjour cheminot\u00b7e\u00b7s! Que faites vous ici? Mon rennes '
            'vous a vu passer il y a quelques instants! OH! OH! OH!\n'
            'Vous entrez dans les terres du Pôle Nord! Le chemin est arride et '
            'difficile ici... Je vous souhaite bonne chance! OH! OH! OH!',
        hasUselessLetter: true,
        hasHiddenLetter: true,
        revealHiddenLetterAtTimeLeft: -1,
        bigHeistProbability: 0.9,
      );
    }
  }

  //// MODIFYING THE CONFIGURATION ////

  ///
  /// If it is currently possible to change the duration of the round
  bool get canChangeDurations =>
      Managers.instance.train.gameStatus != WordsTrainGameStatus.roundStarted;

  ///
  /// If it is currently possible to change the problem picker rules
  bool get canChangeProblem =>
      Managers.instance.train.gameStatus == WordsTrainGameStatus.initializing ||
      Managers.instance.train.gameStatus == WordsTrainGameStatus.roundReady;

  void _tellGameManagerToRepickProblem() =>
      Managers.instance.train.rulesHasChanged(shouldRepickProblem: true);

  void finalizeConfigurationChanges() {
    Managers.instance.train.rulesHasChanged(repickNow: true);
  }
}
