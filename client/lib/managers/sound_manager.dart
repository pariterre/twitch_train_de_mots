import 'package:audioplayers/audioplayers.dart';
import 'package:logging/logging.dart';
import 'package:train_de_mots/managers/configuration_manager.dart';
import 'package:train_de_mots/managers/game_manager.dart';
import 'package:train_de_mots/models/exceptions.dart';
import 'package:train_de_mots/models/word_solution.dart';

final _logger = Logger('SoundManager');

class SoundManager {
  final _gameMusic = AudioPlayer();

  final Map<AudioPlayer, bool> soundEffectAudio = {};

  Future<void> _playSoundEffect(Source source) async {
    _logger.info('Playing sound effect: $source...');

    final cm = ConfigurationManager.instance;
    final soundAudio = soundEffectAudio.keys.firstWhere(
        (e) => soundEffectAudio[e] == false,
        orElse: () => AudioPlayer());

    soundEffectAudio[soundAudio] = true;
    soundAudio.onPlayerComplete
        .listen((event) => soundEffectAudio[soundAudio] = false);

    await soundAudio.setVolume(cm.soundVolume);
    await soundAudio.play(source);

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
    _logger.info('Managing game music...');

    // If we never prepared the game music, we do it now
    if (_gameMusic.state == PlayerState.stopped) {
      await _gameMusic.setReleaseMode(ReleaseMode.loop);
      await _gameMusic.play(AssetSource('sounds/TheSwindler.mp3'));
    }

    //  Set the volume
    final cm = ConfigurationManager.instance;
    await _gameMusic.setVolume(cm.musicVolume);

    _logger.info('Game music managed');
  }

  Future<void> _onRoundStarted() async {
    _playSoundEffect(AssetSource('sounds/GameStarted.mp3'));
  }

  Future<void> _onLettersScrambled() async {
    _playSoundEffect(AssetSource('sounds/LettersScrambling.mp3'));
  }

  Future<void> _onRoundIsOver(bool playSound) async {
    if (!playSound) return;
    _playSoundEffect(AssetSource('sounds/RoundIsOver.mp3'));
  }

  Future<void> _onSolutionFound(WordSolution? solution) async {
    if (solution == null || solution.isStolen) return;

    final gm = GameManager.instance;

    if (solution.word.length == gm.problem!.solutions.nbLettersInLongest) {
      _playSoundEffect(AssetSource('sounds/BestSolutionFound.mp3'));
    } else {
      _playSoundEffect(AssetSource('sounds/SolutionFound.mp3'));
    }
  }

  Future<void> _onTrainGotBoosted(int boostNeeded) async {
    if (boostNeeded > 0) return;

    _playSoundEffect(AssetSource('sounds/GameStarted.mp3'));
  }

  Future<void> playTelegramReceived() async {
    _playSoundEffect(AssetSource('sounds/TelegramReceived.mp3'));
  }

  Future<void> playTrainReachedStation() async {
    _playSoundEffect(AssetSource('sounds/TrainReachedStation.mp3'));
  }

  Future<void> playTrainLostStation() async {
    _playSoundEffect(AssetSource('sounds/TrainLostStation.mp3'));
  }
}
