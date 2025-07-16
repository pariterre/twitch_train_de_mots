import 'package:common/blueberry_war/models/letter_agent.dart';
import 'package:common/generic/models/generic_listener.dart';
import 'package:common/generic/models/serializable_game_state.dart';
import 'package:common/generic/widgets/letter_displayer_common.dart';
import 'package:flutter/material.dart';

class LetterContainer extends StatefulWidget {
  const LetterContainer(
      {super.key, required this.letter, required this.clockTicker});

  final LetterAgent letter;
  final GenericListener clockTicker;

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

  void _clockTicked() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return widget.letter.isDestroyed
        ? Container()
        : Positioned(
            left: widget.letter.position.x - widget.letter.radius.x,
            top: widget.letter.position.y - widget.letter.radius.y,
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
