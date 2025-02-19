import 'dart:math';

import 'package:collection/collection.dart';
import 'package:train_de_mots/models/word_solution.dart';

class Player {
  final String name;

  int score = 0;
  int starsCollected = 0;

  void addToStealCount() {
    _roundStealCount++;
    _gameStealCount++;
  }

  void removeFromStealCount() {
    _roundStealCount--;
    _gameStealCount--;
  }

  int _roundStealCount = 0;
  int get roundStealCount => _roundStealCount;

  int _gameStealCount = 0;
  int get gameStealCount => _gameStealCount;

  WordSolution? lastSolutionFound;

  void startCooldown({required Duration duration}) {
    _cooldownDuration = duration;
    _cooldownEndAt = DateTime.now().add(_cooldownDuration);
  }

  DateTime _cooldownEndAt = DateTime.now();
  Duration get cooldownRemaining => _cooldownEndAt.difference(DateTime.now());
  Duration _cooldownDuration = Duration.zero;
  Duration get cooldownDuration => _cooldownDuration;

  bool get isInCooldownPeriod => _cooldownEndAt.isAfter(DateTime.now());

  void resetForNextRound() {
    _roundStealCount = 0;
    _cooldownEndAt = DateTime.now();
  }

  Player({required this.name});
}

class Players extends DelegatingList<Player> {
  final List<Player> _players;

  ///
  /// Create the delegate (that is _players and super._innerList are the same)
  Players() : this._([]);
  Players._(super.players) : _players = players;

  ///
  /// Get if the player with the given name is registered
  bool hasPlayer(String name) =>
      _players.any((element) => element.name == name);

  ///
  /// Get if the player with the given name is not registered
  bool hasNotPlayer(String name) => !hasPlayer(name);

  ///
  /// This method behaves like [firstWhere] but if the player is not found, it
  /// will add it to the list and return it.
  Player firstWhereOrAdd(String name) {
    return super.firstWhere((element) => element.name == name, orElse: () {
      final newPlayer = Player(name: name);
      _players.add(newPlayer);
      return newPlayer;
    });
  }

  ///
  /// Sort by score (default)
  @override
  Players sort([int Function(Player, Player)? compare]) {
    return Players._(
      [..._players]..sort(compare ?? (a, b) => b.score - a.score),
    );
  }

  ///
  /// Get the players with the best score
  List<Player> get bestPlayersByScore {
    final bestScore = this.bestScore;
    return _players.where((element) => element.score == bestScore).toList();
  }

  ///
  /// Get the best score
  int get bestScore => fold(0, (int prev, Player e) => max(prev, e.score));

  ///
  /// Get the players with the best score
  List<Player> get bestPlayersByStars {
    final bestStars = this.bestStars;
    if (bestStars == 0) return [];

    return _players
        .where((element) => element.starsCollected == bestStars)
        .toList();
  }

  ///
  /// Get the best stars
  int get bestStars =>
      fold(0, (int prev, Player e) => max(prev, e.starsCollected));

  ///
  /// Get the biggest stealers
  List<Player> get biggestStealers {
    final maxStealCount = this.maxStealCount;
    return _players
        .where((element) =>
            element.gameStealCount == maxStealCount && maxStealCount > 0)
        .toList();
  }

  ///
  /// Get the max steal count
  int get maxStealCount =>
      fold(0, (int prev, Player e) => max(prev, e.gameStealCount));
}
