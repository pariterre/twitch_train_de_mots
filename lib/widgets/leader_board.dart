import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:train_de_mots/models/custom_scheme.dart';
import 'package:train_de_mots/managers/configuration_manager.dart';
import 'package:train_de_mots/models/game_manager.dart';
import 'package:train_de_mots/models/player.dart';
import 'package:train_de_mots/models/word_problem.dart';

class LeaderBoard extends ConsumerStatefulWidget {
  const LeaderBoard({super.key});

  @override
  ConsumerState<LeaderBoard> createState() => _LeaderBoardState();
}

class _LeaderBoardState extends ConsumerState<LeaderBoard> {
  @override
  void initState() {
    super.initState();

    final gm = ref.read(gameManagerProvider);
    gm.onRoundStarted.addListener(_refresh);
    gm.onSolutionFound.addListener(_onSolutionFound);

    final cm = ConfigurationManager.instance;
    cm.onChanged.addListener(_refresh);
  }

  @override
  void dispose() {
    super.dispose();

    final gm = ref.read(gameManagerProvider);
    gm.onRoundStarted.removeListener(_refresh);
    gm.onSolutionFound.removeListener(_onSolutionFound);

    final cm = ConfigurationManager.instance;
    cm.onChanged.removeListener(_refresh);
  }

  void _refresh() => setState(() {});
  void _onSolutionFound(_) => setState(() {});

  @override
  Widget build(BuildContext context) {
    final gm = ref.watch(gameManagerProvider);
    final cm = ConfigurationManager.instance;
    final scheme = ref.watch(schemeProvider);

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
      child: cm.showLeaderBoard
          ? Card(
              color: scheme.mainColor,
              elevation: 10,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text('Tableau des cheminot\u2022e\u2022s',
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
            )
          : null,
    );
  }

  Widget _buildTitleTile() {
    return _buildGenericTile(
      player: 'Cheminot\u2022e\u2022s',
      roundScore: 'Points',
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
      isStealer: player.isAStealer,
    );
  }

  Widget _buildGenericTile({
    required String player,
    required String roundScore,
    required String totalScore,
    required bool isTitle,
    bool isStealer = false,
  }) {
    final scheme = ref.read(schemeProvider);
    final style = TextStyle(
        fontSize: scheme.leaderTextSize,
        color: isStealer ? scheme.leaderStealerColor : scheme.leaderTextColor,
        fontWeight: isTitle || isStealer ? FontWeight.bold : FontWeight.normal);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(player, style: style),
        SizedBox(
            width: scheme.leaderTextSize * 7,
            child: Center(
              child: Text('$roundScore ($totalScore)', style: style),
            )),
      ],
    );
  }
}
