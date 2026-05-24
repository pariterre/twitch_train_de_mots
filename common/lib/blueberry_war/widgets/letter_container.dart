import 'package:common/blueberry_war/models/letter_agent.dart';
import 'package:common/generic/models/generic_listener.dart';
import 'package:common/generic/models/serializable_game_state.dart';
import 'package:common/generic/widgets/letter_displayer_common.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math.dart' as vector_math;

class LetterContainer extends StatefulWidget {
  const LetterContainer(
      {super.key, required this.letter, required this.clockTicker});

  final LetterAgent letter;
  final GenericListener<Function(Duration deltaTime)> clockTicker;

  @override
  State<LetterContainer> createState() => _LetterContainerState();
}

class _LetterContainerState extends State<LetterContainer> {
  late vector_math.Vector2 _previousPosition = widget.letter.position;

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
    if (_previousPosition != widget.letter.position) {
      setState(() {});
    }
  }

  vector_math.Vector2 _getPosition() {
    _previousPosition = widget.letter.position;
    return _previousPosition;
  }

  @override
  Widget build(BuildContext context) {
    final position = _getPosition();

    return widget.letter.isDestroyed
        ? Container()
        : Positioned(
            left: position.x - widget.letter.radius.x,
            top: position.y - widget.letter.radius.y,
            child: Center(
              child: LetterWidget(
                letter: widget.letter.letter,
                width: widget.letter.radius.x * 2,
                height: widget.letter.radius.y * 2,
                letterSize: widget.letter.radius.y,
                numberSize: 0,
                uselessStatus: widget.letter.isBoss
                    ? LetterStatus.revealed
                    : LetterStatus.normal,
                hiddenStatus: widget.letter.isWeak
                    ? LetterStatus.normal
                    : LetterStatus.hidden,
              ),
            ),
          );
  }
}
