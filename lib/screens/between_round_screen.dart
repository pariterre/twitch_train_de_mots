import 'package:flutter/material.dart';
import 'package:train_de_mots/managers/configuration_manager.dart';
import 'package:train_de_mots/managers/database_manager.dart';
import 'package:train_de_mots/managers/game_manager.dart';
import 'package:train_de_mots/managers/theme_manager.dart';
import 'package:train_de_mots/models/database_result.dart';
import 'package:train_de_mots/models/success_level.dart';
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
            width: gm.completedLevel == SuccessLevel.failed ? 1200 : 850,
            height: MediaQuery.of(context).size.height * 0.8,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const _Background(),
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 24.0),
                    if (!gm.hasPlayedAtLeastOnce) const _LeaderBoardHeader(),
                    if (gm.hasPlayedAtLeastOnce)
                      gm.successLevel == SuccessLevel.failed
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
  @override
  void initState() {
    super.initState();

    final gm = GameManager.instance;
    gm.onTimerTicks.addListener(_refresh);
  }

  @override
  void dispose() {
    super.dispose();

    final gm = GameManager.instance;
    gm.onTimerTicks.removeListener(_refresh);
  }

  void _refresh() => setState(() {});

  Future<void> _showAutoplayDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Démarrage automatique'),
        content:
            const Text('Vous venez de désactiver le démarrage automatique.\n'
                'Vous pouvez le réactiver dans les paramètres du jeu.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gm = GameManager.instance;
    final cm = ConfigurationManager.instance;
    final tm = ThemeManager.instance;

    String buttonText;
    if (!gm.isNextProblemReady) {
      buttonText = 'Aiguillage du train en cours...';
    } else if (gm.successLevel == SuccessLevel.failed &&
        gm.hasPlayedAtLeastOnce) {
      buttonText = 'Relancer le train';
    } else {
      buttonText = 'Prendre les rails';
    }
    if (gm.nextRoundStartIn != null) {
      if (gm.nextRoundStartIn!.inSeconds <= 0) {
        buttonText += ' (Lancement imminent!)';
      } else {
        buttonText += ' (${gm.nextRoundStartIn!.inSeconds} secondes)';
      }
    }

    return Column(
      children: [
        if (gm.successLevel != SuccessLevel.failed)
          Text('En direction de la Station N\u00b0${gm.roundCount + 1}',
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.normal,
                  color: tm.textColor)),
        const SizedBox(height: 12),
        ThemedElevatedButton(
            onPressed:
                gm.isNextProblemReady ? () => gm.requestStartNewRound() : null,
            buttonText: buttonText),
        const SizedBox(height: 12),
        if (gm.nextRoundStartIn != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: TextButton(
                onPressed: () async {
                  cm.autoplay = false;
                  if (cm.shouldShowAutoplayDialog) {
                    cm.shouldShowAutoplayDialog = false;
                    await _showAutoplayDialog();
                  }
                  gm.cancelAutomaticStart();
                },
                child: Text(
                  'Désactiver le démarrage automatique',
                  style: TextStyle(color: tm.textColor),
                )),
          )
      ],
    );
  }
}

class _LeaderBoard extends StatelessWidget {
  const _LeaderBoard();

