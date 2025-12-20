import 'dart:math';

import 'package:collection/collection.dart';
import 'package:common/generic/models/exceptions.dart';
import 'package:common/treasure_hunt/models/treasure_hunt_grid.dart';
import 'package:just_audio/just_audio.dart';
import 'package:logging/logging.dart';
import 'package:train_de_mots/fix_tracks/managers/fix_tracks_game_manager.dart';
import 'package:train_de_mots/generic/managers/managers.dart';
import 'package:train_de_mots/words_train/models/word_solution.dart';
import 'package:web/web.dart';

final _logger = Logger('SoundManager');

enum _SoundEffect {
  gameStarted,
  lettersScrambling,
  roundIsOver,
  bestSolutionFound,
  solutionFound,
  goldenSolutionAppeared,
  solutionStolen,
  newBoostGranted,
  telegramReceived,
  trainReachedStation,
  trainLostStation,
  fireworks1,
  fireworks2,
  fireworks3,
  fireworks4,
  fireworks5,
  fireworks6,
  theBigHeist,
  theBigHeistSuccess,
  theBigHeistFailed,
  changingLane,
  treasureHuntPluckGrass1,
  treasureHuntPluckGrass2,
  treasureHuntPluckGrass3,
  treasureHuntPluckGrass4,
  treasureHuntPickingTreasure,
  blueberryWarLetterKnock,
  blueberryWarLetterHit;

  static final _soundsAssets = <_SoundEffect, AudioSource>{};

  static void initializeAssets() {
    if (_soundsAssets.isNotEmpty) {
      _logger.severe('Sound effects assets are already initialized.');
      throw Exception('Sound effects assets are already initialized.');
    }

    _logger.info('Initializing sound effects assets...');
    for (final sound in _SoundEffect.values) {
      _soundsAssets[sound] = AudioSource.asset(sound._toFilePath());
    }
  }

  AudioSource get audioSource {
    final source = _soundsAssets[this];
    if (source == null) {
      _logger.severe('Sound effect asset not initialized: $this');
      throw Exception('Sound effect asset not initialized: $this');
    }
    return source;
  }

  @override
  String toString() {
    return name;
  }

  String _toFilePath() {
    const baseFolder = 'packages/common/assets/sounds';
    return switch (this) {
      _SoundEffect.gameStarted => '$baseFolder/GameStarted.mp3',
      _SoundEffect.lettersScrambling => '$baseFolder/LettersScrambling.mp3',
      _SoundEffect.roundIsOver => '$baseFolder/RoundIsOver.mp3',
      _SoundEffect.bestSolutionFound => '$baseFolder/BestSolutionFound.mp3',
      _SoundEffect.solutionFound => '$baseFolder/SolutionFound.mp3',
      _SoundEffect.goldenSolutionAppeared =>
        '$baseFolder/GoldenSolutionAppeared.mp3',
      _SoundEffect.solutionStolen => '$baseFolder/SolutionStolen.mp3',
      _SoundEffect.newBoostGranted => '$baseFolder/NewBoostGranted.mp3',
      _SoundEffect.telegramReceived => '$baseFolder/TelegramReceived.mp3',
      _SoundEffect.trainReachedStation => '$baseFolder/TrainReachedStation.mp3',
      _SoundEffect.trainLostStation => '$baseFolder/TrainLostStation.mp3',
      _SoundEffect.fireworks1 => '$baseFolder/Fireworks1.mp3',
      _SoundEffect.fireworks2 => '$baseFolder/Fireworks2.mp3',
      _SoundEffect.fireworks3 => '$baseFolder/Fireworks3.mp3',
      _SoundEffect.fireworks4 => '$baseFolder/Fireworks4.mp3',
      _SoundEffect.fireworks5 => '$baseFolder/Fireworks5.mp3',
      _SoundEffect.fireworks6 => '$baseFolder/Fireworks6.mp3',
      _SoundEffect.theBigHeist => '$baseFolder/TheBigHeist.mp3',
      _SoundEffect.theBigHeistSuccess => '$baseFolder/BigHeistSuccess.mp3',
      _SoundEffect.theBigHeistFailed => '$baseFolder/BigHeistFailed.mp3',
      _SoundEffect.changingLane => '$baseFolder/ChangingLane.mp3',
      _SoundEffect.treasureHuntPluckGrass1 =>
        '$baseFolder/treasure_hunt/pluck_grass1.mp3',
      _SoundEffect.treasureHuntPluckGrass2 =>
        '$baseFolder/treasure_hunt/pluck_grass2.mp3',
      _SoundEffect.treasureHuntPluckGrass3 =>
        '$baseFolder/treasure_hunt/pluck_grass3.mp3',
      _SoundEffect.treasureHuntPluckGrass4 =>
        '$baseFolder/treasure_hunt/pluck_grass4.mp3',
      _SoundEffect.treasureHuntPickingTreasure =>
        '$baseFolder/treasure_hunt/picking_treasure.mp3',
      _SoundEffect.blueberryWarLetterKnock =>
        '$baseFolder/blueberry_war/letter_knock.mp3',
      _SoundEffect.blueberryWarLetterHit =>
        '$baseFolder/blueberry_war/letter_hit.mp3',
    };
  }
}

