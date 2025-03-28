import 'dart:math';

import 'package:common/models/exceptions.dart';
import 'package:just_audio/just_audio.dart';
import 'package:logging/logging.dart';
import 'package:train_de_mots/generic/managers/managers.dart';
import 'package:train_de_mots/words_train/models/word_solution.dart';

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
    final cm = Managers.instance.configuration;

    if (cm.soundVolume == 0) return;

    _lastSoundEffectAudioIndex =
        (_lastSoundEffectAudioIndex + 1) % soundEffectAudio.length;
    final soundAudio = soundEffectAudio[_lastSoundEffectAudioIndex];
    await soundAudio.setVolume(cm.soundVolume);
    await soundAudio.setAsset(source);
    await soundAudio.play();

    _logger.info('Sound effect: $source played');
  }

  SoundManager._();

  ///
  /// This method initializes the singleton and should be called before
  /// using the singleton.
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  static Future<SoundManager> factory() async {
    final instance = SoundManager._();

    instance._connectListeners();

    await instance._gameMusic.setLoopMode(LoopMode.all);
    await instance._gameMusic.setAsset('assets/sounds/TheSwindler.mp3');

    return instance;
  }

  Future<void> _connectListeners() async {
    while (true) {
      try {
        final gm = Managers.instance.train;
        gm.onGameIsInitializing.addListener(_manageGameMusic);
        gm.onRoundStarted.addListener(_onRoundStarted);
        gm.onSolutionFound.addListener(_onSolutionFound);
        gm.onStealerPardoned.addListener(_onSolutionFound);
        gm.onTrainGotBoosted.addListener(_onTrainGotBoosted);
        gm.onScrablingLetters.addListener(_onLettersScrambled);
        gm.onRevealUselessLetter.addListener(_onLettersScrambled);
        gm.onRevealHiddenLetter.addListener(_onLettersScrambled);
        gm.onRoundIsOver.addListener(_onRoundIsOver);
        gm.onSolutionWasStolen.addListener(_onSolutionStolen);
        gm.onGoldenSolutionAppeared.addListener(_onGoldenSolutionAppeared);
        gm.onAttemptingTheBigHeist.addListener(_onAttemptingTheBigHeist);
        gm.onBigHeistSuccess.addListener(_onTheBigHeistSuccess);
        gm.onBigHeistFailed.addListener(_onTheBigHeistFailed);
        gm.onChangingLane.addListener(_onChangingLane);
        break;
      } on ManagerNotInitializedException {
        // Retry until the manager is initialized
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }

    while (true) {
      try {
        final cm = Managers.instance.configuration;
        cm.onGameMusicVolumeChanged.addListener(_manageGameMusic);
        cm.onSoundVolumeChanged.addListener(_onLettersScrambled);
        break;
      } on ManagerNotInitializedException {
        // Retry until the manager is initialized
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }

    _isInitialized = true;
    _logger.info('SoundManager initialized');
  }

  Future<void> _manageGameMusic() async {
    _logger.info('Managing game music...');

    // If we never prepared the game music, we do it now
    if (!_gameMusic.playing) {
      _gameMusic.play();
    }

    //  Set the volume
    final cm = Managers.instance.configuration;
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

    final gm = Managers.instance.train;

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
