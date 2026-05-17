import 'dart:math';

import 'package:collection/collection.dart';
import 'package:common/generic/managers/serializable_controllable_timer.dart';
import 'package:common/generic/models/serializable_player.dart';
import 'package:logging/logging.dart';
import 'package:train_de_mots/generic/managers/controllable_timer.dart';
import 'package:train_de_mots/generic/managers/managers.dart';
import 'package:train_de_mots/words_train/models/word_solution.dart';

final _logger = Logger('Player');

class Player {
  final String displayName;
  final String login;

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
    cooldownTimer.initialize();
    cooldownTimer.start(duration: duration);
  }

  late final cooldownTimer =
      ControllableTimer(onStatusChanged: _manageEndOfCooldown);
  void _manageEndOfCooldown(ControllableTimerStatus newStatus) {
    if (newStatus == ControllableTimerStatus.ended) {
      cooldownTimer.dispose();
    }
  }

  bool get isInCooldownPeriod => cooldownTimer.isInitialized;

  void resetForNextRound() {
    _roundStealCount = 0;
    if (cooldownTimer.isInitialized) cooldownTimer.dispose();
  }

  Player({required this.login, required this.displayName});

  SerializablePlayer serialize() {
    return SerializablePlayer(
      login: login,
      displayName: displayName,
      score: score,
      starsCollected: starsCollected,
      roundStealCount: roundStealCount,
      gameStealCount: gameStealCount,
      cooldownTimer: cooldownTimer.toSerializable(),
    );
  }
}

class Players extends DelegatingList<Player> {
  final List<Player> _players;

  ///
  /// Create the delegate (that is _players and super._innerList are the same)
  Players() : this._([]);
  Players._(super.players) : _players = players;

  ///
  /// This method behaves like [firstWhere] but if the player is not found, it
  /// will add it to the list and return it.
  Future<Player> firstWhereOrAdd(String login) async {
    Player? player = firstWhereOrNull((element) => element.login == login);
    if (player == null) {
      final displayName =
          await Managers.instance.twitch.displayNameFromLogin(login);
      if (displayName == null) {
        _logger.warning(
            'No display name found for login $login, using login as display name');
        throw Exception('No display name found for login $login');
      }
      final newPlayer = Player(login: login, displayName: displayName);
      _players.add(newPlayer);
      player = newPlayer;
    }

    return player;
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
