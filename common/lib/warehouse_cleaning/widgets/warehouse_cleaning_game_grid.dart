import 'package:common/generic/models/generic_listener.dart';
import 'package:common/warehouse_cleaning/models/avatar_agent.dart';
import 'package:common/warehouse_cleaning/models/box_agent.dart';
import 'package:common/warehouse_cleaning/models/letter_agent.dart';
import 'package:common/warehouse_cleaning/models/warehouse_cleaning_game_manager_helpers.dart';
import 'package:common/warehouse_cleaning/models/warehouse_cleaning_grid.dart';
import 'package:common/warehouse_cleaning/widgets/avatar_container.dart';
import 'package:common/warehouse_cleaning/widgets/box_container.dart';
import 'package:common/warehouse_cleaning/widgets/letter_container.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math.dart' as vector_math;

class WarehouseCleaningGameGrid extends StatelessWidget {
  const WarehouseCleaningGameGrid({
    super.key,
    required this.rowCount,
    required this.columnCount,
    required this.getTileAt,
    required this.avatars,
    required this.boxes,
    required this.letters,
    required this.isGameOver,
    required this.clockTicker,
    required this.onAvatarSlingShoot,
  });

  final int rowCount;
  final int columnCount;
  final Tile Function(int row, int col) getTileAt;
  final List<AvatarAgent> avatars;
  final List<BoxAgent> boxes;
  final List<LetterAgent> letters;
  final bool isGameOver;
  final GenericListener<Function(Duration deltaTime)> clockTicker;
  final Function(AvatarAgent avatar, vector_math.Vector2 newVelocity)
      onAvatarSlingShoot;

  @override
  Widget build(BuildContext context) {
    final tileSize = WarehouseCleaningConfig.tileSize;

    return FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(
        width: columnCount * tileSize,
        height: rowCount * tileSize,
        child: Stack(
          children: [
            _WarehouseCleaningBackgroundLayer(
                rowCount: rowCount,
                columnCount: columnCount,
                tileSize: tileSize),
            _WarehouseCleaningAgentsOverlay(
              avatars: avatars,
              boxes: boxes,
              letters: letters,
              isGameOver: isGameOver,
              clockTicker: clockTicker,
              onAvatarSlingShoot: onAvatarSlingShoot,
              tileSize: tileSize,
            ),
            _WarehouseCleaningFogOfWarOverlay(
              rowCount: rowCount,
              columnCount: columnCount,
              getTileAt: getTileAt,
              tileSize: tileSize,
            ),
          ],
        ),
      ),
    );
  }
}

class _WarehouseCleaningBackgroundLayer extends StatelessWidget {
  const _WarehouseCleaningBackgroundLayer({
    required this.rowCount,
    required this.columnCount,
    required this.tileSize,
  });

  final int rowCount;
  final int columnCount;
  final double tileSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(columnCount, (col) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(rowCount, (row) {
            return Container(
                width: tileSize,
                height: tileSize,
                decoration: BoxDecoration(
                  border: Border.all(width: tileSize * 0.02),
                ),
                child: Image.asset(
                    fit: BoxFit.fill,
                    'packages/common/assets/images/warehouse_cleaning/floor.png'));
          }, growable: false),
        );
      }, growable: false),
    );
  }
}

class _WarehouseCleaningAgentsOverlay extends StatelessWidget {
  const _WarehouseCleaningAgentsOverlay({
    required this.avatars,
    required this.boxes,
    required this.letters,
    required this.tileSize,
    required this.isGameOver,
    required this.clockTicker,
    required this.onAvatarSlingShoot,
  });

  final List<AvatarAgent> avatars;
  final List<BoxAgent> boxes;
  final List<LetterAgent> letters;
  final double tileSize;
  final bool isGameOver;
  final GenericListener<Function(Duration deltaTime)> clockTicker;
  final Function(AvatarAgent avatar, vector_math.Vector2 newVelocity)
      onAvatarSlingShoot;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topLeft,
      children: [
        SizedBox(
          width: double.infinity,
          height: double.infinity,
        ),
        ...boxes.map((e) => BoxContainer(
              box: e,
              tileSize: tileSize,
              clockTicker: clockTicker,
            )),
        ...letters.map((e) => LetterContainer(
              letter: e,
              tileSize: tileSize,
              clockTicker: clockTicker,
            )),
        ...avatars.map((e) => AvatarContainer(
            avatar: e,
            tileSize: tileSize,
            isGameOver: isGameOver,
            clockTicker: clockTicker,
            onAvatarSlingShoot: onAvatarSlingShoot)),
      ],
    );
  }
}

class _WarehouseCleaningFogOfWarOverlay extends StatelessWidget {
  const _WarehouseCleaningFogOfWarOverlay({
    required this.rowCount,
    required this.columnCount,
    required this.getTileAt,
    required this.tileSize,
  });

  final int rowCount;
  final int columnCount;
  final Tile? Function(int row, int col) getTileAt;
  final double tileSize;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(columnCount, (col) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(rowCount, (row) {
              final tile = getTileAt(row, col);
              if (tile == null) return SizedBox.shrink();

              return Container(
                width: tileSize,
                height: tileSize,
                color: tile.isConcealed ? Colors.grey[800] : Colors.transparent,
              );
            }, growable: false),
          );
        }, growable: false),
      ),
    );
  }
}
