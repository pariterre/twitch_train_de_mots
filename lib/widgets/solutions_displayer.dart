import 'package:flutter/material.dart';
import 'package:train_de_mots/managers/theme_manager.dart';
import 'package:train_de_mots/managers/configuration_manager.dart';
import 'package:train_de_mots/managers/game_manager.dart';
import 'package:train_de_mots/models/solution.dart';
import 'package:train_de_mots/widgets/clock.dart';
import 'package:train_de_mots/widgets/fireworks.dart';

class SolutionsDisplayer extends StatefulWidget {
  const SolutionsDisplayer({super.key});

  @override
  State<SolutionsDisplayer> createState() => _SolutionsDisplayerState();
}

class _SolutionsDisplayerState extends State<SolutionsDisplayer> {
  final _fireworksControllers = <Solution, FireworksController>{};

  @override
  void initState() {
    super.initState();

    final gm = GameManager.instance;
    gm.onRoundStarted.addListener(_reinitializeFireworks);
    gm.onSolutionFound.addListener(_onSolutionFound);
    gm.onPlayerUpdate.addListener(_refresh);

    final tm = ThemeManager.instance;
    tm.onChanged.addListener(_refresh);

    _reinitializeFireworks();
  }

  @override
  void dispose() {
    final gm = GameManager.instance;
    gm.onRoundStarted.removeListener(_reinitializeFireworks);
    gm.onSolutionFound.removeListener(_onSolutionFound);
    gm.onPlayerUpdate.removeListener(_refresh);

    final tm = ThemeManager.instance;
    tm.onChanged.removeListener(_refresh);

    super.dispose();
  }

  void _reinitializeFireworks() {
    final gm = GameManager.instance;
    if (gm.problem == null) return;

    _fireworksControllers.clear();
    final solutions = gm.problem!.solutions;
    for (final solution in solutions) {
      _fireworksControllers[solution] = FireworksController(
          huge: solution.word.length == solutions.nbLettersInLongest);
    }

    setState(() {});
  }

  void _onSolutionFound(solution) {
    _fireworksControllers[solution]?.trigger();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final gm = GameManager.instance;
    final tm = ThemeManager.instance;

    if (gm.problem == null) return Container();

    final solutions = gm.problem!.solutions;

    List<Solutions> solutionsByLength = [];
    for (var i = solutions.nbLettersInSmallest;
        i <= solutions.nbLettersInLongest;
        i++) {
      solutionsByLength.add(solutions.solutionsOfLength(i));
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var solutions
            in solutionsByLength.where((element) => element.isNotEmpty))
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    'Mots de ${solutions.first.word.length} lettres',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: tm.textColor,
                        fontSize: tm.textSize),
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(builder: (context, constraint) {
                    return SizedBox(
                      height: constraint.maxHeight,
                      child: Stack(
                        children: [
                          _SolutionWrapper(solutions: solutions),
                          _FireworksWrapper(
                              solutions: solutions,
                              fireworksControllers: _fireworksControllers),
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _SolutionWrapper extends StatefulWidget {
  const _SolutionWrapper({required this.solutions});

  final Solutions solutions;

  @override
  State<_SolutionWrapper> createState() => _SolutionWrapperState();
}

class _SolutionWrapperState extends State<_SolutionWrapper> {
  @override
  void initState() {
    super.initState();

    final gm = GameManager.instance;
    gm.onSolutionFound.addListener(_onSolutionFound);
  }

  @override
  void dispose() {
    final gm = GameManager.instance;
    gm.onSolutionFound.removeListener(_onSolutionFound);

    super.dispose();
  }

  void _onSolutionFound(_) => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      direction: Axis.vertical,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ...widget.solutions
            .map((e) => _SolutionTile(key: ValueKey(e), solution: e))
      ],
    );
  }
}

class _FireworksWrapper extends StatelessWidget {
  const _FireworksWrapper(
      {required this.solutions, required this.fireworksControllers});

  final Solutions solutions;
  final Map<Solution, FireworksController> fireworksControllers;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      direction: Axis.vertical,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ...solutions.map((solution) {
          final controller = fireworksControllers[solution]!;
          return _SolutionTile(solution: solution, fireworks: controller);
        })
      ],
    );
  }
}

