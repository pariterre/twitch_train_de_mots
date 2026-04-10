import 'package:common/generic/models/generic_listener.dart';
import 'package:common/warehouse_cleaning/models/box_agent.dart';
import 'package:flutter/material.dart';

class BoxContainer extends StatefulWidget {
  const BoxContainer({
    super.key,
    required this.box,
    required this.tileSize,
    required this.clockTicker,
  });

  final BoxAgent box;
  final double tileSize;
  final GenericListener clockTicker;

  @override
  State<BoxContainer> createState() => _BoxContainerState();
}

class _BoxContainerState extends State<BoxContainer> {
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

  void _clockTicked() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.box.position.x + widget.tileSize * 0.05,
      top: widget.box.position.y + widget.tileSize * 0.05,
      child: Container(
        width: widget.tileSize * 0.9,
        height: widget.tileSize * 0.9,
        child: Image.asset(
            fit: BoxFit.fill,
            'packages/common/assets/images/warehouse_cleaning/box.png'),
      ),
    );
  }
}
