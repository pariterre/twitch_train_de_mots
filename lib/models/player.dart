import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:train_de_mots/models/game_manager.dart';

class Player with ChangeNotifier {
  final String name;

  int _score = 0;
  int get score => _score;
  void addScore(int value) {
    _score += value;
  }

  int cooldownPeriod = 0;
  bool get isInCooldownPeriod => cooldownPeriod > 0;
  void startCooldownPeriod() async {
    cooldownPeriod = GameManager.instance.cooldownPeriod.inSeconds;
    while (cooldownPeriod > 0) {
      await Future.delayed(const Duration(seconds: 1));
      cooldownPeriod--;
      notifyListeners();
    }
  }

  Player({required this.name});
}

class Players extends DelegatingList<Player> {
  final List<Player> _players;

  ///
  /// Create the delegate (that is _players and super._innerList are the same)
  Players() : this._([]);
  Players._(List<Player> players)
      : _players = players,
        super(players);

  ///
  /// Get if the player with the given name is registered
  bool hasPlayer(String name) =>
      _players.any((element) => element.name == name);

  ///
  /// Get if the player with the given name is not registered
  bool hasNotPlayer(String name) => !hasPlayer(name);

  ///
  /// Sort by score (default)
  @override
  Players sort([int Function(Player, Player)? compare]) {
    return Players._(
      [..._players]..sort(compare ?? (a, b) => b.score - a.score),
    );
  }
}
