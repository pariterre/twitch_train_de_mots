import 'dart:math';

import 'package:flutter/material.dart';
import 'package:train_de_mots/managers/database_manager.dart';
import 'package:train_de_mots/managers/game_manager.dart';
import 'package:train_de_mots/managers/theme_manager.dart';
import 'package:train_de_mots/models/team_result.dart';
import 'package:train_de_mots/models/word_problem.dart';
import 'package:train_de_mots/widgets/themed_elevated_button.dart';

class BetweenRoundsOverlay extends StatefulWidget {
  const BetweenRoundsOverlay({super.key});

  @override
  State<BetweenRoundsOverlay> createState() => _BetweenRoundsOverlayState();
}

class _BetweenRoundsOverlayState extends State<BetweenRoundsOverlay> {
  @override
  void initState() {
    super.initState();

    final gm = GameManager.instance;
    gm.onRoundIsOver.addListener(_refresh);
  }

  @override
  void dispose() {
    super.dispose();

    final gm = GameManager.instance;
    gm.onRoundIsOver.removeListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final gm = GameManager.instance;
    if (gm.problem == null) return Container();

    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.4),
          ],
          stops: const [0.4, 1.0],
          center: Alignment.center,
          radius: 1.0,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: max(MediaQuery.of(context).size.width * 0.4, 800),
            height: MediaQuery.of(context).size.height * 0.8,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const _Background(),
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 24.0),
                    gm.problem!.successLevel == SuccessLevel.failed
                        ? const _DefeatHeader()
                        : const _VictoryHeader(),
                    const _LeaderBoard(),
                    const SizedBox(height: 16.0),
                    const _ContinueButton(),
                    const SizedBox(height: 24.0),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContinueButton extends StatefulWidget {
  const _ContinueButton();

  @override
  State<_ContinueButton> createState() => _ContinueButtonState();
}

class _ContinueButtonState extends State<_ContinueButton> {
  bool _isGameReadyToPlay = false;

  @override
  void initState() {
    super.initState();

    final gm = GameManager.instance;
    gm.onNextProblemReady.addListener(_onNextProblemReady);
  }

  @override
  void dispose() {
    super.dispose();

    final gm = GameManager.instance;
    gm.onNextProblemReady.removeListener(_onNextProblemReady);
  }

  void _onNextProblemReady() {
    _isGameReadyToPlay = true;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final gm = GameManager.instance;

    return ThemedElevatedButton(
        onPressed: _isGameReadyToPlay ? () => gm.requestStartNewRound() : null,
        buttonText: _isGameReadyToPlay
            ? (gm.problem!.successLevel == SuccessLevel.failed
                ? 'Relancer le train'
                : 'Lancer la prochaine manche')
            : 'Aiguillage du train en cours...');
  }
}

class _LeaderBoard extends StatelessWidget {
  const _LeaderBoard();

