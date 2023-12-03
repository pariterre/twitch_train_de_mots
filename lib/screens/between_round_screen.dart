import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:train_de_mots/models/custom_scheme.dart';
import 'package:train_de_mots/models/game_manager.dart';
import 'package:train_de_mots/models/player.dart';

class PlayfulScoreOverlay extends ConsumerWidget {
  const PlayfulScoreOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gm = ref.read(gameManagerProvider);

    return SizedBox(
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
              if (gm.problem!.isSuccess)
                const _VictoryHeader()
              else
                const _DefeatHeader(),
              const SizedBox(height: 24.0),
              const _LeaderBoard(),
              const SizedBox(height: 16.0),
              const _ContinueButton(),
              const SizedBox(height: 24.0),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContinueButton extends ConsumerStatefulWidget {
  const _ContinueButton();

  @override
  ConsumerState<_ContinueButton> createState() => _ContinueButtonState();
}

class _ContinueButtonState extends ConsumerState<_ContinueButton> {
  @override
  void initState() {
    super.initState();

    ref
        .read(gameManagerProvider)
        .onNextProblemReady
        .addListener(_onNextProblemReady);
  }

  @override
  void dispose() {
    // ref
    //     .read(gameManagerProvider)
    //     .onNextProblemReady
    //     .removeListener(_onNextProblemReady);

    super.dispose();
  }

  void _onNextProblemReady() {
    if (!mounted) return;

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final gm = ref.read(gameManagerProvider);
    final scheme = ref.watch(schemeProvider);

    return gm.gameStatus == GameStatus.roundPreparing
        ? Container()
        : Card(
            elevation: 10,
            child: ElevatedButton(
              onPressed: () =>
                  ref.read(gameManagerProvider).requestStartNewRound(),
              style: scheme.elevatedButtonStyle,
              child: Text(
                  gm.problem!.isSuccess
                      ? 'Lancer la prochaine manche'
                      : 'Relancer le train',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: scheme.buttonTextSize)),
            ),
          );
  }
}

class _LeaderBoard extends ConsumerWidget {
  const _LeaderBoard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gm = ref.read(gameManagerProvider);
    final players = gm.players.sort((a, b) => b.score - a.score);

    final highestStealCount = players.fold<int>(
        0, (previousValue, player) => max(previousValue, player.stealCount));
    final biggestStealers = players.where((player) {
      return highestStealCount != 0 && player.stealCount == highestStealCount;
    }).toList();

    return Expanded(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 150),
          child: SizedBox(
            width: double.infinity,
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

                      if (index == 0) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTitleTile('Meilleur\u2022e cheminot\u2022e'),
                            _buildPlayerNameTile(player, isBiggestStealer),
                            const SizedBox(height: 12.0),
                            if (players.length > 1)
                              _buildTitleTile('Autres cheminot\u2022e\u2022s')
                          ],
                        );
                      }

                      return _buildPlayerNameTile(player, isBiggestStealer);
                    },
                  ).toList(),
                ),
                Column(
                  children: players.asMap().keys.map(
                    (index) {
                      final player = players[index];
                      final isBiggestStealer = biggestStealers.contains(player);

                      if (index == 0) {
                        return Column(
                          children: [
                            _buildTitleTile('Score'),
                            _buildPlayerScoreTile(player, isBiggestStealer),
                            const SizedBox(height: 12.0),
                            if (players.length > 1) _buildTitleTile('')
                          ],
                        );
                      }

                      return _buildPlayerScoreTile(player, isBiggestStealer);
                    },
                  ).toList(),
                ),
              ],
            ),
          ),
        ),
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

  Widget _buildPlayerNameTile(Player player, bool isBiggestStealer) {
    final style = _playerStyle(isBiggestStealer);

    return Padding(
      padding: const EdgeInsets.only(left: 12.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Icon(Icons.local_police,
                  color: isBiggestStealer ? Colors.red : Colors.transparent),
            ),
            Text(player.name, style: style),
            if (isBiggestStealer) Text(' (Plus grand voleur!)', style: style),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerScoreTile(Player player, bool isBiggestStealer) {
    final style = _playerStyle(isBiggestStealer);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        player.score.toString(),
        style: style,
      ),
    );
  }
}

class _VictoryHeader extends ConsumerWidget {
  const _VictoryHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gm = ref.read(gameManagerProvider);
    final scheme = ref.watch(schemeProvider);

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
                    fontSize: scheme.titleSize,
                    fontWeight: FontWeight.bold,
                    color: scheme.textColor),
              ),
              const SizedBox(height: 16.0),
              Text(
                'Félicitation nous sommes arrivé\u2022e\u2022s à une nouvelle station!',
                style: TextStyle(
                    fontSize: scheme.leaderTitleSize,
                    fontWeight: FontWeight.normal,
                    color: scheme.textColor),
              ),
              const SizedBox(height: 8.0),
              Text(
                  'La prochaine station sera la Station N\u00b0${gm.roundCount + 1}',
                  style: TextStyle(
                      fontSize: scheme.leaderTitleSize,
                      fontWeight: FontWeight.normal,
                      color: scheme.textColor)),
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

class _Background extends ConsumerWidget {
  const _Background();

  final int rainbowOpacity = 70;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = ref.watch(schemeProvider);

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
              color: scheme.mainColor,
              borderRadius: BorderRadius.circular(20.0)),
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

class _DefeatHeader extends ConsumerWidget {
  const _DefeatHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gm = ref.read(gameManagerProvider);
    final scheme = ref.watch(schemeProvider);

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
                    fontSize: scheme.titleSize,
                    fontWeight: FontWeight.bold,
                    color: scheme.textColor),
              ),
              const SizedBox(height: 16.0),
              Text(
                'Le Petit train du Nord n\'a pu se rendre à destination',
                style: TextStyle(
                    fontSize: scheme.leaderTitleSize,
                    fontWeight: FontWeight.normal,
                    color: scheme.textColor),
              ),
              const SizedBox(height: 8.0),
              Text(
                  'La dernière station atteinte était la Station N\u00b0${gm.roundCount}',
                  style: TextStyle(
                      fontSize: scheme.leaderTitleSize,
                      fontWeight: FontWeight.normal,
                      color: scheme.textColor)),
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
