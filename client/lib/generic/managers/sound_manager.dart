import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:collection/collection.dart';
import 'package:common/generic/managers/serializable_controllable_timer.dart';
import 'package:common/generic/models/exceptions.dart';
import 'package:common/treasure_hunt/models/treasure_hunt_grid.dart'
    as treasure_hunt_grid;
import 'package:common/warehouse_cleaning/models/avatar_agent.dart';
import 'package:common/warehouse_cleaning/models/warehouse_cleaning_grid.dart'
    as warehouse_cleaning_grid;
import 'package:logging/logging.dart';
import 'package:train_de_mots/fix_tracks/managers/fix_tracks_game_manager.dart';
import 'package:train_de_mots/generic/managers/audio_context/audio_context_stub.dart'
    if (dart.library.html) 'package:train_de_mots/generic/managers/audio_context/audio_context_web.dart';
import 'package:train_de_mots/generic/managers/managers.dart';
import 'package:train_de_mots/words_train/models/word_solution.dart';

final _logger = Logger('SoundManager');

const _baseFolder = 'sounds';

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
  blueberryWarLetterHit,
  warehouseCleaningAvatarLaunched1,
  warehouseCleaningAvatarLaunched2,
  warehouseCleaningAvatarLaunched3,
  warehouseCleaningAvatarLaunched4;

  static final _soundsAssets = <_SoundEffect, Source>{};

  static void initializeAssets() {
    if (_soundsAssets.isNotEmpty) {
      _logger.severe('Sound effects assets are already initialized.');
      throw Exception('Sound effects assets are already initialized.');
    }

    _logger.info('Initializing sound effects assets...');
    for (final sound in _SoundEffect.values) {
      _soundsAssets[sound] = AssetSource(sound._toFilePath());
    }
  }

  Source get audioSource {
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
    return switch (this) {
      _SoundEffect.gameStarted => '$_baseFolder/GameStarted.mp3',
      _SoundEffect.lettersScrambling => '$_baseFolder/LettersScrambling.mp3',
      _SoundEffect.roundIsOver => '$_baseFolder/RoundIsOver.mp3',
      _SoundEffect.bestSolutionFound => '$_baseFolder/BestSolutionFound.mp3',
      _SoundEffect.solutionFound => '$_baseFolder/SolutionFound.mp3',
      _SoundEffect.goldenSolutionAppeared =>
        '$_baseFolder/GoldenSolutionAppeared.mp3',
      _SoundEffect.solutionStolen => '$_baseFolder/SolutionStolen.mp3',
      _SoundEffect.newBoostGranted => '$_baseFolder/NewBoostGranted.mp3',
      _SoundEffect.telegramReceived => '$_baseFolder/TelegramReceived.mp3',
      _SoundEffect.trainReachedStation =>
        '$_baseFolder/TrainReachedStation.mp3',
      _SoundEffect.trainLostStation => '$_baseFolder/TrainLostStation.mp3',
      _SoundEffect.fireworks1 => '$_baseFolder/Fireworks1.mp3',
      _SoundEffect.fireworks2 => '$_baseFolder/Fireworks2.mp3',
      _SoundEffect.fireworks3 => '$_baseFolder/Fireworks3.mp3',
      _SoundEffect.fireworks4 => '$_baseFolder/Fireworks4.mp3',
      _SoundEffect.fireworks5 => '$_baseFolder/Fireworks5.mp3',
      _SoundEffect.fireworks6 => '$_baseFolder/Fireworks6.mp3',
      _SoundEffect.theBigHeist => '$_baseFolder/TheBigHeist.mp3',
      _SoundEffect.theBigHeistSuccess => '$_baseFolder/BigHeistSuccess.mp3',
      _SoundEffect.theBigHeistFailed => '$_baseFolder/BigHeistFailed.mp3',
      _SoundEffect.changingLane => '$_baseFolder/ChangingLane.mp3',
      _SoundEffect.treasureHuntPluckGrass1 =>
        '$_baseFolder/treasure_hunt/pluck_grass1.mp3',
      _SoundEffect.treasureHuntPluckGrass2 =>
        '$_baseFolder/treasure_hunt/pluck_grass2.mp3',
      _SoundEffect.treasureHuntPluckGrass3 =>
        '$_baseFolder/treasure_hunt/pluck_grass3.mp3',
      _SoundEffect.treasureHuntPluckGrass4 =>
        '$_baseFolder/treasure_hunt/pluck_grass4.mp3',
      _SoundEffect.treasureHuntPickingTreasure =>
        '$_baseFolder/treasure_hunt/picking_treasure.mp3',
      _SoundEffect.blueberryWarLetterKnock =>
        '$_baseFolder/blueberry_war/letter_knock.mp3',
      _SoundEffect.blueberryWarLetterHit =>
        '$_baseFolder/blueberry_war/letter_hit.mp3',
      _SoundEffect.warehouseCleaningAvatarLaunched1 =>
        '$_baseFolder/warehouse_cleaning/avatar_launched1.mp3',
      _SoundEffect.warehouseCleaningAvatarLaunched2 =>
        '$_baseFolder/warehouse_cleaning/avatar_launched2.mp3',
      _SoundEffect.warehouseCleaningAvatarLaunched3 =>
        '$_baseFolder/warehouse_cleaning/avatar_launched3.mp3',
      _SoundEffect.warehouseCleaningAvatarLaunched4 =>
        '$_baseFolder/warehouse_cleaning/avatar_launched4.mp3',
    };
  }
}

