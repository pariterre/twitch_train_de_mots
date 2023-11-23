import 'package:flutter/material.dart';
import 'package:train_de_mots/models/color_scheme.dart';
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

    GameManager.instance.onRoundIsReady.addListener(_refresh);
    GameManager.instance.onSolutionFound.addListener(_refresh);
  }

  @override
  void dispose() {
    super.dispose();

    GameManager.instance.onRoundIsReady.removeListener(_refresh);
    GameManager.instance.onSolutionFound.removeListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final gm = GameManager.instance;
    final scheme = CustomColorScheme.instance;

    WordProblem? problem = gm.problem;
    // Sort players by round score then by total score if they are equal

    final players = gm.players.sort((a, b) {
      // Unless a round has not started, then sort only by total score
      if (problem == null) return b.score - a.score;

      final roundScore = problem.scoreOf(b) - problem.scoreOf(a);
      if (roundScore != 0) return roundScore;
      return b.score - a.score;
    });

    return Container(
      padding: const EdgeInsets.all(12.0),
      width: 400,
      child: Card(
        color: scheme.mainColor,
        elevation: 10,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text('Tableau des meneurs',
                    style: TextStyle(
                      fontSize: scheme.leaderTitleSize,
                      color: scheme.leaderTextColor,
                    )),
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
              Center(
                  child: Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Text('En attente de joueurs...',
                    style: TextStyle(
                        fontSize: scheme.leaderTextSize,
                        color: scheme.leaderTextColor)),
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
      isStealer: player.isStealer,
    );
  }

  Widget _buildGenericTile({
    required String player,
    required String roundScore,
    required String totalScore,
    required bool isTitle,
    bool isStealer = false,
    _CoolDownClock? clock,
  }) {
    final scheme = CustomColorScheme.instance;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(player,
                style: TextStyle(
                    fontSize: scheme.leaderTextSize,
                    color: isStealer
                        ? scheme.leaderStealerColor
                        : scheme.leaderTextColor,
                    fontWeight: isTitle || isStealer
                        ? FontWeight.bold
                        : FontWeight.normal)),
            if (clock != null) clock,
          ],
        ),
        SizedBox(
          width: 150,
          child: Center(
            child: Text('$roundScore ($totalScore)',
                style: TextStyle(
                    fontSize: scheme.leaderTextSize,
                    color: scheme.leaderTextColor,
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
    GameManager.instance.onPlayerUpdate.addListener(_refresh);
  }

  @override
  void dispose() {
    super.dispose();
    GameManager.instance.onPlayerUpdate.removeListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final scheme = CustomColorScheme.instance;
    int value = widget.player.cooldownTimer;

    return value > 0
        ? Text(' ($value)',
            style: TextStyle(
                color: widget.player.isStealer
                    ? scheme.leaderStealerColor
                    : scheme.leaderTextColor,
                fontSize: scheme.leaderTextSize,
                fontWeight: widget.player.isStealer
                    ? FontWeight.bold
                    : FontWeight.normal))
        : const SizedBox();
  }
}
