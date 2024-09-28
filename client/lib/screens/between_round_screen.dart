import 'package:common/managers/theme_manager.dart';
import 'package:common/widgets/bouncy_container.dart';
import 'package:common/widgets/themed_elevated_button.dart';
import 'package:flutter/material.dart';
import 'package:train_de_mots/managers/configuration_manager.dart';
import 'package:train_de_mots/managers/database_manager.dart';
import 'package:train_de_mots/managers/game_manager.dart';
import 'package:train_de_mots/managers/mocks_configuration.dart';
import 'package:train_de_mots/models/database_result.dart';
import 'package:train_de_mots/models/player.dart';
import 'package:train_de_mots/models/round_success.dart';
import 'package:train_de_mots/models/success_level.dart';
import 'package:train_de_mots/widgets/growing_widget.dart';
import 'package:train_de_mots/widgets/parchment_dialog.dart';

class BetweenRoundsOverlay extends StatefulWidget {
  const BetweenRoundsOverlay({super.key});

  @override
  State<BetweenRoundsOverlay> createState() => _BetweenRoundsOverlayState();
}

class _BetweenRoundsOverlayState extends State<BetweenRoundsOverlay> {
  final _attemptingTheBigHeist = BouncyContainerController(
      bounceCount: 1,
      easingInDuration: 900,
      bouncingDuration: 6000,
      easingOutDuration: 600,
      minScale: 0.95,
      bouncyScale: 1.0,
      maxScale: 1.0,
      maxOpacity: 0.99);

  @override
  void initState() {
    super.initState();

    final gm = GameManager.instance;
    gm.onRoundIsOver.addListener(_refresh);
    gm.onAttemptingTheBigHeist.addListener(_showAttemptingTheBigHeist);
  }

  @override
  void dispose() {
    super.dispose();

    final gm = GameManager.instance;
    gm.onRoundIsOver.removeListener(_refresh);
    gm.onAttemptingTheBigHeist.removeListener(_showAttemptingTheBigHeist);
    _attemptingTheBigHeist.dispose();
  }

  void _refresh(_) => setState(() {});