class _SolutionTile extends StatefulWidget {
  const _SolutionTile({super.key, required this.solution, this.fireworks});

  final Solution solution;
  final FireworksController? fireworks;

  @override
  State<_SolutionTile> createState() => _SolutionTileState();
}

class _SolutionTileState extends State<_SolutionTile> {
  @override
  void initState() {
    super.initState();

    final cm = ConfigurationManager.instance;
    cm.onChanged.addListener(_refresh);

    final tm = ThemeManager.instance;
    tm.onChanged.addListener(_refresh);
  }

  @override
  void dispose() {
    super.dispose();

    final cm = ConfigurationManager.instance;
    cm.onChanged.removeListener(_refresh);

    final tm = ThemeManager.instance;
    tm.onChanged.removeListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final cm = ConfigurationManager.instance;
    final tm = ThemeManager.instance;

    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        child: SizedBox(
          width: tm.textSize * 13,
          height: 50,
          child: cm.showAnswersTooltip
              ? Tooltip(
                  message: widget.solution.isFound ? '' : widget.solution.word,
                  verticalOffset: -5,
                  textStyle:
                      TextStyle(fontSize: tm.textSize, color: Colors.white),
                  child: _buildTile(),
                )
              : _buildTile(),
        ));
  }

  Widget _buildTile() {
    final tm = ThemeManager.instance;
    final gc = ConfigurationManager.instance;

    if (widget.fireworks != null) {
      return Fireworks(
          key: widget.fireworks!.key, controller: widget.fireworks!);
    }

    return Container(
      decoration: _boxDecoration,
      child: widget.solution.isFound
          ? Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.solution.word,
                    style: TextStyle(
                        fontSize: tm.textSize,
                        fontWeight: FontWeight.bold,
                        color: widget.solution.isFound
                            ? tm.textSolvedColor
                            : tm.textUnsolvedColor),
                  ),
                  Text(
                    ' (${widget.solution.foundBy.name})',
                    style: TextStyle(
                        fontSize: tm.textSize,
                        color: widget.solution.isFound
                            ? tm.textSolvedColor
                            : tm.textUnsolvedColor),
                  ),
                  if (widget.solution.foundBy.lastSolutionFound ==
                          widget.solution &&
                      widget.solution.foundBy.cooldownRemaining.inSeconds > 0)
                    Padding(
                      padding: const EdgeInsets.only(left: 15.0),
                      child: SizedBox(
                        height: 15,
                        child: Clock(
                          timeRemaining:
                              widget.solution.foundBy.cooldownRemaining,
                          maxDuration: widget.solution.wasStolen
                              ? gc.cooldownPeriodAfterSteal
                              : gc.cooldownPeriod,
                        ),
                      ),
                    ),
                ],
              ),
            )
          : null,
    );
  }

  BoxDecoration get _boxDecoration => BoxDecoration(
        gradient: widget.solution.isFound
            ? (widget.solution.wasStolen ? stolen : solved)
            : unsolved,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.black),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 3.0,
            spreadRadius: 0.0,
            offset: const Offset(5.0, 5.0),
          )
        ],
      );

  LinearGradient get unsolved {
    final tm = ThemeManager.instance;

    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        tm.solutionUnsolvedColorLight!,
        tm.solutionUnsolvedColorDark!,
      ],
      stops: const [0, 0.6],
    );
  }

  LinearGradient get solved {
    final tm = ThemeManager.instance;

    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        tm.solutionSolvedColorLight!,
        tm.solutionSolvedColorDark!,
      ],
      stops: const [0.1, 1],
    );
  }

  LinearGradient get stolen {
    final tm = ThemeManager.instance;

    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        tm.solutionStolenColorLight!,
        tm.solutionStolenColorDark!,
      ],
      stops: const [0.1, 1],
    );
  }
}
