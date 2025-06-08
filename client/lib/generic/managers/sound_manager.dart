import 'dart:math';

import 'package:common/generic/models/exceptions.dart';
import 'package:common/treasure_hunt/models/treasure_hunt_grid.dart';
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
    _logger.fine('Playing sound effect: $source...');
    final cm = Managers.instance.configuration;

    if (cm.soundVolume == 0) return;

    _lastSoundEffectAudioIndex =
        (_lastSoundEffectAudioIndex + 1) % soundEffectAudio.length;
    final soundAudio = soundEffectAudio[_lastSoundEffectAudioIndex];
    await soundAudio.setVolume(cm.soundVolume);
    await soundAudio.setAsset(source);
    await soundAudio.play();

    _logger.fine('Sound effect: $source played');
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
        thm.onTrySolution.listen(_onSolutionTried);
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
        bwm.onLetterHitByPlayer.listen(_onBlueberryWarLetterHitByPlayer);
        bwm.onLetterHitByLetter.listen(_onBlueberryWarLetterHitByLetter);
        bwm.onBlueberryDestroyed.listen(_onBlueberryWarBlueberryDestroyed);
        bwm.onTrySolution.listen(_onSolutionTried);
        bwm.onGameEnded.listen(_onBlueberryWarGameIsOver);
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

    _isInitialized = true;
    _logger.config('Ready');
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
    _playSoundEffect('packages/common/assets/sounds/GameStarted.mp3');
  }

  Future<void> _onLettersScrambled() async {
    _playSoundEffect('packages/common/assets/sounds/LettersScrambling.mp3');
  }

  Future<void> _onRoundIsOver() async {
    _playSoundEffect('packages/common/assets/sounds/RoundIsOver.mp3');
  }

  Future<void> _onSolutionFound(WordSolution? solution) async {
    if (solution == null || solution.isStolen) return;

    final gm = Managers.instance.train;

    if (solution.isGolden) {
      _playSoundEffect(
          'packages/common/assets/sounds/GoldenSolutionAppeared.mp3');
    }
    if (solution.word.length == gm.problem!.solutions.nbLettersInLongest) {
      _playSoundEffect('packages/common/assets/sounds/BestSolutionFound.mp3');
    } else {
      _playSoundEffect('packages/common/assets/sounds/SolutionFound.mp3');
    }
  }

  Future<void> _onGoldenSolutionAppeared(WordSolution solution) async {
    _playSoundEffect(
        'packages/common/assets/sounds/GoldenSolutionAppeared.mp3');
  }

  Future<void> _onSolutionStolen(WordSolution solution) async {
    _playSoundEffect('packages/common/assets/sounds/SolutionStolen.mp3');
  }

  Future<void> _onTrainGotBoosted(int boostNeeded) async {
    if (boostNeeded > 0) return;

    _playSoundEffect('packages/common/assets/sounds/GameStarted.mp3');
  }

  Future<void> playTelegramReceived() async {
    _playSoundEffect('packages/common/assets/sounds/TelegramReceived.mp3');
  }

  Future<void> playTrainReachedStation() async {
    _playSoundEffect('packages/common/assets/sounds/TrainReachedStation.mp3');
  }

  Future<void> playTrainLostStation() async {
    _playSoundEffect('packages/common/assets/sounds/TrainLostStation.mp3');
  }

  Future<void> playFireworks() async {
    final fileNumber = Random().nextInt(6) + 1;
    _playSoundEffect('packages/common/assets/sounds/Fireworks$fileNumber.mp3');
  }

  Future<void> _onAttemptingTheBigHeist() async {
    _playSoundEffect('packages/common/assets/sounds/TheBigHeist.mp3');
  }

  Future<void> _onTheBigHeistSuccess() async {
    _playSoundEffect('packages/common/assets/sounds/BigHeistSuccess.mp3');
  }

  Future<void> _onTheBigHeistFailed() async {
    _playSoundEffect('packages/common/assets/sounds/BigHeistFailed.mp3');
  }

  Future<void> _onChangingLane() async {
    _playSoundEffect('packages/common/assets/sounds/ChangingLane.mp3');
  }

  Future<void> _onTreasureHuntPluckingGrass(Tile tile) async {
    // Choose one of the 4 sounds at random
    final fileNumber = Random().nextInt(4) + 1;
    _playSoundEffect(
        'packages/common/assets/sounds/treasure_hunt/pluck_grass$fileNumber.mp3');
  }

  Future<void> _onTreasureHuntLetterFound(Tile tile) async {
    final tm = Managers.instance.miniGames.treasureHunt;
    if (tm.isGameOver && !tm.hasWon) return;

    _playSoundEffect(tile.isLetter
        ? 'packages/common/assets/sounds/SolutionFound.mp3'
        : 'packages/common/assets/sounds/treasure_hunt/picking_treasure.mp3');
  }

  Future<void> _onSolutionTried(String _, String __, bool isCorrect) async {
    if (isCorrect) {
      // Do nothing as the sound is already played in the game over
    } else {
      _playSoundEffect('packages/common/assets/sounds/SolutionStolen.mp3');
    }
  }

  Future<void> _onTreasureHuntGameIsOver(bool hasWon) async {
    if (hasWon) {
      _playSoundEffect('packages/common/assets/sounds/BestSolutionFound.mp3');
    } else {
      _playSoundEffect('packages/common/assets/sounds/RoundIsOver.mp3');
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

    _playSoundEffect(
        'packages/common/assets/sounds/blueberry_war/letter_knock.mp3');
  }

  Future<void> _onBlueberryWarLetterHitByPlayer(
      int letterIndex, bool isDestroyed) async {
    final tm = Managers.instance.miniGames.blueberryWar;
    if (tm.isGameOver) return;

    _playSoundEffect(
        'packages/common/assets/sounds/blueberry_war/letter_hit.mp3');
    if (isDestroyed) {
      _playSoundEffect('packages/common/assets/sounds/SolutionFound.mp3');
    }
  }

  Future<void> _onBlueberryWarBlueberryDestroyed(int blueberryIndex) async {
    _playSoundEffect('packages/common/assets/sounds/TrainLostStation.mp3');
  }

  Future<void> _onBlueberryWarGameIsOver(bool hasWon) async {
    if (hasWon) {
      _playSoundEffect('packages/common/assets/sounds/BestSolutionFound.mp3');
    } else {
      _playSoundEffect('packages/common/assets/sounds/RoundIsOver.mp3');
    }
  }
}
