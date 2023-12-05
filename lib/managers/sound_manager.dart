import 'package:audioplayers/audioplayers.dart';
import 'package:train_de_mots/managers/configuration_manager.dart';
import 'package:train_de_mots/managers/game_manager.dart';

class SoundManager {
  final _gameMusic = AudioPlayer();

  final _roundStarted = AudioPlayer();
  final _lettersScrambling = AudioPlayer();
  final _roundIsOver = AudioPlayer();

  final _normalSolutionFound = AudioPlayer();
  final _bestSolutionFound = AudioPlayer();

  /// Declare the singleton
  static SoundManager get instance => _instance;
  static final SoundManager _instance = SoundManager._internal();
  SoundManager._internal() {
    final gm = GameManager.instance;
    gm.onGameIsInitializing.addListener(_manageGameMusic);
    gm.onRoundStarted.addListener(_onRoundStarted);
    gm.onSolutionFound.addListener(_onSolutionFound);
    gm.onScrablingLetters.addListener(_onLettersScrambled);
    gm.onRoundIsOver.addListener(_onRoundIsOver);

    final cm = ConfigurationManager.instance;
    cm.onMusicChanged.addListener(_manageGameMusic);
    cm.onSoundChanged.addListener(_onLettersScrambled);
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
}
