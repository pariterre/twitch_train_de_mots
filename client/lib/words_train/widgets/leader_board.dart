import 'package:common/generic/managers/theme_manager.dart';
import 'package:flutter/material.dart';
import 'package:train_de_mots/generic/managers/managers.dart';
import 'package:train_de_mots/generic/widgets/theme_card.dart';
import 'package:train_de_mots/words_train/models/letter_problem.dart';
import 'package:train_de_mots/words_train/models/player.dart';

class LeaderBoard extends StatefulWidget {
  const LeaderBoard({super.key});

  @override
  State<LeaderBoard> createState() => _LeaderBoardState();
}

class _LeaderBoardState extends State<LeaderBoard> {
  @override
  void initState() {
    super.initState();

    final gm = Managers.instance.train;
    gm.onRoundStarted.listen(_refresh);
    gm.onSolutionFound.listen(_onSolutionFound);
    gm.onStealerPardoned.listen(_onSolutionFound);

    final cm = Managers.instance.configuration;
    cm.onChanged.listen(_refresh);

    final tm = ThemeManager.instance;
    tm.onChanged.listen(_refresh);
  }

  @override
  void dispose() {
    super.dispose();

    final gm = Managers.instance.train;
    gm.onRoundStarted.cancel(_refresh);
    gm.onSolutionFound.cancel(_onSolutionFound);
    gm.onStealerPardoned.cancel(_onSolutionFound);

    final cm = Managers.instance.configuration;
    cm.onChanged.cancel(_refresh);

    final tm = ThemeManager.instance;
    tm.onChanged.cancel(_refresh);
  }

  void _refresh() => setState(() {});
  void _onSolutionFound(_) => setState(() {});

  @override
  Widget build(BuildContext context) {
    final gm = Managers.instance.train;
    final cm = Managers.instance.configuration;
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
          ? ThemeCard(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text('Tableau des cheminot\u00b7e\u00b7s',
                          style: tm.clientMainTextStyle.copyWith(
                            fontSize: 26,
                            color: tm.leaderTextColor,
                          )),
                    ),
                    Column(
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
                    if (players.isEmpty)
                      Center(
                          child: Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Text('En attente de joueurs...',
                            style: tm.clientMainTextStyle.copyWith(
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
    final style = isTitle
        ? tm.clientMainTextStyle.copyWith(
            fontSize: 20,
            color: tm.leaderTextColor,
            fontWeight: FontWeight.bold)
        : TextStyle(
            fontSize: 20,
            color: isStealer ? tm.leaderStealerColor : tm.leaderTextColor,
            fontWeight: isStealer ? FontWeight.bold : FontWeight.normal);

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
