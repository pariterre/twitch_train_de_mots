import 'package:common/generic/models/generic_listener.dart';
import 'package:common/warehouse_cleaning/models/avatar_agent.dart';
import 'package:common/warehouse_cleaning/models/box_agent.dart';
import 'package:common/warehouse_cleaning/models/letter_agent.dart';
import 'package:common/warehouse_cleaning/models/warehouse_cleaning_config.dart';
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
    required this.isRoundInProgress,
    required this.clockTicker,
    required this.onAvatarSlingShoot,
  });

  final int rowCount;
  final int columnCount;
  final Tile? Function({int? row, int? col, int? index}) getTileAt;
  final List<AvatarAgent> avatars;
  final List<BoxAgent> boxes;
  final List<LetterAgent> letters;
  final bool isRoundInProgress;
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
                getTileAt: getTileAt,
                tileSize: tileSize),
            _WarehouseCleaningAgentsOverlay(
              avatars: avatars,
              boxes: boxes,
              letters: letters,
              isRoundInProgress: isRoundInProgress,
              clockTicker: clockTicker,
              onAvatarSlingShoot: onAvatarSlingShoot,
              tileSize: tileSize,
              getTileAt: getTileAt,
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
    required this.getTileAt,
    required this.tileSize,
  });

  final int rowCount;
  final int columnCount;
  final Tile? Function({int? row, int? col, int? index}) getTileAt;
  final double tileSize;

  @override
  Widget build(BuildContext context) {
    final floorImage = Container(
        width: tileSize,
        height: tileSize,
        decoration: BoxDecoration(
          border: Border.all(width: tileSize * 0.02),
        ),
        child: Image.asset(
            fit: BoxFit.fill,
            'packages/common/assets/images/warehouse_cleaning/floor.png'));

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
          columnCount,
          (col) => Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(rowCount, (row) {
                  final tile = getTileAt(row: row, col: col);
                  if (tile == null || tile.isBox || tile.isConcealed) {
                    return SizedBox(width: tileSize, height: tileSize);
                  }
                  return floorImage;
                }, growable: false),
              ),
          growable: false),
    );
  }
}

class _WarehouseCleaningAgentsOverlay extends StatelessWidget {
  const _WarehouseCleaningAgentsOverlay({
    required this.avatars,
    required this.boxes,
    required this.letters,
    required this.tileSize,
    required this.isRoundInProgress,
    required this.clockTicker,
    required this.onAvatarSlingShoot,
    required this.getTileAt,
  });

  final List<AvatarAgent> avatars;
  final List<BoxAgent> boxes;
  final List<LetterAgent> letters;
  final double tileSize;
  final bool isRoundInProgress;
  final GenericListener<Function(Duration deltaTime)> clockTicker;
  final Function(AvatarAgent avatar, vector_math.Vector2 newVelocity)
      onAvatarSlingShoot;
  final Tile? Function({int? row, int? col, int? index}) getTileAt;

  @override
  Widget build(BuildContext context) {
    final boxImage = Container(
      width: tileSize,
      height: tileSize,
      child: Image.asset(
          fit: BoxFit.fill,
          'packages/common/assets/images/warehouse_cleaning/box.png'),
    );

    return Stack(
      alignment: Alignment.topLeft,
      children: [
        SizedBox(
          width: double.infinity,
          height: double.infinity,
        ),
        ...boxes.map((e) => BoxContainer(
              box: e,
              child: boxImage,
              getTileAt: getTileAt,
            )),
        ...letters.map((e) => LetterContainer(
              letter: e,
              tileSize: tileSize,
              clockTicker: clockTicker,
              getTileAt: getTileAt,
            )),
        ...avatars.map((e) => AvatarContainer(
            avatar: e,
            tileSize: tileSize,
            isRoundInProgress: isRoundInProgress,
            clockTicker: clockTicker,
            onAvatarSlingShoot: onAvatarSlingShoot)),
      ],
    );
  }
}
