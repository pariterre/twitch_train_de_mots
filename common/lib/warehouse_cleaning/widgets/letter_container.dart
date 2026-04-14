import 'package:common/warehouse_cleaning/models/letter_agent.dart';
import 'package:common/generic/models/generic_listener.dart';
import 'package:common/warehouse_cleaning/models/warehouse_cleaning_grid.dart';
import 'package:flutter/material.dart';

class LetterContainer extends StatefulWidget {
  const LetterContainer({
    super.key,
    required this.letter,
    required this.tileSize,
    required this.clockTicker,
    required this.getTileAt,
  });

  final LetterAgent letter;
  final double tileSize;
  final GenericListener<Function(Duration deltaTime)> clockTicker;
  final Tile? Function({int? row, int? col, int? index}) getTileAt;

  @override
  State<LetterContainer> createState() => _LetterContainerState();
}

class _LetterContainerState extends State<LetterContainer> {
  @override
  void initState() {
    super.initState();

    widget.clockTicker.listen(_clockTicked);
  }

  @override
  void dispose() {
    widget.clockTicker.cancel(_clockTicked);

    super.dispose();
  }

  void _clockTicked(Duration deltaTime) {
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final tile = widget.getTileAt(index: widget.letter.tileIndex);

    return widget.letter.isCollected ||
            tile == null ||
            tile.isConcealed ||
            tile.isMysteryLetter
        ? SizedBox.shrink()
        : Positioned(
            left: widget.letter.position.x,
            top: widget.letter.position.y,
            child: Container(
              width: widget.tileSize,
              height: widget.tileSize,
              color: Colors.white.withAlpha(100),
              child: Transform.translate(
                // Center the letter vertically
                offset: Offset(0, -widget.tileSize * 0.15),
                child: Text(widget.letter.value,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: widget.tileSize * 0.9,
                        color: Colors.black,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          );
  }
}
