import 'dart:math';

import 'package:common/models/exceptions.dart';
import 'package:just_audio/just_audio.dart';
import 'package:logging/logging.dart';
import 'package:train_de_mots/managers/configuration_manager.dart';
import 'package:train_de_mots/managers/game_manager.dart';
import 'package:train_de_mots/models/word_solution.dart';

final _logger = Logger('SoundManager');

class SoundManager {
  final _gameMusic = AudioPlayer();

  // Play up to 5 sound effects at the same time
  final soundEffectAudio = [
    AudioPlayer(),
    AudioPlayer(),
    AudioPlayer(),
    AudioPlayer(),
    AudioPlayer(),
  ];
  int _lastSoundEffectAudioIndex = -1;

  Future<void> _playSoundEffect(String source) async {
    _logger.info('Playing sound effect: $source...');
    final cm = ConfigurationManager.instance;

    if (cm.soundVolume == 0) return;

    _lastSoundEffectAudioIndex =
        (_lastSoundEffectAudioIndex + 1) % soundEffectAudio.length;
    final soundAudio = soundEffectAudio[_lastSoundEffectAudioIndex];
    await soundAudio.setVolume(cm.soundVolume);
    await soundAudio.setAsset(source);
    await soundAudio.play();

    _logger.info('Sound effect: $source played');
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
    gm.onStealerPardoned.addListener(instance._onSolutionFound);
    gm.onTrainGotBoosted.addListener(instance._onTrainGotBoosted);
    gm.onScrablingLetters.addListener(instance._onLettersScrambled);
    gm.onRevealUselessLetter.addListener(instance._onLettersScrambled);
    gm.onRevealHiddenLetter.addListener(instance._onLettersScrambled);
    gm.onRoundIsOver.addListener(instance._onRoundIsOver);
    gm.onSolutionWasStolen.addListener(instance._onSolutionStolen);
    gm.onGoldenSolutionAppeared.addListener(instance._onGoldenSolutionAppeared);
    gm.onAttemptingTheBigHeist.addListener(instance._onAttemptingTheBigHeist);
    gm.onBigHeistSuccess.addListener(instance._onTheBigHeistSuccess);
    gm.onBigHeistFailed.addListener(instance._onTheBigHeistFailed);
    gm.onChangingLane.addListener(instance._onChangingLane);

    final cm = ConfigurationManager.instance;
    cm.onGameMusicVolumeChanged.addListener(instance._manageGameMusic);
    cm.onSoundVolumeChanged.addListener(instance._onLettersScrambled);

    await instance._gameMusic.setLoopMode(LoopMode.all);
    await instance._gameMusic.setAsset('assets/sounds/TheSwindler.mp3');
  }

  Future<void> _manageGameMusic() async {
    _logger.info('Managing game music...');

    // If we never prepared the game music, we do it now
    if (!_gameMusic.playing) {
      _gameMusic.play();
    }

    //  Set the volume
    final cm = ConfigurationManager.instance;
    await _gameMusic.setVolume(cm.musicVolume);

    if (cm.musicVolume == 0) {
      _gameMusic.pause();
    }

    _logger.info('Game music managed');
  }

  Future<void> _onRoundStarted() async {
    _playSoundEffect('assets/sounds/GameStarted.mp3');
  }

  Future<void> _onLettersScrambled() async {
    _playSoundEffect('assets/sounds/LettersScrambling.mp3');
  }

  Future<void> _onRoundIsOver(bool playSound) async {
    if (!playSound) return;
    _playSoundEffect('assets/sounds/RoundIsOver.mp3');
  }

  Future<void> _onSolutionFound(WordSolution? solution) async {
    if (solution == null || solution.isStolen) return;

    final gm = GameManager.instance;

    if (solution.isGolden) {
      _playSoundEffect('assets/sounds/GoldenSolutionAppeared.mp3');
    }
    if (solution.word.length == gm.problem!.solutions.nbLettersInLongest) {
      _playSoundEffect('assets/sounds/BestSolutionFound.mp3');
    } else {
      _playSoundEffect('assets/sounds/SolutionFound.mp3');
    }
  }

  Future<void> _onGoldenSolutionAppeared(WordSolution solution) async {
    _playSoundEffect('assets/sounds/GoldenSolutionAppeared.mp3');
  }

  Future<void> _onSolutionStolen(WordSolution solution) async {
    _playSoundEffect('assets/sounds/SolutionStolen.mp3');
  }

  Future<void> _onTrainGotBoosted(int boostNeeded) async {
    if (boostNeeded > 0) return;

    _playSoundEffect('assets/sounds/GameStarted.mp3');
  }

  Future<void> playTelegramReceived() async {
    _playSoundEffect('assets/sounds/TelegramReceived.mp3');
  }

  Future<void> playTrainReachedStation() async {
    _playSoundEffect('assets/sounds/TrainReachedStation.mp3');
  }

  Future<void> playTrainLostStation() async {
    _playSoundEffect('assets/sounds/TrainLostStation.mp3');
  }

  Future<void> playFireworks() async {
    final fileNumber = Random().nextInt(6) + 1;
    _playSoundEffect('assets/sounds/Fireworks$fileNumber.mp3');
  }

  Future<void> _onAttemptingTheBigHeist() async {
    _playSoundEffect('assets/sounds/TheBigHeist.mp3');
  }

  Future<void> _onTheBigHeistSuccess() async {
    _playSoundEffect('assets/sounds/BigHeistSuccess.mp3');
  }

  Future<void> _onTheBigHeistFailed() async {
    _playSoundEffect('assets/sounds/BigHeistFailed.mp3');
  }

  Future<void> _onChangingLane() async {
    _playSoundEffect('assets/sounds/ChangingLane.mp3');
  }
}