class _AudioPlayerManager {
  bool isAvailable = true;
  final AudioPlayer _audioPlayer = AudioPlayer();

  static final _audioContext = AudioContextWrapper();

  Future<void> play(Source source, double volume) async {
    if (_audioContext.state != "running") return;

    try {
      isAvailable = false;
      await _audioPlayer.play(source,
          volume: volume, mode: PlayerMode.lowLatency);
      await _audioPlayer.onPlayerComplete.first;
    } finally {
      await _audioPlayer.stop();
      isAvailable = true;
    }
  }
}

class SoundManager {
  final _gameMusic = AudioPlayer()..setReleaseMode(ReleaseMode.loop);
  bool _isMusicPlaying = false;

  // Play up to 5 sound effects at the same time
  final _soundEffectAudio = <_AudioPlayerManager>[];

  Future<void> _playSoundEffect(_SoundEffect soundEffect) async {
    if (!_isInitialized) {
      _logger.warning(
          'SoundManager is not initialized yet. Cannot play sound effect: $soundEffect');
      return;
    }
    _logger.fine('Playing sound effect: $soundEffect...');
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

    await soundAudio.play(
        soundEffect.audioSource, pow(cm.soundVolume, 2) as double);

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
        gm.onTrainCollectedBoost.listen(_onNewBoostGranted);
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
        thm.onRoundEnded.listen(_onTreasureHuntGameIsOver);
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
        bwm.onRoundEnded.listen(_onBlueberryWarGameIsOver);
        break;
      } on ManagerNotInitializedException {
        // Retry until the manager is initialized
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }

