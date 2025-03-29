import 'dart:math';

import 'package:flutter/material.dart';
import 'package:train_de_mots/generic/managers/managers.dart';
import 'package:train_de_mots/treasure_hunt/models/tile.dart';

extension TileColor on TileValue {
  Color get color {
    switch (this) {
      case TileValue.zero:
        return const Color.fromARGB(0, 0, 0, 0);
      case TileValue.one:
        return const Color.fromARGB(255, 89, 171, 191);
      case TileValue.two:
        return const Color.fromARGB(255, 30, 139, 249);
      case TileValue.three:
        return const Color.fromARGB(255, 171, 161, 235);
      case TileValue.four:
        return const Color.fromARGB(255, 139, 105, 2);
      case TileValue.five:
        return Colors.purple;
      case TileValue.six:
        return Colors.brown;
      case TileValue.seven:
        return const Color.fromARGB(255, 212, 85, 0);
      case TileValue.eight:
        return Colors.deepPurple;
      case TileValue.treasure:
        return const Color.fromARGB(255, 10, 41, 66);
      case TileValue.letter:
        return const Color.fromARGB(255, 255, 108, 108);
    }
  }
}

class SweeperTile extends StatelessWidget {
  const SweeperTile({
    super.key,
    required this.tileIndex,
    required this.tileSize,
    required this.textSize,
  });

  final int tileIndex;
  final double tileSize;
  final double textSize;

  @override
  Widget build(BuildContext context) {
    final gm = Managers.instance.miniGames.treasureHunt;
    final tile = gm.getTile(tileIndex);

    // index is the number of treasure around the current tile
    final value = tile.value;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(width: tileSize * 0.03),
      ),
      child: GestureDetector(
        onTap: () => gm.revealTile(tileIndex: tileIndex),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: const BoxDecoration(
                  // border: Border.all(width: tileSize * 0.02),
                  ),
              child: Image.asset(tile.isConcealed
                  ? 'assets/images/treasure_hunt/grass.png'
                  : 'assets/images/treasure_hunt/open_grass.png'),
            ),
            tile.isRevealed && tile.hasReward
                ? (tile.hasLetter
                    ? Text(gm.getLetter(tileIndex)!,
                        style: TextStyle(
                            fontSize: textSize * 0.65,
                            color: tile.value.color,
                            fontWeight: FontWeight.bold))
                    : const _TreasureTile())
                : Text(
                    tile.isRevealed ? value.toString() : '',
                    style: TextStyle(
                        fontSize: textSize * 0.65,
                        color: tile.value.color,
                        fontWeight: FontWeight.bold),
                  )
          ],
        ),
      ),
    );
  }
}

class _TreasureTile extends StatefulWidget {
  const _TreasureTile();

  @override
  State<_TreasureTile> createState() => _TreasureTileState();
}

class _TreasureTileState extends State<_TreasureTile> {
  double _easeOutExponential(double x) {
    return 1 - (x == 1 ? 1.0 : pow(2, -50 * x).toDouble());
  }

  double _pulsing(double x) {
    return 0.05 * (sin(20 * x) + pi) + (1 - 0.3);
  }

  double _animation(double t) {
    return _easeOutExponential(t) * _pulsing(t);
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
        duration: const Duration(seconds: 4),
        tween: Tween<double>(begin: 1, end: 0.02),
        builder: (context, value, child) {
          return SizedBox(
              height: _animation(value) * 30,
              width: _animation(value) * 30,
              child:
                  Image.asset('assets/images/treasure_hunt/blueberries.png'));
        });
  }
}
