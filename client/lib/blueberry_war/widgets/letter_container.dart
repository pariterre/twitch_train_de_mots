import 'package:common/generic/models/serializable_game_state.dart';
import 'package:common/generic/widgets/letter_displayer_common.dart';
import 'package:flutter/material.dart';
import 'package:train_de_mots/blueberry_war/models/letter_agent.dart';
import 'package:train_de_mots/generic/managers/managers.dart';

class LetterContainer extends StatefulWidget {
  const LetterContainer({super.key, required this.letter});

  final LetterAgent letter;

  @override
  State<LetterContainer> createState() => _LetterContainerState();
}

class _LetterContainerState extends State<LetterContainer> {
  @override
  void initState() {
    super.initState();

    final gm = Managers.instance.miniGames.blueberryWar;
    gm.onClockTicked.listen(_clockTicked);
  }

  @override
  void dispose() {
    final gm = Managers.instance.miniGames.blueberryWar;
    gm.onClockTicked.cancel(_clockTicked);

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
