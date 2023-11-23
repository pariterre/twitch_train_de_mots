import 'package:collection/collection.dart';

class Player {
  final String name;

  int score = 0;

  bool isStealer = false;

  int cooldownTimer = 0;
  bool get isInCooldownPeriod => cooldownTimer > 0;

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
}