  Widget _buildGameScore({required double width}) {
    final gm = GameManager.instance;
    final players = gm.players.sort();

    if (players.isEmpty) {
      return Center(child: _buildTitleTile('Aucun joueur n\'a joué'));
    }

    final nbHighestScore = players.bestPlayers.length;
    final biggestStealers = players.biggestStealers;

    const scoreWidth = 80.0;
    const spacer = 20.0;
    const stealWidth = 60.0;
    final nameWidth = width - (stealWidth + scoreWidth + spacer);

    return SingleChildScrollView(
      child: SizedBox(
        width: width,
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
                    const stealColor = Color.fromARGB(255, 255, 200, 200);

                    return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (index == 0)
                            _buildTitleTile('Meilleur\u00b7e cheminot\u00b7e'),
                          _buildNamedTile(
                            player.name,
                            highlight: isBiggestStealer,
                            suffixIcon: Icon(Icons.local_police,
                                color: isBiggestStealer
                                    ? stealColor
                                    : Colors.transparent),
                            width: nameWidth,
                          ),
                          if (players.length > nbHighestScore &&
                              index + 1 == nbHighestScore)
                            Column(
                              children: [
                                const SizedBox(height: 12.0),
                                _buildTitleTile('Autres cheminot\u00b7e\u00b7s')
                              ],
                            )
                        ]);
                  },
                ).toList()),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: stealWidth,
                  child: Column(
                      children: players.asMap().keys.map(
                    (index) {
                      final player = players[index];
                      final isBiggestStealer = biggestStealers.contains(player);

                      return Column(children: [
                        if (index == 0) _buildTitleTile('Vols'),
                        _buildScoreTile(
                            score: player.gameStealCount,
                            highlight: isBiggestStealer),
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
                const SizedBox(width: spacer),
                SizedBox(
                  width: scoreWidth,
                  child: Column(
                      children: players.asMap().keys.map(
                    (index) {
                      final player = players[index];
                      final isBiggestStealer = biggestStealers.contains(player);

                      return Column(children: [
                        if (index == 0) _buildTitleTile('Score'),
                        _buildScoreTile(
                            score: player.score, highlight: isBiggestStealer),
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
          ],
        ),
      ),
    );
  }

  Widget _buildTeamLeaderboardScore({required double width}) {
    final gm = GameManager.instance;
    final tm = ThemeManager.instance;
    final dm = DatabaseManager.instance;

    const scoreWidth = 80.0;
    final nameWidth = width - scoreWidth;

    return FutureBuilder(
        future: dm.getBestTrainStationsReached(
            top: 10, stationReached: gm.roundCount),
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTitleTile('Meilleur\u00b7e\u00b7s équipes'),
                        ...teams.map(
                          (team) => _buildNamedTile(
                            team.name,
                            highlight: team.name == dm.teamName &&
                                team.bestStation == gm.roundCount,
                            prefixText: '${team.rank}.',
                            width: nameWidth,
                          ),
                        ),
                      ]),
                  SizedBox(
                    width: scoreWidth,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _buildTitleTile('Stations'),
                          ...teams.map(
                            (team) => _buildScoreTile(
                              score: team.bestStation,
                              highlight: team.name == dm.teamName &&
                                  team.bestStation == gm.roundCount,
                            ),
                          )
                        ]),
                  ),
                ],
              ),
            ),
          );
        });
  }

  Widget _buildIndividualLeaderboardScore({required double width}) {
    final gm = GameManager.instance;
    final tm = ThemeManager.instance;

    final bestPlayers = gm.players.bestPlayers;

    const scoreWidth = 80.0;
    final nameWidth = width - scoreWidth;

    return FutureBuilder(
        future: DatabaseManager.instance
            .getBestPlayers(top: 10, bestPlayers: bestPlayers),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return SizedBox(
              width: 80,
              height: 80,
              child:
                  Center(child: CircularProgressIndicator(color: tm.mainColor)),
            );
          }

          final players = snapshot.data as List<PlayerResult>;

          if (players.isEmpty) {
            return Center(
                child:
                    _buildTitleTile('Aucun\u00b7e cheminot\u00b7e n\'a joué'));
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTitleTile(
                            'Meilleur\u00b7e\u00b7s cheminot\u00b7e\u00b7s'),
                        ...players.map(
                          (player) => _buildNamedTile(
                            '${player.name}${player.teamName.isNotEmpty ? ' (${player.teamName})' : ''}',
                            highlight: bestPlayers.any((e) =>
                                e.name == player.name &&
                                e.score == player.score),
                            prefixText: '${player.rank}.',
                            width: nameWidth,
                          ),
                        ),
                      ]),
                  SizedBox(
                    width: scoreWidth,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _buildTitleTile('Score'),
                          ...players.map(
                            (player) => _buildScoreTile(
                              score: player.score,
                              highlight: bestPlayers.any((e) =>
                                  e.name == player.name &&
                                  e.score == player.score),
                            ),
                          )
                        ]),
                  ),
                ],
              ),
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
          if (gm.hasPlayedAtLeastOnce)
            Expanded(
              child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: _buildGameScore(width: 500)),
            ),
          if (gm.successLevel == SuccessLevel.failed)
            Expanded(
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 75),
                    child: Divider(thickness: 4),
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildTeamLeaderboardScore(width: 450),
                        const SizedBox(width: 12.0),
                        const VerticalDivider(thickness: 4),
                        const SizedBox(width: 12.0),
                        _buildIndividualLeaderboardScore(width: 450),
                      ],
                    ),
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
    const stealColor = Color.fromARGB(255, 255, 200, 200);

    return TextStyle(
      fontSize: 20.0,
      fontWeight: isBiggestStealer ? FontWeight.bold : FontWeight.normal,
      color: isBiggestStealer ? stealColor : Colors.white,
    );
  }

  Widget _buildNamedTile(
    String name, {
    bool highlight = false,
    Widget? suffixIcon,
    String? prefixText,
    required double width,
  }) {
    final style = _playerStyle(highlight);

    return SizedBox(
      width: width,
      child: Padding(
        padding: EdgeInsets.only(
            top: 8.0, bottom: 8.0, left: prefixText == null ? 10 : 50),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (prefixText != null)
              Align(
                  alignment: Alignment.centerRight,
                  child: Text(prefixText, style: style)),
            const SizedBox(width: 12.0),
            Expanded(
                child:
                    Text(name, style: style, overflow: TextOverflow.ellipsis)),
            if (suffixIcon != null) suffixIcon,
          ],
        ),
      ),
    );
  }

  Widget _buildScoreTile({required int score, required bool highlight}) {
    final style = _playerStyle(highlight);

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
                'Entrée en gare à la Station N\u00b0${gm.roundCount}!',
                style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: tm.textColor),
              ),
              const SizedBox(height: 16.0),
              Text(
                'Félicitation! Nous avons traversé '
                '${gm.successLevel.toInt()} station${gm.successLevel.toInt() > 1 ? 's' : ''}!',
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.normal,
                    color: tm.textColor),
              ),
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

class _LeaderBoardHeader extends StatefulWidget {
  const _LeaderBoardHeader();

  @override
  State<_LeaderBoardHeader> createState() => _LeaderBoardHeaderState();
}

class _LeaderBoardHeaderState extends State<_LeaderBoardHeader> {
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
          Text(
            'Le tableau des cheminot\u00b7e\u00b7s',
            style: TextStyle(
                fontSize: 32, fontWeight: FontWeight.bold, color: tm.textColor),
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
