import 'package:flutter/material.dart';
import 'package:train_de_mots/managers/configuration_manager.dart';
import 'package:train_de_mots/managers/game_manager.dart';
import 'package:train_de_mots/managers/theme_manager.dart';
import 'package:train_de_mots/models/letter_problem.dart';
import 'package:train_de_mots/models/player.dart';

class LeaderBoard extends StatefulWidget {
  const LeaderBoard({super.key});

  @override
  State<LeaderBoard> createState() => _LeaderBoardState();
}

class _LeaderBoardState extends State<LeaderBoard> {
  @override
  void initState() {
    super.initState();

    final gm = GameManager.instance;
    gm.onRoundStarted.addListener(_refresh);
    gm.onSolutionFound.addListener(_onSolutionFound);
    gm.onStealerPardonned.addListener(_onSolutionFound);

    final cm = ConfigurationManager.instance;
    cm.onChanged.addListener(_refresh);

    final tm = ThemeManager.instance;
    tm.onChanged.addListener(_refresh);
  }

  @override
  void dispose() {
    super.dispose();

    final gm = GameManager.instance;
    gm.onRoundStarted.removeListener(_refresh);
    gm.onSolutionFound.removeListener(_onSolutionFound);
    gm.onStealerPardonned.removeListener(_onSolutionFound);

    final cm = ConfigurationManager.instance;
    cm.onChanged.removeListener(_refresh);

    final tm = ThemeManager.instance;
    tm.onChanged.removeListener(_refresh);
  }

  void _refresh() => setState(() {});
  void _onSolutionFound(_) => setState(() {});

  @override
  Widget build(BuildContext context) {
    final gm = GameManager.instance;
    final cm = ConfigurationManager.instance;
    final tm = ThemeManager.instance;

    LetterProblem? problem = gm.problem;
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
      width: 425,
      height: 350,
      child: cm.showLeaderBoard
          ? Card(
              color: tm.mainColor,
              elevation: 10,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text('Tableau des cheminot\u00b7e\u00b7s',
                            style: TextStyle(
                              fontSize: 26,
                              color: tm.leaderTextColor,
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
                                      problem?.scoreOf(player).toString() ??
                                          '0',
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
                                fontSize: 20, color: tm.leaderTextColor)),
                      )),
                    const SizedBox(height: 12.0),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildTitleTile() {
    return _buildGenericTile(
      player: 'Cheminot\u00b7e\u00b7s',
      roundScore: 'Points',
      totalScore: 'Total',
      isTitle: true,
    );
  }

  Widget _buildPlayerTile({
    required Player player,
    required String roundScore,
  }) {
    return SizedBox(
      width: 400,
      child: _buildGenericTile(
        player: player.name,
        roundScore: roundScore,
        totalScore: player.score.toString(),
        isTitle: false,
        isStealer: player.roundStealCount > 0,
      ),
    );
  }

  Widget _buildGenericTile({
    required String player,
    required String roundScore,
    required String totalScore,
    required bool isTitle,
    bool isStealer = false,
  }) {
    final tm = ThemeManager.instance;
    final style = TextStyle(
        fontSize: 20,
        color: isStealer ? tm.leaderStealerColor : tm.leaderTextColor,
        fontWeight: isTitle || isStealer ? FontWeight.bold : FontWeight.normal);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
            child: Text(player, style: style, overflow: TextOverflow.ellipsis)),
        SizedBox(
            width: tm.leaderTextSize * 7,
            child: Center(
              child: Text('$roundScore ($totalScore)', style: style),
            )),
      ],
    );
  }
}