class _AudioPlayerManager {
  bool isAvailable = true;
  final AudioPlayer _audioPlayer = AudioPlayer();

  static final _audioContext = AudioContext();

  Future<void> play(AudioSource source, double volume) async {
    if (_audioContext.state != "running") return;

    try {
      isAvailable = false;
      await _audioPlayer.setVolume(volume);
      await _audioPlayer.setAudioSource(source);
      await _audioPlayer.play();
    } finally {
      await _audioPlayer.stop();
      await _audioPlayer.seek(Duration.zero);
      isAvailable = true;
    }
  }
}

class SoundManager {
  final _gameMusic = AudioPlayer();

  // Play up to 5 sound effects at the same time
  final _soundEffectAudio = <_AudioPlayerManager>[];

  Future<void> _playSoundEffect(_SoundEffect soundEffect) async {
    if (!_isInitialized) {
      _logger.warning(
          'SoundManager is not initialized yet. Cannot play sound effect: $soundEffect');
      return;
    }
    _logger.info('Playing sound effect: $soundEffect...');
    final cm = Managers.instance.configuration;

    if (cm.soundVolume == 0) return;

    var soundAudio =
        _soundEffectAudio.firstWhereOrNull((audio) => audio.isAvailable);
    if (soundAudio == null) {
      soundAudio = _AudioPlayerManager();
      _soundEffectAudio.add(soundAudio);
      _logger.fine(
          'All audio players are busy. Creating a new one to play sound effect: $soundEffect');
    }

    await soundAudio.play(soundEffect.audioSource, cm.soundVolume);

    _logger.fine('Sound effect: $soundEffect played');
  }

  ///
  /// This method initializes the singleton and should be called before
  /// using the singleton.
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  SoundManager() {
    _asyncInitializations();
  }