  Widget _buildGameScore() {
    final gm = GameManager.instance;
    final players = gm.players.sort((a, b) => b.score - a.score);

    if (players.isEmpty) {
      return Center(child: _buildTitleTile('Aucun joueur n\'a joué'));
    }

    final highestScore = players.fold<int>(
        0, (previousValue, player) => max(previousValue, player.score));
    final nbHighestScore =
        players.where((player) => player.score == highestScore).length;

    final highestStealCount = players.fold<int>(
        0, (previousValue, player) => max(previousValue, player.stealCount));
    final biggestStealers = players.where((player) {
      return highestStealCount != 0 && player.stealCount == highestStealCount;
    }).toList();

    return SingleChildScrollView(
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: players.asMap().keys.map(
                (index) {
                  final player = players[index];
                  final isBiggestStealer = biggestStealers.contains(player);

                  return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (index == 0)
                          _buildTitleTile('Meilleur\u2022e cheminot\u2022e'),
                        _buildNamedTile(player.name,
                            highlight: isBiggestStealer,
                            prefixIcon: Icon(Icons.local_police,
                                color: isBiggestStealer
                                    ? Colors.red
                                    : Colors.transparent),
                            suffixText: isBiggestStealer
                                ? ' (Plus grand voleur!)'
                                : null),
                        if (players.length > nbHighestScore &&
                            index + 1 == nbHighestScore)
                          Column(
                            children: [
                              const SizedBox(height: 12.0),
                              _buildTitleTile('Autres cheminot\u2022e\u2022s')
                            ],
                          )
                      ]);
                },
              ).toList()),
          SizedBox(
            width: 80,
            child: Column(
                children: players.asMap().keys.map(
              (index) {
                final player = players[index];
                final isBiggestStealer = biggestStealers.contains(player);

                return Column(children: [
                  if (index == 0) _buildTitleTile('Score'),
                  _buildScoreTile(player.score, isBiggestStealer),
                  if (players.length > nbHighestScore &&
                      index + 1 == nbHighestScore)
                    Column(
                      children: [
                        const SizedBox(height: 12.0),
                        _buildTitleTile('')
                      ],
                    )
                ]);
              },
            ).toList()),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardScore() {
    final gm = GameManager.instance;
    final tm = ThemeManager.instance;
    final dm = DatabaseManager.instance;

    return FutureBuilder(
        future: dm.getBestScoresOfTrainStationsReached(
            top: 10, currentStation: gm.roundCount),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return SizedBox(
              width: 80,
              height: 80,
              child:
                  Center(child: CircularProgressIndicator(color: tm.mainColor)),
            );
          }

          final teams = snapshot.data as List<TeamResult>;

          if (teams.isEmpty) {
            return Center(
                child: _buildTitleTile('Aucune équipe n\'a encore joué'));
          }

          return SingleChildScrollView(
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _buildTitleTile(
                      'Meilleur\u2022e\u2022s équipes de cheminot\u2022e\u2022s'),
                  ...teams.map(
                    (team) => _buildNamedTile(team.name!,
                        highlight: team.name == dm.teamName &&
                            team.station == gm.roundCount,
                        prefixText: '${team.rank}.'),
                  ),
                ]),
                SizedBox(
                  width: 80,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildTitleTile('Stations'),
                        ...teams.map(
                          (team) => _buildScoreTile(
                            team.station!,
                            team.name! == dm.teamName &&
                                team.station! == gm.roundCount,
                          ),
                        )
                      ]),
                ),
              ],
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    final gm = GameManager.instance;

    return Expanded(
      child: Column(
        children: [
          Expanded(
            child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 150, vertical: 12),
                child: _buildGameScore()),
          ),
          if (gm.problem!.successLevel == SuccessLevel.failed)
            Expanded(
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 75),
                    child: Divider(thickness: 4),
                  ),
                  Expanded(
                    child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 150, vertical: 12),
                        child: _buildLeaderboardScore()),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTitleTile(String title) {
    return Text(title,
        style: const TextStyle(
            fontSize: 20.0, fontWeight: FontWeight.bold, color: Colors.white));
  }

  TextStyle _playerStyle(bool isBiggestStealer) {
    return TextStyle(
      fontSize: 20.0,
      fontWeight: isBiggestStealer ? FontWeight.bold : FontWeight.normal,
      color: isBiggestStealer ? Colors.red : Colors.white,
    );
  }

  Widget _buildNamedTile(String name,
      {bool highlight = false,
      Widget? prefixIcon,
      String? prefixText,
      String? suffixText}) {
    final style = _playerStyle(highlight);
    if (prefixIcon != null && prefixText != null) {
      throw ArgumentError(
          'prefixIcon and prefixText cannot be both non-null at the same time');
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
              width: 50,
              child: Align(
                  alignment: Alignment.centerRight,
                  child: prefixText != null
                      ? Text(prefixText, style: style)
                      : prefixIcon)),
          const SizedBox(width: 12.0),
          Text(name, style: style),
          if (suffixText != null) Text(suffixText, style: style),
        ],
      ),
    );
  }

  Widget _buildScoreTile(int score, bool isBiggestStealer) {
    final style = _playerStyle(isBiggestStealer);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(score.toString(), style: style),
    );
  }
}

class _VictoryHeader extends StatefulWidget {
  const _VictoryHeader();

  @override
  State<_VictoryHeader> createState() => _VictoryHeaderState();
}

class _VictoryHeaderState extends State<_VictoryHeader> {
  @override
  void initState() {
    super.initState();

    final tm = ThemeManager.instance;
    tm.onChanged.addListener(_refresh);
  }

