import 'package:common/managers/theme_manager.dart';
import 'package:common/models/simplified_game_state.dart';
import 'package:common/models/valuable_letter.dart';
import 'package:flutter/material.dart';

const double _baseLetterWidth = 80;
const double _baseLetterHeight = 90;
const double _baseLetterPadding = 4;
const double _baseLetterSize = 46;
const double _baseNumberSize = 26;

class LetterDisplayerCommon extends StatefulWidget {
  const LetterDisplayerCommon({
    super.key,
    required this.letterProblem,
    this.letterBuilder,
  });

  final SimplifiedLetterProblem letterProblem;
  final Widget Function(int)? letterBuilder;

  static double baseWidth(int letterCount) =>
      _baseLetterWidth * letterCount +
      2 * _baseLetterPadding * (letterCount + 1);

  @override
  State<LetterDisplayerCommon> createState() => _LetterDisplayerCommonState();
}

class _LetterDisplayerCommonState extends State<LetterDisplayerCommon> {
  double _sizeFactor = 1.0;

  double get _letterWidth => _baseLetterWidth * _sizeFactor;
  double get _letterHeight => _baseLetterHeight * _sizeFactor;
  double get _letterPadding => _baseLetterPadding * _sizeFactor;

  double get _letterSize => _baseLetterSize * _sizeFactor;
  double get _numberSize => _baseNumberSize * _sizeFactor;

  @override
  Widget build(BuildContext context) {
    final lp = widget.letterProblem;

    return LayoutBuilder(builder: (context, constraints) {
      _sizeFactor = constraints.maxWidth /
          LetterDisplayerCommon.baseWidth(lp.letters.length);

      return SizedBox(
        height: _letterHeight * 1.2,
        child: Stack(alignment: Alignment.center, children: [
          for (var index in lp.letters.asMap().keys)
            AnimatedPositioned(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                left: (_letterWidth + 2 * _letterPadding) *
                    lp.scrambleIndices[index],
                child: _Letter(
                  letter: lp.letters[index],
                  width: _letterWidth,
                  height: _letterHeight,
                  letterSize: _letterSize,
                  numberSize: _numberSize,
                  uselessStatus: lp.uselessLetterStatuses[index],
                  hiddenStatus: lp.hiddenLetterStatuses[index],
                )),
          for (var index in lp.letters.asMap().keys)
            AnimatedPositioned(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                left: (_letterWidth + 2 * _letterPadding) *
                    lp.scrambleIndices[index],
                child: SizedBox(
                  width: _letterWidth,
                  height: _letterHeight,
                  child: widget.letterBuilder != null
                      ? widget.letterBuilder!(index)
                      : null,
                )),
        ]),
      );
    });
  }
}

class _Letter extends StatefulWidget {
  const _Letter({
    required this.letter,
    required this.width,
    required this.height,
    required this.letterSize,
    required this.numberSize,
    required this.uselessStatus,
    required this.hiddenStatus,
  });

  final String letter;

  final double width;
  final double height;
  final double letterSize;
  final double numberSize;

  final LetterStatus uselessStatus;
  final LetterStatus hiddenStatus;

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
            colors: widget.uselessStatus == LetterStatus.revealed
                ? [tm.uselessLetterColorLight, tm.uselessLetterColorDark]
                : widget.hiddenStatus == LetterStatus.hidden
                    ? [tm.hiddenLetterColorLight, tm.hiddenLetterColorDark]
                    : [tm.letterColorLight, tm.letterColorDark],
            stops: const [0, 0.4],
          ),
          border: Border.all(color: Colors.black),
          borderRadius: const BorderRadius.all(Radius.circular(5)),
        ),
        child: widget.hiddenStatus == LetterStatus.hidden
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
