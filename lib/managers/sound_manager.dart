import 'package:audioplayers/audioplayers.dart';
import 'package:train_de_mots/managers/configuration_manager.dart';
import 'package:train_de_mots/managers/game_manager.dart';
import 'package:train_de_mots/models/exceptions.dart';
import 'package:train_de_mots/models/word_solution.dart';

class SoundManager {
  final _gameMusic = AudioPlayer();

  Future<AudioPlayer> get _soundEffect async {
    final audio = AudioPlayer();
    audio.onPlayerComplete.listen((event) {
      audio.dispose();
    });

    final cm = ConfigurationManager.instance;
    await audio.setVolume(cm.soundVolume);

    return audio;
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
    (await _soundEffect).play(AssetSource('sounds/GameStarted.mp3'));
  }

  Future<void> _onLettersScrambled() async {
    (await _soundEffect).play(AssetSource('sounds/LettersScrambling.mp3'));
  }

  Future<void> _onRoundIsOver() async {
    (await _soundEffect).play(AssetSource('sounds/RoundIsOver.mp3'));
  }

  Future<void> _onSolutionFound(WordSolution solution) async {
    final gm = GameManager.instance;

    if (solution.word.length == gm.problem!.solutions.nbLettersInLongest) {
      (await _soundEffect).play(AssetSource('sounds/BestSolutionFound.mp3'));
    } else {
      (await _soundEffect).play(AssetSource('sounds/SolutionFound.mp3'));
    }
  }

  Future<void> playTelegramReceived() async {
    (await _soundEffect).play(AssetSource('sounds/TelegramReceived.mp3'));
  }

  Future<void> playTrainReachedStation() async {
    (await _soundEffect).play(AssetSource('sounds/TrainReachedStation.mp3'));
  }

  Future<void> playTrainLostStation() async {
    (await _soundEffect).play(AssetSource('sounds/TrainLostStation.mp3'));
  }
}
