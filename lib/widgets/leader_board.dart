import 'package:flutter/material.dart';
import 'package:train_de_mots/models/game_manager.dart';
import 'package:train_de_mots/models/player.dart';
import 'package:train_de_mots/models/word_problem.dart';

class LeaderBoard extends StatefulWidget {
  const LeaderBoard({super.key});

  @override
  State<LeaderBoard> createState() => _LeaderBoardState();
}

class _LeaderBoardState extends State<LeaderBoard> {
  @override
  void initState() {
    super.initState();

    GameManager.instance.onRoundIsReady(_refresh);
    GameManager.instance.onSolutionFound(_refresh);
  }

  @override
  void dispose() {
    super.dispose();

    GameManager.instance.removeOnSolutionFound(_refresh);
    GameManager.instance.removeOnSolutionFound(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final gm = GameManager.instance;
    final players = gm.players.sort();
    WordProblem? problem = gm.problem;

    return SizedBox(
      width: 300,
      child: Card(
        color: Colors.blueGrey,
        elevation: 10,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Tableau des meneurs',
                    style: TextStyle(fontSize: 20, color: Colors.white)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  _buildTitleTile(),
                  const SizedBox(height: 12.0),
                  if (players.isNotEmpty)
                    for (var player in players)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: _buildPlayerTile(
                          player: player,
                          roundScore:
                              problem?.scoreOf(player).toString() ?? '0',
                        ),
                      ),
                ],
              ),
            ),
            if (players.isEmpty)
              const Center(
                  child: Padding(
                padding: EdgeInsets.only(bottom: 12.0),
                child: Text('En attente de joueurs...',
                    style: TextStyle(color: Colors.white)),
              )),
            const SizedBox(height: 12.0),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleTile() {
    return _buildGenericTile(
      player: 'Participants',
      roundScore: 'Ronde',
      totalScore: 'Total',
      isTitle: true,
    );
  }

  Widget _buildPlayerTile({
    required Player player,
    required String roundScore,
  }) {
    return _buildGenericTile(
      player: player.name,
      roundScore: roundScore,
      totalScore: player.score.toString(),
      isTitle: false,
      clock: _CoolDownClock(player: player),
    );
  }

  Widget _buildGenericTile({
    required String player,
    required String roundScore,
    required String totalScore,
    required bool isTitle,
    _CoolDownClock? clock,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(player,
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: isTitle ? FontWeight.bold : FontWeight.normal)),
            if (clock != null) clock,
          ],
        ),
        SizedBox(
          width: 100,
          child: Center(
            child: Text('$roundScore ($totalScore)',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: isTitle ? FontWeight.bold : FontWeight.normal)),
          ),
        ),
      ],
    );
  }
}

class _CoolDownClock extends StatefulWidget {
  const _CoolDownClock({required this.player});

  final Player player;

  @override
  State<_CoolDownClock> createState() => _CoolDownClockState();
}

class _CoolDownClockState extends State<_CoolDownClock> {
  @override
  void initState() {
    super.initState();
    widget.player.addListener(_refresh);
  }

  @override
  void dispose() {
    super.dispose();
    widget.player.removeListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    int value = widget.player.cooldownPeriod;
    return value > 0
        ? Text(' ($value)', style: const TextStyle(color: Colors.white))
        : const SizedBox();
  }
}