  Future<void> _asyncInitializations() async {
    _logger.config('Initializing...');

    // Main game sounds
    while (true) {
      try {
        final gm = Managers.instance.train;
        gm.onGameIsInitializing.listen(_manageGameMusic);
        gm.onRoundStarted.listen(_onRoundStarted);
        gm.onSolutionFound.listen(_onSolutionFound);
        gm.onStealerPardoned.listen(_onSolutionFound);
        gm.onNewBoostGranted.listen(_onNewBoostGranted);
        gm.onTrainGotBoosted.listen(_onTrainGotBoosted);
        gm.onScrablingLetters.listen(_onLettersScrambled);
        gm.onRevealUselessLetter.listen(_onLettersScrambled);
        gm.onRevealHiddenLetter.listen(_onLettersScrambled);
        gm.onRoundIsOver.listen(_onRoundIsOver);
        gm.onSolutionWasStolen.listen(_onSolutionStolen);
        gm.onGoldenSolutionAppeared.listen(_onGoldenSolutionAppeared);
        gm.onAttemptingTheBigHeist.listen(_onAttemptingTheBigHeist);
        gm.onBigHeistSuccess.listen(_onTheBigHeistSuccess);
        gm.onBigHeistFailed.listen(_onTheBigHeistFailed);
        gm.onChangingLane.listen(_onChangingLane);
        break;
      } on ManagerNotInitializedException {
        // Retry until the manager is initialized
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
    // Minigame Treasure Hunt sounds
    while (true) {
      try {
        final thm = Managers.instance.miniGames.treasureHunt;
        thm.onTileRevealed.listen(_onTreasureHuntPluckingGrass);
        thm.onRewardFound.listen(_onTreasureHuntLetterFound);
        thm.onTrySolution.listen(_onTreasureHuntSolutionTried);
        thm.onGameEnded.listen(_onTreasureHuntGameIsOver);
        break;
      } on ManagerNotInitializedException {
        // Retry until the manager is initialized
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }

    // Minigame Blueberry War sounds
    while (true) {
      try {
        final bwm = Managers.instance.miniGames.blueberryWar;
        bwm.onLetterHitByBlueberry.listen(_onBlueberryWarLetterHitByBlueberry);
        bwm.onLetterHitByLetter.listen(_onBlueberryWarLetterHitByLetter);
        bwm.onBlueberryDestroyed.listen(_onBlueberryWarBlueberryDestroyed);
        bwm.onTrySolution.listen(_onBlueberrySolutionTried);
        bwm.onGameEnded.listen(_onBlueberryWarGameIsOver);
        break;
      } on ManagerNotInitializedException {
        // Retry until the manager is initialized
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }

    // Minigame Track fix sounds
    while (true) {
      try {
        final tfm = Managers.instance.miniGames.fixTracks;
        tfm.onTrySolution.listen(_onFixTracksSolutionTried);
        tfm.onGameEnded.listen(_onFixTracksGameIsOver);
        break;
      } on ManagerNotInitializedException {
        // Retry until the manager is initialized
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }

    while (true) {
      try {
        final cm = Managers.instance.configuration;
        cm.onGameMusicVolumeChanged.listen(_manageGameMusic);
        cm.onSoundVolumeChanged.listen(_onLettersScrambled);
        break;
      } on ManagerNotInitializedException {
        // Retry until the manager is initialized
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
    _gameMusic.setLoopMode(LoopMode.all);
    _gameMusic.setAsset('packages/common/assets/sounds/TheSwindler.mp3');

    _SoundEffect.initializeAssets();

    _isInitialized = true;
    _logger.config('Ready');
  }

  Future<void> _manageGameMusic() async {
    _logger.info('Managing game music...');

    // If we never prepared the game music, we do it now
    if (!_gameMusic.playing) {
      while (_AudioPlayerManager._audioContext.state != "running") {
        await Future.delayed(const Duration(milliseconds: 100));
      }
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
    _playSoundEffect(_SoundEffect.gameStarted);
  }

  Future<void> _onLettersScrambled() async {
    _playSoundEffect(_SoundEffect.lettersScrambling);
  }

  Future<void> _onRoundIsOver() async {
    _playSoundEffect(_SoundEffect.roundIsOver);
  }

  Future<void> _onSolutionFound(WordSolution? solution) async {
    if (solution == null || solution.isStolen) return;

    final gm = Managers.instance.train;

    if (solution.isGolden) {
      _playSoundEffect(_SoundEffect.goldenSolutionAppeared);
    }
    if (solution.word.length == gm.problem!.solutions.nbLettersInLongest) {
      _playSoundEffect(_SoundEffect.bestSolutionFound);
    } else {
      _playSoundEffect(_SoundEffect.solutionFound);
    }
  }

  Future<void> _onGoldenSolutionAppeared(WordSolution solution) async {
    _playSoundEffect(_SoundEffect.goldenSolutionAppeared);
  }

  Future<void> _onSolutionStolen(WordSolution solution) async {
    _playSoundEffect(_SoundEffect.solutionStolen);
  }

  Future<void> _onNewBoostGranted() async {
    _playSoundEffect(_SoundEffect.newBoostGranted);
  }

  Future<void> _onTrainGotBoosted(int boostNeeded) async {
    if (boostNeeded > 0) return;

    _playSoundEffect(_SoundEffect.gameStarted);
  }

  Future<void> playTelegramReceived() async {
    _playSoundEffect(_SoundEffect.telegramReceived);
  }

  Future<void> playTrainReachedStation() async {
    _playSoundEffect(_SoundEffect.trainReachedStation);
  }

  Future<void> playTrainLostStation() async {
    _playSoundEffect(_SoundEffect.trainLostStation);
  }

  Future<void> playFireworks() async {
    final fileNumber = Random().nextInt(6) + 1;
    switch (fileNumber) {
      case 1:
        _playSoundEffect(_SoundEffect.fireworks1);
        break;
      case 2:
        _playSoundEffect(_SoundEffect.fireworks2);
        break;
      case 3:
        _playSoundEffect(_SoundEffect.fireworks3);
        break;
      case 4:
        _playSoundEffect(_SoundEffect.fireworks4);
        break;
      case 5:
        _playSoundEffect(_SoundEffect.fireworks5);
        break;
      case 6:
        _playSoundEffect(_SoundEffect.fireworks6);
        break;
      default:
        break;
    }
  }

  Future<void> _onAttemptingTheBigHeist({required String playerName}) async {
    _playSoundEffect(_SoundEffect.theBigHeist);
  }

  Future<void> _onTheBigHeistSuccess() async {
    _playSoundEffect(_SoundEffect.theBigHeistSuccess);
  }

  Future<void> _onTheBigHeistFailed() async {
    _playSoundEffect(_SoundEffect.theBigHeistFailed);
  }

  Future<void> _onChangingLane() async {
    _playSoundEffect(_SoundEffect.changingLane);
  }

  Future<void> _onTreasureHuntPluckingGrass(Tile tile) async {
    // Choose one of the 4 sounds at random
    final fileNumber = Random().nextInt(4) + 1;
    switch (fileNumber) {
      case 1:
        _playSoundEffect(_SoundEffect.treasureHuntPluckGrass1);
        break;
      case 2:
        _playSoundEffect(_SoundEffect.treasureHuntPluckGrass2);
        break;
      case 3:
        _playSoundEffect(_SoundEffect.treasureHuntPluckGrass3);
        break;
      case 4:
        _playSoundEffect(_SoundEffect.treasureHuntPluckGrass4);
        break;
      default:
        break;
    }
  }

  Future<void> _onTreasureHuntLetterFound(Tile tile) async {
    final tm = Managers.instance.miniGames.treasureHunt;
    if (tm.isGameOver && !tm.hasWon) return;

    _playSoundEffect(tile.isLetter
        ? _SoundEffect.solutionFound
        : _SoundEffect.treasureHuntPickingTreasure);
  }

  Future<void> _onTreasureHuntSolutionTried({
    required String playerName,
    required String word,
    required bool isSolutionRight,
    required int pointsAwarded,
  }) async {
    if (isSolutionRight) {
      // Do nothing as the sound is already played in the game over
    } else {
      _playSoundEffect(_SoundEffect.solutionStolen);
    }
  }

  Future<void> _onBlueberrySolutionTried({
    required String playerName,
    required String word,
    required bool isSolutionRight,
    required int pointsAwarded,
  }) async {
    if (isSolutionRight) {
      // Do nothing as the sound is already played in the game over
    } else {
      _playSoundEffect(_SoundEffect.solutionStolen);
    }
  }

  Future<void> _onTreasureHuntGameIsOver({required bool hasWon}) async {
    if (hasWon) {
      _playSoundEffect(_SoundEffect.bestSolutionFound);
    } else {
      _playSoundEffect(_SoundEffect.roundIsOver);
    }
  }

  DateTime _lastLetterHitByLetterPlayed = DateTime.now();
  Future<void> _onBlueberryWarLetterHitByLetter(
      int first, int second, bool firstIsBoss, bool secondIsBoss) async {
    final tm = Managers.instance.miniGames.blueberryWar;
    if (tm.isGameOver) return;
    // If both letters are not bosses, we don't play the sound
    if (!firstIsBoss && !secondIsBoss) return;

    // Prevent spamming the sound effect
    if (_lastLetterHitByLetterPlayed
        .add(const Duration(milliseconds: 100))
        .isAfter(DateTime.now())) {
      return;
    }
    _lastLetterHitByLetterPlayed = DateTime.now();

    _playSoundEffect(_SoundEffect.blueberryWarLetterKnock);
  }

  Future<void> _onBlueberryWarLetterHitByBlueberry(
      int letterIndex, bool isDestroyed) async {
    final tm = Managers.instance.miniGames.blueberryWar;
    if (tm.isGameOver) return;

    _playSoundEffect(_SoundEffect.blueberryWarLetterHit);
    if (isDestroyed) {
      _playSoundEffect(_SoundEffect.solutionFound);
    }
  }

  Future<void> _onBlueberryWarBlueberryDestroyed(int blueberryIndex) async {
    _playSoundEffect(_SoundEffect.trainLostStation);
  }

  Future<void> _onBlueberryWarGameIsOver({required bool hasWon}) async {
    if (hasWon) {
      _playSoundEffect(_SoundEffect.bestSolutionFound);
    } else {
      _playSoundEffect(_SoundEffect.roundIsOver);
    }
  }

  Future<void> _onFixTracksSolutionTried(
      {required String playerName,
      required String word,
      required FixTracksSolutionStatus solutionStatus,
      required int pointsAwarded}) async {
    if (solutionStatus == FixTracksSolutionStatus.isValid) {
      _playSoundEffect(_SoundEffect.solutionFound);
    }
  }

  Future<void> _onFixTracksGameIsOver({required bool hasWon}) async {
    if (hasWon) {
      _playSoundEffect(_SoundEffect.bestSolutionFound);
    } else {
      _playSoundEffect(_SoundEffect.roundIsOver);
    }
  }
}
