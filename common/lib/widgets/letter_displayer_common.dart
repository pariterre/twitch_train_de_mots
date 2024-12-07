import 'package:common/managers/theme_manager.dart';
import 'package:common/models/simplified_game_state.dart';
import 'package:common/models/valuable_letter.dart';
import 'package:flutter/material.dart';

class LetterDisplayerController {
  late double _sizeFactor;

  LetterDisplayerController({double sizeFactor = 1.0}) {
    sizeFactor = sizeFactor;
  }

  late double _letterWidth;
  late double _letterHeight;
  late double _letterPadding;

  late double _letterSize;
  late double _numberSize;

  set sizeFactor(double value) {
    _sizeFactor = value;

    _letterWidth = 80 * _sizeFactor;
    _letterHeight = 90 * _sizeFactor;
    _letterPadding = 4 * _sizeFactor;

    _letterSize = 46 * _sizeFactor;
    _numberSize = 26 * _sizeFactor;

    if (_state != null) _state!.refresh();
  }

  _LetterDisplayerCommonState? _state;
}

class LetterDisplayerCommon extends StatefulWidget {
  const LetterDisplayerCommon({
    super.key,
    this.controller,
    required this.letterProblem,
    this.onLetterBuilder,
  });

  final LetterDisplayerController? controller;
  final SimplifiedLetterProblem letterProblem;
  final Widget Function(int)? onLetterBuilder;

  @override
  State<LetterDisplayerCommon> createState() => _LetterDisplayerCommonState();
}

class _LetterDisplayerCommonState extends State<LetterDisplayerCommon> {
  late final LetterDisplayerController _controller;

  @override
  void initState() {
    super.initState();

    _controller = widget.controller ?? LetterDisplayerController();
    _controller._state = this;
  }

  @override
  void dispose() {
    _controller._state = null;

    super.dispose();
  }

  void refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final lp = widget.letterProblem;

    final displayerWidth = _controller._letterWidth * lp.letters.length +
        2 * _controller._letterPadding * (lp.letters.length);

    return SizedBox(
      width: displayerWidth,
      height: _controller._letterHeight * 1.2,
      child: Stack(alignment: Alignment.center, children: [
        for (var index in lp.letters.asMap().keys)
          AnimatedPositioned(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              left:
                  (_controller._letterWidth + 2 * _controller._letterPadding) *
                      lp.scrambleIndices[index],
              child: _Letter(
                letter: lp.letters[index],
                width: _controller._letterWidth,
                height: _controller._letterHeight,
                letterSize: _controller._letterSize,
                numberSize: _controller._numberSize,
                uselessIsRevealed: index == lp.revealedUselessLetterIndex,
                isAHiddenLetter: index == lp.hiddenLetterIndex,
                isHidden:
                    index == lp.hiddenLetterIndex && lp.shouldHideHiddenLetter,
              )),
        for (var index in lp.letters.asMap().keys)
          AnimatedPositioned(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              left:
                  (_controller._letterWidth + 2 * _controller._letterPadding) *
                      lp.scrambleIndices[index],
              child: SizedBox(
                width: _controller._letterWidth,
                height: _controller._letterHeight,
                child: widget.onLetterBuilder != null
                    ? widget.onLetterBuilder!(index)
                    : null,
              )),
      ]),
    );
  }
}

class _Letter extends StatefulWidget {
  const _Letter({
    required this.letter,
    required this.width,
    required this.height,
    required this.letterSize,
    required this.numberSize,
    required this.uselessIsRevealed,
    required this.isAHiddenLetter,
    required this.isHidden,
  });

  final String letter;

  final double width;
  final double height;
  final double letterSize;
  final double numberSize;

  final bool uselessIsRevealed;
  final bool isAHiddenLetter;
  final bool isHidden;

  @override
  State<_Letter> createState() => _LetterState();
}

class _LetterState extends State<_Letter> {
  @override
  void initState() {
    super.initState();

    final tm = ThemeManager.instance;
    tm.onChanged.addListener(_refresh);
  }

  @override
  void dispose() {
    super.dispose();

    final tm = ThemeManager.instance;
    tm.onChanged.removeListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final tm = ThemeManager.instance;
    final valuableLetter = ValuableLetter(widget.letter);

    // Create a letter that ressemble those on a Scrabble board
    return Card(
      elevation: 5,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: widget.uselessIsRevealed
                ? [tm.uselessLetterColorLight, tm.uselessLetterColorDark]
                : widget.isAHiddenLetter
                    ? [tm.hiddenLetterColorLight, tm.hiddenLetterColorDark]
                    : [tm.letterColorLight, tm.letterColorDark],
            stops: const [0, 0.4],
          ),
          border: Border.all(color: Colors.black),
          borderRadius: const BorderRadius.all(Radius.circular(5)),
        ),
        child: widget.isHidden
            ? null
            : Stack(
                children: [
                  Center(
                    child: Text(
                      valuableLetter.data,
                      style: TextStyle(
                        color: tm.textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: widget.letterSize,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 2.0, right: 4.0),
                      child: Text(
                        valuableLetter.value.toString(),
                        style: TextStyle(
                            color: tm.textColor, fontSize: widget.numberSize),
                      ),
                    ),
                  )
                ],
              ),
      ),
    );
  }
}