  @override
  void dispose() {
    super.dispose();

    final tm = ThemeManager.instance;
    tm.onChanged.removeListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final gm = GameManager.instance;
    final tm = ThemeManager.instance;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.star,
              color: Colors.amber,
              size: 70.0,
              shadows: [Shadow(color: Colors.grey.shade500, blurRadius: 15.0)]),
          Column(
            children: [
              Text(
                'Entrée en gare!',
                style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: tm.textColor),
              ),
              const SizedBox(height: 16.0),
              Text(
                'Félicitation! Nous avons traversé '
                '${gm.problem!.successLevel.toInt()} station${gm.problem!.successLevel.toInt() > 1 ? 's' : ''}!',
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.normal,
                    color: tm.textColor),
              ),
              const SizedBox(height: 8.0),
              Text('En direction de la Station N\u00b0${gm.roundCount + 1}',
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.normal,
                      color: tm.textColor)),
              const SizedBox(height: 16.0),
            ],
          ),
          Icon(Icons.star,
              color: Colors.amber,
              size: 70.0,
              shadows: [Shadow(color: Colors.grey.shade500, blurRadius: 15.0)]),
        ],
      ),
    );
  }
}

class _Background extends StatefulWidget {
  const _Background();

  @override
  State<_Background> createState() => _BackgroundState();
}

class _BackgroundState extends State<_Background> {
  final int rainbowOpacity = 70;

  @override
  void initState() {
    super.initState();

    final tm = ThemeManager.instance;
    tm.onChanged.addListener(_refresh);
  }

  @override
  void dispose() {
    super.dispose();

    final tm = ThemeManager.instance;
    tm.onChanged.removeListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final tm = ThemeManager.instance;

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
              color: tm.mainColor, borderRadius: BorderRadius.circular(20.0)),
          child: Container(
              decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                spreadRadius: 3,
                blurRadius: 2,
                offset: const Offset(3, 3),
              ),
            ],
            gradient: LinearGradient(
              colors: [
                Colors.red.withAlpha(rainbowOpacity),
                Colors.orange.withAlpha(rainbowOpacity),
                Colors.yellow.withAlpha(rainbowOpacity),
                Colors.green.withAlpha(rainbowOpacity),
                Colors.blue.withAlpha(rainbowOpacity),
                Colors.indigo.withAlpha(rainbowOpacity),
                Colors.purple.withAlpha(rainbowOpacity),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          )),
        ),
        Image.asset('assets/images/splash_screen.png',
            height: MediaQuery.of(context).size.height * 0.6,
            fit: BoxFit.cover,
            opacity: const AlwaysStoppedAnimation(0.04)),
      ],
    );
  }
}

class _DefeatHeader extends StatefulWidget {
  const _DefeatHeader();

  @override
  State<_DefeatHeader> createState() => _DefeatHeaderState();
}

class _DefeatHeaderState extends State<_DefeatHeader> {
  @override
  void initState() {
    super.initState();

    final tm = ThemeManager.instance;
    tm.onChanged.addListener(_refresh);
  }

  @override
  void dispose() {
    super.dispose();

    final tm = ThemeManager.instance;
    tm.onChanged.removeListener(_refresh);
  }

  void _refresh() => setState(() {});
  @override
  Widget build(BuildContext context) {
    final gm = GameManager.instance;
    final tm = ThemeManager.instance;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.star,
              color: Colors.grey,
              size: 70.0,
              shadows: [Shadow(color: Colors.grey.shade800, blurRadius: 15.0)]),
          Column(
            children: [
              Text(
                'Immobilisé entre deux stations',
                style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: tm.textColor),
              ),
              const SizedBox(height: 16.0),
              Text(
                'Le Petit Train du Nord n\'a pu se rendre à destination',
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.normal,
                    color: tm.textColor),
              ),
              const SizedBox(height: 8.0),
              Text(
                  'La dernière station atteinte était la Station N\u00b0${gm.roundCount}',
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.normal,
                      color: tm.textColor)),
              const SizedBox(height: 16.0),
            ],
          ),
          Icon(Icons.star,
              color: Colors.grey,
              size: 70.0,
              shadows: [Shadow(color: Colors.grey.shade800, blurRadius: 15.0)]),
        ],
      ),
    );
  }
}
