import 'package:audioplayers/audioplayers.dart';
import 'package:train_de_mots/managers/configuration_manager.dart';
import 'package:train_de_mots/managers/game_manager.dart';
import 'package:train_de_mots/models/exceptions.dart';

class SoundManager {
  final _gameMusic = AudioPlayer();

  final _roundStarted = AudioPlayer();
  final _telegramReceived = AudioPlayer();
  final _lettersScrambling = AudioPlayer();
  final _roundIsOver = AudioPlayer();

  final _normalSolutionFound = AudioPlayer();
  final _bestSolutionFound = AudioPlayer();
  final _trainReachedStation = AudioPlayer();

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
    final cm = ConfigurationManager.instance;

    await _roundStarted.play(AssetSource('sounds/GameStarted.mp3'),
        volume: cm.soundVolume);
  }

  Future<void> _onLettersScrambled() async {
    final cm = ConfigurationManager.instance;
    _lettersScrambling.play(AssetSource('sounds/LettersScrambling.mp3'),
        volume: cm.soundVolume);
  }

  Future<void> _onRoundIsOver() async {
    final cm = ConfigurationManager.instance;
    _roundIsOver.play(AssetSource('sounds/RoundIsOver.mp3'),
        volume: cm.soundVolume);
  }

  Future<void> _onSolutionFound(solution) async {
    final gm = GameManager.instance;
    final cm = ConfigurationManager.instance;

    if (solution.word.length == gm.problem!.solutions.nbLettersInLongest) {
      _bestSolutionFound.play(AssetSource('sounds/BestSolutionFound.mp3'),
          volume: cm.soundVolume);
    } else {
      _normalSolutionFound.play(AssetSource('sounds/SolutionFound.mp3'),
          volume: cm.soundVolume);
    }
  }

  Future<void> playTelegramReceived() async {
    final cm = ConfigurationManager.instance;
    _telegramReceived.play(AssetSource('sounds/TelegramReceived.mp3'),
        volume: cm.soundVolume);
  }

  Future<void> playTrainReachedStation() async {
    final cm = ConfigurationManager.instance;
    _trainReachedStation.play(AssetSource('sounds/TrainReachedStation.mp3'),
        volume: cm.soundVolume);
  }

  Future<void> playTrainLostStation() async {
    final cm = ConfigurationManager.instance;
    _trainReachedStation.play(AssetSource('sounds/TrainLostStation.mp3'),
        volume: cm.soundVolume);
  }
}
