import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:train_de_mots/models/game_configuration.dart';
import 'package:train_de_mots/models/game_manager.dart';

class SoundManager {
  final _gameMusic = AudioPlayer();

  final _roundStarted = AudioPlayer();
  final _lettersScrambling = AudioPlayer();

  final _normalSolutionFound = AudioPlayer();
  final _bestSolutionFound = AudioPlayer();

  /// Declare the singleton
  static SoundManager get instance => _instance;
  static final SoundManager _instance = SoundManager._internal();
  SoundManager._internal() {
    final gm = ProviderContainer().read(gameManagerProvider);

    gm.onGameIsInitializing.addListener(_startGameMusic);
    gm.onRoundStarted.addListener(_onRoundStarted);
    gm.onSolutionFound.addListener(_onSolutionFound);
    gm.onScrablingLetters.addListener(_onLettersScrambled);

    ProviderContainer()
        .read(gameConfigurationProvider)
        .addListener(_onConfigurationChanged);
  }

  void _onConfigurationChanged() {
    if (ProviderContainer().read(gameConfigurationProvider).musicEnabled) {
      _gameMusic.resume();
    } else {
      _gameMusic.pause();
    }
  }

  Future<void> _startGameMusic() async {
    await _gameMusic.setReleaseMode(ReleaseMode.loop);
    await _gameMusic.play(AssetSource('sounds/TheSwindler.mp3'), volume: 0.15);

    if (!ProviderContainer().read(gameConfigurationProvider).musicEnabled) {
      _gameMusic.pause();
    }
  }

  Future<void> _onRoundStarted() async {
    await _roundStarted.play(AssetSource('sounds/GameStarted.mp3'));
  }

  Future<void> _onLettersScrambled() async {
    _lettersScrambling.play(AssetSource('sounds/LettersScrambling.mp3'),
        volume: 0.2);
  }

  Future<void> _onSolutionFound(solution) async {
    final gm = ProviderContainer().read(gameManagerProvider);

    if (solution.word.length == gm.problem!.solutions.nbLettersInLongest) {
      _bestSolutionFound.play(AssetSource('sounds/BestSolutionFound.mp3'));
    } else {
      _normalSolutionFound.play(AssetSource('sounds/SolutionFound.mp3'));
    }
  }
}
