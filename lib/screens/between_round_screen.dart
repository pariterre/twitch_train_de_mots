import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:train_de_mots/models/custom_scheme.dart';
import 'package:train_de_mots/models/game_manager.dart';

class Tata {
  final String name;
  final int score;
  Tata(this.name, this.score);
}

class PlayfulScoreOverlay extends ConsumerWidget {
  const PlayfulScoreOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = ref.watch(schemeProvider);

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
              const SizedBox(height: 16.0),
              const _VictoryHeader(),
              const _LeaderBoard(),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close the overlay
                },
                style: scheme.elevatedButtonStyle,
                child: Text(
                  'Aller à la prochaine station!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: scheme.buttonTextSize,
                    color: scheme.mainColor,
                  ),
                ),
              ),
              const SizedBox(height: 24.0),
            ],
          ),
        ],
      ),
    );
  }
}

class _LeaderBoard extends StatelessWidget {
  const _LeaderBoard();

  @override
  Widget build(BuildContext context) {
//final players = gm.players.sort((a, b) => b.score - a.score);
    final players = [
      Tata('coucou1', 1),
      Tata('coucou2', 2),
      Tata('coucou3', 3),
      Tata('coucou4', 4),
      Tata('coucou5', 5),
      Tata('coucou6', 6),
      Tata('coucou7', 7),
      Tata('coucou8', 8),
      Tata('coucou9', 9),
      Tata('coucou10', 10),
      Tata('coucou11', 11),
    ];

    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          children: players
              .map((e) => ListTile(
                    leading: Icon(Icons.person, color: Colors.white),
                    title: Text(
                      '${e.name}: ${e.score}',
                      style: TextStyle(fontSize: 20.0, color: Colors.white),
                    ),
                  ))
              .toList(),
        ),
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
