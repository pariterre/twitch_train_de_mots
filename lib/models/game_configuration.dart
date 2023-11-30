import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_de_mots/models/game_manager.dart';
import 'package:train_de_mots/models/word_problem.dart';

const _nbLetterInSmallestWordDefault = 5;
const _roundDurationDefault = 180;
const _minimumWordLetterDefault = 6;
const _maximumWordLetterDefault = 8;

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

  final _canSteal = true;
  bool get canSteal => _canSteal;
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

  Duration _roundDuration = const Duration(seconds: _roundDurationDefault);
  Duration get roundDuration => _roundDuration;
  set roundDuration(Duration value) {
    _roundDuration = value;
    _saveConfiguration();
  }

  final Duration cooldownPeriod = const Duration(seconds: 15);

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

  final int minimumWordsNumber = 15;
  final int maximumWordsNumber = 25;

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
      'roundDuration': roundDuration.inSeconds,
      'nbLetterInSmallestWord': nbLetterInSmallestWord,
      'minimumWordLetter': minimumWordLetter,
      'maximumWordLetter': maximumWordLetter,
    };
  }

  ///
  /// Save the configuration to the device
  void _saveConfiguration() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('gameConfiguration', jsonEncode(serialize()));
  }

  ///
  /// Load the configuration from the device
  void _loadConfiguration() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('gameConfiguration');
    if (data != null) {
      final map = jsonDecode(data);
      _roundDuration =
          Duration(seconds: map['roundDuration'] ?? _roundDurationDefault);
      _nbLetterInSmallestWord =
          map['nbLetterInSmallestWord'] ?? _nbLetterInSmallestWordDefault;
      _minimumWordLetter =
          map['minimumWordLetter'] ?? _minimumWordLetterDefault;
      _maximumWordLetter =
          map['maximumWordLetter'] ?? _maximumWordLetterDefault;
      _tellGameManagerToRepickProblem();
    }
  }

  ///
  /// Reset the configuration to the default values
  void resetConfiguration() {
    _roundDuration = const Duration(seconds: _roundDurationDefault);
    _nbLetterInSmallestWord = _nbLetterInSmallestWordDefault;
    _minimumWordLetter = _minimumWordLetterDefault;
    _maximumWordLetter = _maximumWordLetterDefault;

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