    while (true) {
      try {
        final wccm = Managers.instance.miniGames.warehouseCleaning;
        wccm.onAvatarLaunched.listen(_onWareHouseCleaningAvatarLaunched);
        wccm.onLetterFound.listen(_onWareHouseCleaningLetterFound);
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
        tfm.onRoundEnded.listen(_onFixTracksGameIsOver);
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

    _SoundEffect.initializeAssets();

    _isInitialized = true;
    _logger.config('Ready');
  }

  Future<void> _manageGameMusic() async {
    _logger.info('Managing game music...');

    // If we never prepared the game music, we do it now
    if (!_isMusicPlaying) {
      while (_AudioPlayerManager._audioContext.state != "running") {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      _gameMusic.play(AssetSource('$_baseFolder/TheSwindler.mp3'));
      _isMusicPlaying = true;
    }

    //  Set the volume
    final cm = Managers.instance.configuration;
    await _gameMusic.setVolume(pow(cm.musicVolume, 2) as double);

    if (cm.musicVolume == 0) {
      _gameMusic.pause();
      _isMusicPlaying = false;
    }

    _logger.info('Game music managed');
  }

  void _onRoundStarted() {
    _playSoundEffect(_SoundEffect.gameStarted);
  }

  void _onLettersScrambled() {
    _playSoundEffect(_SoundEffect.lettersScrambling);
  }

  void _onRoundIsOver() {
    _playSoundEffect(_SoundEffect.roundIsOver);
  }

  void _onSolutionFound(WordSolution? solution) {
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

  void _onGoldenSolutionAppeared(WordSolution solution) {
    _playSoundEffect(_SoundEffect.goldenSolutionAppeared);
  }

  void _onSolutionStolen(WordSolution solution) {
    _playSoundEffect(_SoundEffect.solutionStolen);
  }

  void _onNewBoostGranted() {
    _playSoundEffect(_SoundEffect.newBoostGranted);
  }

  void _onTrainGotBoosted(int boostNeeded) {
    if (boostNeeded > 0) return;

    _playSoundEffect(_SoundEffect.gameStarted);
  }

  void playTelegramReceived() {
    _playSoundEffect(_SoundEffect.telegramReceived);
  }

  void playTrainReachedStation() {
    _playSoundEffect(_SoundEffect.trainReachedStation);
  }

  void playTrainLostStation() {
    _playSoundEffect(_SoundEffect.trainLostStation);
  }

  void playFireworks() {
    final fileNumber = Random().nextInt(6) + 1;
    _playSoundEffect(_SoundEffect.values
        .firstWhere((e) => e.toString() == 'fireworks$fileNumber'));
  }

  void _onAttemptingTheBigHeist({required String login}) {
    _playSoundEffect(_SoundEffect.theBigHeist);
  }

  void _onTheBigHeistSuccess() {
    _playSoundEffect(_SoundEffect.theBigHeistSuccess);
  }

  void _onTheBigHeistFailed() {
    _playSoundEffect(_SoundEffect.theBigHeistFailed);
  }

  void _onChangingLane() {
    _playSoundEffect(_SoundEffect.changingLane);
  }

  void _onTreasureHuntPluckingGrass(treasure_hunt_grid.Tile tile) {
    // Choose one of the 4 sounds at random
    final fileNumber = Random().nextInt(4) + 1;
    _playSoundEffect(_SoundEffect.values.firstWhere(
        (e) => e.toString() == 'treasureHuntPluckGrass$fileNumber'));
  }

  void _onTreasureHuntLetterFound(treasure_hunt_grid.Tile tile) {
    final tm = Managers.instance.miniGames.treasureHunt;
    if (tm.roundStatus != ControllableTimerStatus.inProgress) return;

    _playSoundEffect(tile.isLetter
        ? _SoundEffect.solutionFound
        : _SoundEffect.treasureHuntPickingTreasure);
  }

  void _onTreasureHuntSolutionTried({
    required String playerName,
    required String word,
    required bool isSolutionRight,
    required int pointsAwarded,
  }) {
    if (isSolutionRight) {
      // Do nothing as the sound is already played in the game over
    } else {
      _playSoundEffect(_SoundEffect.solutionStolen);
    }
  }

  void _onBlueberrySolutionTried({
    required String playerName,
    required String word,
    required bool isSolutionRight,
    required int pointsAwarded,
  }) {
    if (isSolutionRight) {
      // Do nothing as the sound is already played in the game over
    } else {
      _playSoundEffect(_SoundEffect.solutionStolen);
    }
  }

  void _onTreasureHuntGameIsOver() {
    final thgm = Managers.instance.miniGames.treasureHunt;
    if (thgm.hasWon) {
      _playSoundEffect(_SoundEffect.solutionFound);
      _playSoundEffect(_SoundEffect.bestSolutionFound);
    } else {
      _playSoundEffect(_SoundEffect.roundIsOver);
    }
  }

  DateTime _lastLetterHitByLetterPlayed = DateTime.now();
  void _onBlueberryWarLetterHitByLetter(
      int first, int second, bool firstIsBoss, bool secondIsBoss) {
    final tm = Managers.instance.miniGames.blueberryWar;
    if (tm.roundStatus != ControllableTimerStatus.inProgress) return;

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

  void _onBlueberryWarLetterHitByBlueberry(int letterIndex, bool isDestroyed) {
    final tm = Managers.instance.miniGames.blueberryWar;
    if (tm.roundStatus != ControllableTimerStatus.inProgress) return;

    _playSoundEffect(_SoundEffect.blueberryWarLetterHit);
    if (isDestroyed) {
      _playSoundEffect(_SoundEffect.solutionFound);
    }
  }

  void _onBlueberryWarBlueberryDestroyed(int blueberryIndex) {
    _playSoundEffect(_SoundEffect.trainLostStation);
  }

  void _onBlueberryWarGameIsOver() {
    final bwm = Managers.instance.miniGames.blueberryWar;
    if (bwm.hasWon) {
      _playSoundEffect(_SoundEffect.solutionFound);
      _playSoundEffect(_SoundEffect.bestSolutionFound);
    } else {
      _playSoundEffect(_SoundEffect.roundIsOver);
    }
  }

  void _onWareHouseCleaningAvatarLaunched(AvatarAgent avatar) {
    final tm = Managers.instance.miniGames.warehouseCleaning;
    if (tm.roundStatus != ControllableTimerStatus.inProgress) return;
    final fileNumber = Random().nextInt(4) + 1;
    _playSoundEffect(_SoundEffect.values.firstWhere(
        (e) => e.toString() == 'warehouseCleaningAvatarLaunched$fileNumber'));
  }

  void _onWareHouseCleaningLetterFound(warehouse_cleaning_grid.Tile tile) {
    final tm = Managers.instance.miniGames.warehouseCleaning;
    if (tm.roundStatus != ControllableTimerStatus.inProgress) return;

    _playSoundEffect(_SoundEffect.solutionFound);
  }

  void _onFixTracksSolutionTried(
      {required String playerName,
      required String word,
      required FixTracksSolutionStatus solutionStatus,
      required int pointsAwarded}) {
    if (solutionStatus == FixTracksSolutionStatus.isValid) {
      _playSoundEffect(_SoundEffect.solutionFound);
    }
  }

  void _onFixTracksGameIsOver() {
    final ftgm = Managers.instance.miniGames.fixTracks;
    if (ftgm.endGameStatus == EndGameStatus.won) {
      _playSoundEffect(_SoundEffect.bestSolutionFound);
    } else {
      _playSoundEffect(_SoundEffect.roundIsOver);
    }
  }
}