  void _showAttemptingTheBigHeist() {
    _attemptingTheBigHeist.triggerAnimation(const _AttemptingTheBigHeist());
  }

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
            width: gm.successLevel == SuccessLevel.failed ? 1200 : 850,
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
                    const _ContinueSection(),
                    const SizedBox(height: 24.0),
                  ],
                ),
                Positioned(
                  top: MediaQuery.of(context).size.height * 0.13,
                  child: BouncyContainer(controller: _attemptingTheBigHeist),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContinueSection extends StatefulWidget {
  const _ContinueSection();

  @override
  State<_ContinueSection> createState() => _ContinueSectionState();
}

class _ContinueSectionState extends State<_ContinueSection> {
  bool _canClick = true;

  @override
  void initState() {
    super.initState();

    final gm = GameManager.instance;
    gm.onClockTicked.addListener(_refresh);
    gm.onCongratulationFireworks.addListener(_toggleCanClick);
  }

  @override
  void dispose() {
    super.dispose();

    final gm = GameManager.instance;
    gm.onClockTicked.removeListener(_refresh);
  }

  void _toggleCanClick(Map<String, dynamic> info) {
    bool isCongratulating = (info['is_congratulating'] as bool?) ?? false;
    setState(() => _canClick = !isCongratulating);
  }

  void _refresh() => setState(() {});

  Future<void> _showAutoplayDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) => ParchmentDialog(
        title: 'Démarrage automatique',
        content:
            const Text('Vous venez de désactiver le démarrage automatique.\n'
                'Vous pouvez le réactiver dans les paramètres du jeu.'),
        acceptButtonTitle: 'OK',
        width: 500,
        height: 200,
        padding: const EdgeInsets.symmetric(horizontal: 50.0),
        onAccept: () => Navigator.of(context).pop(),
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
        buttonText +=
            ' (${gm.nextRoundStartIn!.inSeconds} seconde${gm.nextRoundStartIn!.inSeconds > 1 ? 's' : ''})';
      }
    }

    return Column(
      children: [
        if (gm.successLevel != SuccessLevel.failed)
          Text('En direction de la Station N\u00b0${gm.roundCount + 1}',
              style: tm.clientMainTextStyle.copyWith(
                  fontSize: 26,
                  fontWeight: FontWeight.normal,
                  color: tm.textColor)),
        const SizedBox(height: 12),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (gm.hasPlayedAtLeastOnce)
              ThemedElevatedButton(
                onPressed: _canClick ? gm.requestShowCaseAnswers : null,
                buttonText: 'Revoir les réponses',
              ),
            const SizedBox(width: 24),
            ThemedElevatedButton(
                onPressed: _canClick && gm.isNextProblemReady
                    ? () => gm.requestStartNewRound()
                    : null,
                buttonText: buttonText),
            if (MocksConfiguration.showDebugOptions)
              Row(
                children: [
                  const SizedBox(width: 24),
                  ThemedElevatedButton(
                      onPressed: _canClick
                          ? () => gm.onCongratulationFireworks
                                  .notifyListenersWithParameter({
                                'is_congratulating': true,
                                'player_name': 'Anynome'
                              })
                          : null,
                      buttonText: 'BOOM!'),
                  const SizedBox(width: 24),
                  ThemedElevatedButton(
                      onPressed: _canClick && gm.canAttemptTheBigHeist
                          ? () => gm.requestTheBigHeist()
                          : null,
                      buttonText: 'Le grand coup')
                ],
              )
          ],
        ),
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
                  setState(() {});
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

  final Color _winnerColor = Colors.amber;
  final Color _stealerColor = const Color.fromARGB(255, 255, 200, 200);

  Color? _highlightBestScoreColor(
      {required Player player,
      required TeamResult team,
      required Players players}) {
    // Define some aliases
    final biggestStealers = players.biggestStealers;
    final mvpPlayers = team.mvpPlayers.map((e) => e.name);

    // Check some feats of the player
    final isBiggestStealer = biggestStealers.contains(player);
    final isMvpPlayer = mvpPlayers.contains(player.name);

    // Define the color to use
    if (isMvpPlayer) {
      return _winnerColor;
    } else if (isBiggestStealer) {
      return _stealerColor;
    } else {
      return null;
    }
  }

  Color? _highlightBestTeamColor({required TeamResult team}) {
    final dm = DatabaseManager.instance;
    final gm = GameManager.instance;

    final shouldHighlight = team.name == dm.teamName &&
        (team.bestStation == gm.roundCount || !gm.hasPlayedAtLeastOnce);
    if (shouldHighlight) {
      return _winnerColor;
    } else {
      return null;
    }
  }

  Color? _highlightBestPlayerColor({required PlayerResult player}) {
    final dm = DatabaseManager.instance;
    final gm = GameManager.instance;

    final bestPlayers = gm.players.bestPlayers;
    final shouldHighlight = bestPlayers
            .any((e) => (e.name == player.name && e.score == player.score)) ||
        (!gm.hasPlayedAtLeastOnce && player.teamName == dm.teamName);

    if (shouldHighlight) {
      return _winnerColor;
    } else {
      return null;
    }
  }

  Widget? _playerSuffixWidget(
      {required Player player,
      required TeamResult teamResult,
      required Players players}) {
    // Define some aliases
    final biggestStealers = players.biggestStealers;
    final mvpPlayers = teamResult.mvpPlayers.map((e) => e.name);

    // Check some feats of the player
    final isBiggestStealer = biggestStealers.contains(player);
    final isMvpPlayer = mvpPlayers.contains(player.name);

    // Define the icon to use
    if (isMvpPlayer) {
      return const GrowingWidget(
          growingFactor: 0.9,
          duration: Duration(milliseconds: 1000),
          child: Icon(Icons.emoji_events, color: Colors.amber));
    } else if (isBiggestStealer) {
      return const GrowingWidget(
          growingFactor: 0.93,
          duration: Duration(milliseconds: 500),
          child: Icon(Icons.local_police, color: Colors.red));
    } else {
      return null;
    }
  }

  Widget _buildGameScore({required double width}) {
    final gm = GameManager.instance;
    final players = gm.players.sort();

    if (players.isEmpty) {
      return Center(child: _buildTitleTile('Aucun joueur n\'a joué'));
    }

    final nbHighestScore = players.bestPlayers.length;

    const scoreWidth = 80.0;
    const spacer = 20.0;
    const stealWidth = 60.0;
    final nameWidth = width - (stealWidth + scoreWidth + spacer);

    return FutureBuilder(
        future: DatabaseManager.instance.getCurrentTeamResults(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return SizedBox(
              width: 80,
              height: 80,
              child: Center(
                  child: CircularProgressIndicator(
                      color: ThemeManager.instance.mainColor)),
            );
          }

          final team = snapshot.data as TeamResult;

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
                          final highlightColor = _highlightBestScoreColor(
                              player: player, players: players, team: team);
                          final suffixIcon = _playerSuffixWidget(
                              player: player,
                              players: players,
                              teamResult: team);

                          return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (index == 0)
                                  _buildTitleTile(
                                      'Meilleur\u00b7e cheminot\u00b7e'),
                                _buildNamedTile(
                                  player.name,
                                  highlightColor: highlightColor,
                                  suffixIcon: suffixIcon,
                                  width: nameWidth,
                                ),
                                if (players.length > nbHighestScore &&
                                    index + 1 == nbHighestScore)
                                  Column(
                                    children: [
                                      const SizedBox(height: 12.0),
                                      _buildTitleTile(
                                          'Autres cheminot\u00b7e\u00b7s')
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
                            final highlightColor = _highlightBestScoreColor(
                                player: player, players: players, team: team);

                            return Column(children: [
                              if (index == 0) _buildTitleTile('Vols'),
                              _buildScoreTile(
                                  score: player.gameStealCount,
                                  highlightColor: highlightColor),
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
                            final highlightColor = _highlightBestScoreColor(
                                player: player, players: players, team: team);

                            return Column(children: [
                              if (index == 0) _buildTitleTile('Score'),
                              _buildScoreTile(
                                  score: player.score,
                                  highlightColor: highlightColor),
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
        });
  }

  Widget _buildTeamLeaderboardScore({required double width}) {
    final gm = GameManager.instance;
    final tm = ThemeManager.instance;
    final dm = DatabaseManager.instance;

    const scoreWidth = 82.0;
    final nameWidth = width - scoreWidth;

    return FutureBuilder(
        future: dm.getBestTrainStationsReached(
            top: 50,
            stationReached: gm.hasPlayedAtLeastOnce ? gm.roundCount : null),
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
                            highlightColor: _highlightBestTeamColor(team: team),
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
                              highlightColor:
                                  _highlightBestTeamColor(team: team),
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

  Widget _builBestPlayersLeaderboardScore({required double width}) {
    final gm = GameManager.instance;
    final tm = ThemeManager.instance;

    final bestPlayers = gm.players.bestPlayers;

    const scoreWidth = 80.0;
    final nameWidth = width - scoreWidth;

    return FutureBuilder(
        future: DatabaseManager.instance.getBestPlayers(
            top: 50, mvpPlayers: gm.hasPlayedAtLeastOnce ? bestPlayers : null),
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
                            highlightColor:
                                _highlightBestPlayerColor(player: player),
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
                              highlightColor:
                                  _highlightBestPlayerColor(player: player),
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
          if ((gm.successLevel == SuccessLevel.failed &&
                  gm.isAllowedToSendResults) ||
              !gm.hasPlayedAtLeastOnce)
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
                        _builBestPlayersLeaderboardScore(width: 450),
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
    final tm = ThemeManager.instance;

    return Text(title,
        style: tm.clientMainTextStyle.copyWith(
            fontSize: 20.0, fontWeight: FontWeight.bold, color: Colors.white));
  }

  TextStyle _playerStyle(Color? hightlightColor) {
    return TextStyle(
      fontSize: 20.0,
      fontWeight: hightlightColor != null ? FontWeight.bold : FontWeight.normal,
      color: hightlightColor ?? Colors.white,
    );
  }

  Widget _buildNamedTile(
    String name, {
    Color? highlightColor,
    Widget? suffixIcon,
    String? prefixText,
    required double width,
  }) {
    final style = _playerStyle(highlightColor);

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

  Widget _buildScoreTile({required int score, required Color? highlightColor}) {
    final style = _playerStyle(highlightColor);

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
          GrowingWidget(
            growingFactor: 0.9,
            duration: const Duration(milliseconds: 1000),
            child: Icon(Icons.star, color: Colors.amber, size: 70.0, shadows: [
              Shadow(color: Colors.grey.shade500, blurRadius: 15.0)
            ]),
          ),
          Column(
            children: [
              Text(
                'Entrée en gare à la Station N\u00b0${gm.roundCount}!',
                style: tm.clientMainTextStyle.copyWith(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: tm.textColor),
              ),
              const SizedBox(height: 16.0),
              Text(
                'Félicitation! Nous avons traversé '
                '${gm.successLevel.toInt()} station${gm.successLevel.toInt() > 1 ? 's' : ''}!',
                style: tm.clientMainTextStyle.copyWith(
                    fontSize: 26,
                    fontWeight: FontWeight.normal,
                    color: tm.textColor),
              ),
              if (gm.roundSuccesses.contains(RoundSuccess.noSteal))
                Text(
                    'Le contrôleur est impressionné par votre honnêteté.\n'
                    'Il vous accorde un pardon supplémentaire!',
                    textAlign: TextAlign.center,
                    style: tm.clientMainTextStyle.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.normal,
                        color: tm.textColor)),
              const SizedBox(height: 16.0),
            ],
          ),
          GrowingWidget(
            growingFactor: 0.9,
            duration: const Duration(milliseconds: 1000),
            child: Icon(Icons.star, color: Colors.amber, size: 70.0, shadows: [
              Shadow(color: Colors.grey.shade500, blurRadius: 15.0)
            ]),
          ),
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
          GrowingWidget(
            growingFactor: 0.9,
            duration: const Duration(milliseconds: 1000),
            child: Icon(Icons.star, color: Colors.amber, size: 70.0, shadows: [
              Shadow(color: Colors.grey.shade500, blurRadius: 15.0)
            ]),
          ),
          Text(
            'Le tableau des cheminot\u00b7e\u00b7s',
            style: tm.clientMainTextStyle.copyWith(
                fontSize: 32, fontWeight: FontWeight.bold, color: tm.textColor),
          ),
          GrowingWidget(
            growingFactor: 0.9,
            duration: const Duration(milliseconds: 1000),
            child: Icon(Icons.star, color: Colors.amber, size: 70.0, shadows: [
              Shadow(color: Colors.grey.shade500, blurRadius: 15.0)
            ]),
          ),
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
        Image.asset('assets/images/train.png',
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
          GrowingWidget(
              growingFactor: 0.9,
              duration: const Duration(milliseconds: 1000),
              child: Icon(Icons.star, color: Colors.grey, size: 70.0, shadows: [
                Shadow(color: Colors.grey.shade800, blurRadius: 15.0)
              ])),
          Column(
            children: [
              Text(
                'Immobilisé entre deux stations',
                style: tm.clientMainTextStyle.copyWith(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: tm.textColor),
              ),
              const SizedBox(height: 16.0),
              Text(
                'Le Petit Train du Nord n\'a pu se rendre à destination',
                style: tm.clientMainTextStyle.copyWith(
                    fontSize: 26,
                    fontWeight: FontWeight.normal,
                    color: tm.textColor),
              ),
              const SizedBox(height: 8.0),
              Text(
                  'La dernière station atteinte était la Station N\u00b0${gm.roundCount}',
                  style: tm.clientMainTextStyle.copyWith(
                      fontSize: 26,
                      fontWeight: FontWeight.normal,
                      color: tm.textColor)),
              const SizedBox(height: 16.0),
            ],
          ),
          GrowingWidget(
            growingFactor: 0.9,
            duration: const Duration(milliseconds: 1000),
            child: Icon(Icons.star, color: Colors.grey, size: 70.0, shadows: [
              Shadow(color: Colors.grey.shade800, blurRadius: 15.0)
            ]),
          ),
        ],
      ),
    );
  }
}

class _AttemptingTheBigHeist extends StatelessWidget {
  const _AttemptingTheBigHeist();

  @override
  Widget build(BuildContext context) {
    final tm = ThemeManager.instance;

    return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 99, 65, 14),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 10),
          Text(
            'Un\u00b7e cheminot\u00b7e a orchestré un Grand Coup! Braquez le train\n'
            'en chemin pour un quitte ou double et parcourir six stations d\'un coup!',
            style: tm.clientMainTextStyle.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color.fromARGB(255, 255, 210, 133)),
          ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }
}
