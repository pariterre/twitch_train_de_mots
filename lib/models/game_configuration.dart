import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_de_mots/models/game_manager.dart';
import 'package:train_de_mots/models/word_problem.dart';

const _showAnswersTooltipDefault = false;

const _roundDurationDefault = 180;
const _cooldownPeriodDefault = 15;
const _cooldownPeriodAfterStealDefault = 30;
const _timeBeforeScramblingLettersDefault = 15;

const _nbLetterInSmallestWordDefault = 5;
const _minimumWordLetterDefault = 6;
const _maximumWordLetterDefault = 8;
const _minimumWordsNumberDefault = 15;
const _maximumWordsNumberDefault = 25;

const _canStealDefault = true;

// Declare the GameConfiguration provider
final gameConfigurationProvider =
    ChangeNotifierProvider<_GameConfiguration>((ref) {
  return _GameConfiguration.instance;
});

class _GameConfiguration with ChangeNotifier {
  ///
  /// Declare the singleton
  static _GameConfiguration get instance => _instance;
  static final _GameConfiguration _instance = _GameConfiguration._internal();
  _GameConfiguration._internal() {
    _loadConfiguration();
    _listenToGameManagerEvents();
  }

  final Future<WordProblem> Function({
    required int nbLetterInSmallestWord,
    required int minLetters,
    required int maxLetters,
    required int minimumNbOfWords,
    required int maximumNbOfWords,
  }) _problemGenerator = WordProblem.generateFromRandom;
  Future<WordProblem> Function({
    required int nbLetterInSmallestWord,
    required int minLetters,
    required int maxLetters,
    required int minimumNbOfWords,
    required int maximumNbOfWords,
  }) get problemGenerator => _problemGenerator;

  bool _showAnswersTooltip = _showAnswersTooltipDefault;
  bool get showAnswersTooltip => _showAnswersTooltip;
  set showAnswersTooltip(bool value) {
    _showAnswersTooltip = value;
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

  bool _canSteal = _canStealDefault;
  bool get canSteal => _canSteal;
  set canSteal(bool value) {
    _canSteal = value;
    _saveConfiguration();
  }

  //// LISTEN TO GAME MANAGER ////
  void _listenToGameManagerEvents() {
    final gm = ProviderContainer().read(gameManagerProvider);
    gm.onRoundIsPreparing.addListener(_reactToGameManagerEvent);
    gm.onNextProblemReady.addListener(_reactToGameManagerEvent);
    gm.onRoundStarted.addListener(_reactToGameManagerEvent);
    gm.onRoundIsOver.addListener(_reactToGameManagerEvent);
  }

  void _reactToGameManagerEvent() => notifyListeners();

  //// LOAD AND SAVE ////

  ///
  /// Serialize the configuration to a map
  Map<String, dynamic> serialize() {
    return {
      'showAnswersTooltip': showAnswersTooltip,
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
    };
  }

  ///
  /// Save the configuration to the device
  void _saveConfiguration() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('gameConfiguration', jsonEncode(serialize()));
    notifyListeners();
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

      _canSteal = map['canSteal'] ?? _canStealDefault;

      _tellGameManagerToRepickProblem();
    }
  }

  ///
  /// Reset the configuration to the default values
  void resetConfiguration() {
    _showAnswersTooltip = _showAnswersTooltipDefault;

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

    _canSteal = _canStealDefault;

    _tellGameManagerToRepickProblem();
    _saveConfiguration();
  }

  //// MODIFYING THE CONFIGURATION ////

  ///
  /// If it is currently possible to change the duration of the roudn
  bool get canChangeDurations =>
      !ProviderContainer().read(gameManagerProvider).hasAnActiveRound;

  ///
  /// If it is currently possible to change the problem picker rules
  bool get canChangeProblem {
    final gm = ProviderContainer().read(gameManagerProvider);
    return !gm.isSearchingForProblem && !gm.hasAnActiveRound;
  }

  void _tellGameManagerToRepickProblem() {
    final container = ProviderContainer();
    container
        .read(gameManagerProvider)
        .rulesHasChanged(shoulRepickProblem: true);
  }

  void finalizeConfigurationChanges() {
    ProviderContainer()
        .read(gameManagerProvider)
        .rulesHasChanged(repickNow: true);
  }
}
