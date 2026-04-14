import 'package:common/warehouse_cleaning/models/box_agent.dart';
import 'package:common/warehouse_cleaning/models/warehouse_cleaning_grid.dart';
import 'package:flutter/material.dart';

class BoxContainer extends StatelessWidget {
  const BoxContainer({
    super.key,
    required this.box,
    required this.child,
    required this.getTileAt,
  });

  final BoxAgent box;
  final Widget child;
  final Tile? Function({int? row, int? col, int? index}) getTileAt;

  @override
  Widget build(BuildContext context) {
    final tile = getTileAt(index: box.tileIndex);

    return tile?.isConcealed ?? true
        ? SizedBox.shrink()
        : Positioned(
            left: box.position.x,
            top: box.position.y,
            child: child,
          );
  }
}
