import 'package:collection/collection.dart';
import 'package:train_de_mots/models/word_solution.dart';

class Player {
  final String name;

  int score = 0;

  bool _isAStealer = false;
  bool get isAStealer => _isAStealer;
  void hasStolen() {
    _isAStealer = true;
    stealCount++;
  }

  int stealCount = 0;

  WordSolution? lastSolutionFound;

  void resetCooldown() => _cooldownEndAt = DateTime.now();
  void startCooldown({required Duration duration}) =>
      _cooldownEndAt = DateTime.now().add(duration);
  DateTime _cooldownEndAt = DateTime.now();
  Duration get cooldownRemaining => _cooldownEndAt.difference(DateTime.now());
  bool get isInCooldownPeriod => _cooldownEndAt.isAfter(DateTime.now());

  void resetForNextRound() {
    _isAStealer = false;
    _cooldownEndAt = DateTime.now();
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
