import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:train_de_mots/managers/configuration_manager.dart';
import 'package:train_de_mots/managers/game_manager.dart';
import 'package:train_de_mots/models/exceptions.dart';
import 'package:train_de_mots/models/word_solution.dart';

import 'package:mutex/mutex.dart';

class SoundManager {
  final _gameMusic = AudioPlayer();

  final _soundEffectMutex = Mutex();
  late final _soundEffectAudio = AudioPlayer()
    ..onPlayerComplete.listen((event) => _soundEffectMutex.release());
  Future<void> _playSoundEffect(Source source,
      {required bool allowSkip}) async {
    if (kIsWeb && _soundEffectMutex.isLocked && allowSkip) return;
    await _soundEffectMutex.acquire();

    final cm = ConfigurationManager.instance;
    await _soundEffectAudio.setVolume(cm.soundVolume);
    await _soundEffectAudio.play(source);
  }

  /// Declare the singleton
  static SoundManager get instance {
    if (_instance == null) {
      throw ManagerNotInitializedException(
          'SoundManager must be initialized before being used');
    }
    return _instance!;
  }

  static SoundManager? _instance;
  SoundManager._internal();

  ///
  /// This method initializes the singleton and should be called before
  /// using the singleton.
  static Future<void> initialize() async {
    if (_instance != null) {
      throw ManagerAlreadyInitializedException(
          'SoundManager should not be initialized twice');
    }

    SoundManager._instance = SoundManager._internal();

    late final gm = GameManager.instance;
    gm.onGameIsInitializing.addListener(instance._manageGameMusic);
    gm.onRoundStarted.addListener(instance._onRoundStarted);
    gm.onSolutionFound.addListener(instance._onSolutionFound);
    gm.onStealerPardonned.addListener(instance._onSolutionFound);
    gm.onTrainGotBoosted.addListener(instance._onTrainGotBoosted);
    gm.onScrablingLetters.addListener(instance._onLettersScrambled);
    gm.onRevealUselessLetter.addListener(instance._onLettersScrambled);
    gm.onRevealHiddenLetter.addListener(instance._onLettersScrambled);
    gm.onRoundIsOver.addListener(instance._onRoundIsOver);

    final cm = ConfigurationManager.instance;
    cm.onMusicChanged.addListener(instance._manageGameMusic);
    cm.onSoundChanged.addListener(instance._onLettersScrambled);
  }

  Future<void> _manageGameMusic() async {
    // If we never prepared the game music, we do it now
    if (_gameMusic.state == PlayerState.stopped) {
      await _gameMusic.setReleaseMode(ReleaseMode.loop);
      await _gameMusic.play(AssetSource('sounds/TheSwindler.mp3'));
    }

    //  Set the volume
    final cm = ConfigurationManager.instance;
    await _gameMusic.setVolume(cm.musicVolume);
  }

  Future<void> _onRoundStarted() async {
    _playSoundEffect(AssetSource('sounds/GameStarted.mp3'), allowSkip: false);
  }

  Future<void> _onLettersScrambled() async {
    _playSoundEffect(AssetSource('sounds/LettersScrambling.mp3'),
        allowSkip: false);
  }

  Future<void> _onRoundIsOver(bool playSound) async {
    if (!playSound) return;
    _playSoundEffect(AssetSource('sounds/RoundIsOver.mp3'), allowSkip: false);
  }

  Future<void> _onSolutionFound(WordSolution? solution) async {
    if (solution == null || solution.isStolen) return;

    final gm = GameManager.instance;

    if (solution.word.length == gm.problem!.solutions.nbLettersInLongest) {
      _playSoundEffect(AssetSource('sounds/BestSolutionFound.mp3'),
          allowSkip: false);
    } else {
      _playSoundEffect(AssetSource('sounds/SolutionFound.mp3'),
          allowSkip: true);
    }
  }

  Future<void> _onTrainGotBoosted(int boostNeeded) async {
    if (boostNeeded > 0) return;

    _playSoundEffect(AssetSource('sounds/GameStarted.mp3'), allowSkip: false);
  }

  Future<void> playTelegramReceived() async {
    _playSoundEffect(AssetSource('sounds/TelegramReceived.mp3'),
        allowSkip: false);
  }

  Future<void> playTrainReachedStation() async {
    _playSoundEffect(AssetSource('sounds/TrainReachedStation.mp3'),
        allowSkip: false);
  }

  Future<void> playTrainLostStation() async {
    _playSoundEffect(AssetSource('sounds/TrainLostStation.mp3'),
        allowSkip: false);
  }
}
