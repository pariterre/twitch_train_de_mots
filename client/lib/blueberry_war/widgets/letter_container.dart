import 'package:flutter/material.dart';
import 'package:train_de_mots/blueberry_war/models/letter_agent.dart';
import 'package:train_de_mots/blueberry_war/to_remove/any_dumb_stuff.dart';

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
            child: Container(
              width: widget.letter.radius.x * 2,
              height: widget.letter.radius.y * 2,
              decoration: BoxDecoration(
                color: widget.letter.isBoss ? Colors.red : Colors.blue,
                border: Border.all(color: Colors.black, width: 2.0),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Center(
                child: Text(
                  widget.letter.isWeak ? widget.letter.letter : '',
                  style: TextStyle(fontSize: 30, color: Colors.black),
                ),
              ),
            ),
          );
  }
}
