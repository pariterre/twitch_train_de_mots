import 'dart:math';

import 'package:common/models/game_status.dart';
import 'package:common/widgets/clock.dart';
import 'package:common/widgets/fireworks.dart';
import 'package:common/widgets/growing_widget.dart';
import 'package:flutter/material.dart';
import 'package:train_de_mots/generic/managers/managers.dart';
import 'package:train_de_mots/words_train/models/word_solution.dart';

class SolutionsDisplayer extends StatefulWidget {
  const SolutionsDisplayer({super.key});

  @override
  State<SolutionsDisplayer> createState() => _SolutionsDisplayerState();
}

class _SolutionsDisplayerState extends State<SolutionsDisplayer> {
  final _fireworksControllers = <WordSolution, FireworksController>{};

  final List<String> _mvpPlayers = [];

  @override
  void initState() {
    super.initState();

    final gm = Managers.instance.train;
    gm.onRoundStarted.listen(_reinitializeFireworks);
    gm.onRoundStarted.listen(_fetchMvpPlayers);
    gm.onSolutionFound.listen(_onSolutionFound);
    gm.onStealerPardoned.listen(_onPlayerWasPardoned);
    gm.onPlayerUpdate.listen(_refresh);
    gm.onGoldenSolutionAppeared.listen(_onGoldenSolutionAppeared);

    final tm = Managers.instance.theme;
    tm.onChanged.listen(_refresh);

    _fetchMvpPlayers();
    _reinitializeFireworks();
  }

  Future<void> _fetchMvpPlayers() async {
    // It is okay to do that once at the beginning of each round since the best
    // players can only change when a new game is started anyway.
    final dm = Managers.instance.database;
    final team = await dm.getCurrentTeamResult();
    _mvpPlayers.clear();
    _mvpPlayers.addAll(team.mvpScore.map((e) => e.name));
  }

  @override
  void dispose() {
    final gm = Managers.instance.train;
    gm.onRoundStarted.cancel(_reinitializeFireworks);
    gm.onRoundStarted.cancel(_fetchMvpPlayers);
    gm.onSolutionFound.cancel(_onSolutionFound);
    gm.onStealerPardoned.cancel(_onPlayerWasPardoned);
    gm.onPlayerUpdate.cancel(_refresh);
    gm.onGoldenSolutionAppeared.cancel(_onGoldenSolutionAppeared);

    final tm = Managers.instance.theme;
    tm.onChanged.cancel(_refresh);

    _fireworksControllers.forEach((key, value) => value.dispose());

    super.dispose();
  }

  void _reinitializeFireworks() {
    final gm = Managers.instance.train;
    if (gm.problem == null) return;

    _fireworksControllers.forEach((key, value) => value.dispose());
    _fireworksControllers.clear();

    final solutions = gm.problem!.solutions;
    for (final solution in solutions) {
      _fireworksControllers[solution] = FireworksController(
          isHuge: solution.word.length == solutions.nbLettersInLongest);
    }

    setState(() {});
  }

  void _onSolutionFound(WordSolution? solution) {
    if (solution == null) return;

    _fireworksControllers[solution]?.trigger();
  }

  void _onPlayerWasPardoned(WordSolution? solution) {
    if (solution == null || solution.isStolen) return;

    _fireworksControllers[solution]?.trigger();
  }

  void _refresh() => setState(() {});

  void _onGoldenSolutionAppeared(WordSolution solution) {
    _fireworksControllers[solution]?.dispose();
    _fireworksControllers[solution] = FireworksController(isHuge: true);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final gm = Managers.instance.train;
    final tm = Managers.instance.theme;

    if (gm.problem == null) return Container();

    final solutions = gm.problem!.solutions;

    List<WordSolutions> solutionsByLength = [];
    for (var i = solutions.nbLettersInSmallest;
        i <= solutions.nbLettersInLongest;
        i++) {
      solutionsByLength.add(solutions.solutionsOfLength(i));
    }

    const headerHeight = 375;
    const solutionTileHeight = 58.0;
    final maxHeight = MediaQuery.of(context).size.height - headerHeight;
    final nbSolutionPerColumn =
        maxHeight ~/ solutionTileHeight - 1; // -1 accounts for the header

    return SizedBox(
      height: maxHeight,
      child: Wrap(
        direction: Axis.vertical,
        children: [
          for (var solutions
              in solutionsByLength.where((element) => element.isNotEmpty))
            SizedBox(
              height: solutions.length > nbSolutionPerColumn
                  ? double.infinity
                  : (solutions.length + 1) * solutionTileHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        'Mots de ${solutions.first.word.length} lettres',
                        style: tm.clientMainTextStyle.copyWith(
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
                              _SolutionWrapper(
                                  solutions: solutions,
                                  mvpPlayers: _mvpPlayers),
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
            ),
        ],
      ),
    );
  }
}

class _SolutionWrapper extends StatefulWidget {
  const _SolutionWrapper({required this.solutions, required this.mvpPlayers});

  final WordSolutions solutions;
  final List<String> mvpPlayers;

  @override
  State<_SolutionWrapper> createState() => _SolutionWrapperState();
}

class _SolutionWrapperState extends State<_SolutionWrapper> {
  @override
  void initState() {
    super.initState();

    final gm = Managers.instance.train;
    gm.onSolutionFound.listen(_onSolutionFound);
    gm.onStealerPardoned.listen(_onSolutionFound);
  }

  @override
  void dispose() {
    final gm = Managers.instance.train;
    gm.onSolutionFound.cancel(_onSolutionFound);
    gm.onStealerPardoned.cancel(_onSolutionFound);

    super.dispose();
  }

  void _onSolutionFound(_) => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      direction: Axis.vertical,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ...widget.solutions.map((e) => _SolutionTile(
            key: ValueKey(e), solution: e, mvpPlayers: widget.mvpPlayers))
      ],
    );
  }
}

class _FireworksWrapper extends StatelessWidget {
  const _FireworksWrapper(
      {required this.solutions, required this.fireworksControllers});

  final WordSolutions solutions;
  final Map<WordSolution, FireworksController> fireworksControllers;

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
  const _SolutionTile(
      {super.key, required this.solution, this.fireworks, this.mvpPlayers});

  final List<String>? mvpPlayers;
  final WordSolution solution;
  final FireworksController? fireworks;

  @override
  State<_SolutionTile> createState() => _SolutionTileState();
}

class _SolutionTileState extends State<_SolutionTile> {
  @override
  void initState() {
    super.initState();

    final cm = Managers.instance.configuration;
    cm.onChanged.listen(_refresh);

    final tm = Managers.instance.theme;
    tm.onChanged.listen(_refresh);

    final gm = Managers.instance.train;
    gm.onRoundIsPreparing.listen(_refresh);
  }

  @override
  void dispose() {
    super.dispose();

    final cm = Managers.instance.configuration;
    cm.onChanged.cancel(_refresh);

    final tm = Managers.instance.theme;
    tm.onChanged.cancel(_refresh);

    final gm = Managers.instance.train;
    gm.onRoundIsPreparing.cancel(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final cm = Managers.instance.configuration;
    final tm = Managers.instance.theme;

    final widthFactor = min(MediaQuery.of(context).size.width / 1920, 1.0);
    final heightFactor = min(MediaQuery.of(context).size.height / 1080, 1.0);

    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        child: SizedBox(
          width: tm.textSize * 13 * widthFactor,
          height: tm.textSize * 2.1 * heightFactor,
          child: cm.showAnswersTooltip
              ? Tooltip(
                  message: widget.solution.isFound ? '' : widget.solution.word,
                  verticalOffset: -5,
                  textStyle:
                      TextStyle(fontSize: tm.textSize, color: Colors.white),
                  child: _buildTile(
                      widthFactor: widthFactor, heightFactor: heightFactor),
                )
              : _buildTile(
                  widthFactor: widthFactor, heightFactor: heightFactor),
        ));
  }

  Widget _buildTile(
      {required double widthFactor, required double heightFactor}) {
    final gm = Managers.instance.train;
    final tm = Managers.instance.theme;

    if (widget.fireworks != null) {
      return Fireworks(
          key: widget.fireworks!.key, controller: widget.fireworks!);
    }
    final showCooldown = widget.solution.isFound &&
        (widget.solution.foundBy.lastSolutionFound == widget.solution &&
            widget.solution.foundBy.isInCooldownPeriod);

    final tile = Container(
      decoration: _boxDecoration,
      padding: EdgeInsets.symmetric(horizontal: tm.textSize / 2 * widthFactor),
      child: widget.solution.isFound ||
              gm.gameStatus == GameStatus.revealAnswers
          ? Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    children: [
                      Text(
                        widget.solution.word,
                        style: TextStyle(
                            fontSize: tm.textSize * heightFactor,
                            fontWeight: FontWeight.bold,
                            color: widget.solution.isFound
                                ? tm.textSolvedColor
                                : tm.textUnsolvedColor),
                      ),
                      if (widget.solution.isFound)
                        Flexible(
                          child: Text(
                            ' (${widget.solution.foundBy.name})',
                            style: TextStyle(
                                fontSize: tm.textSize * heightFactor,
                                color: tm.textSolvedColor),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
                if (showCooldown && gm.gameStatus == GameStatus.roundStarted)
                  Padding(
                    padding: const EdgeInsets.only(left: 15.0),
                    child: SizedBox(
                      height: 15,
                      child: Clock(
                        timeRemaining:
                            widget.solution.foundBy.cooldownRemaining,
                        maxDuration: widget.solution.foundBy.cooldownDuration,
                      ),
                    ),
                  ),
              ],
            )
          : widget.solution.isGolden
              ? const Icon(Icons.star, color: Colors.amber)
              : Container(),
    );

    if (widget.solution.isGolden && !widget.solution.isFound) {
      return GrowingWidget(
          growingFactor: 1.05,
          duration: const Duration(seconds: 1),
          child: tile);
    } else {
      return tile;
    }
  }

  BoxDecoration get _boxDecoration => BoxDecoration(
        gradient: widget.solution.isGolden
            ? isGolden
            : (widget.solution.isFound
                ? (widget.solution.isStolen ? stolen : solved)
                : unsolved),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.black),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 3.0,
            spreadRadius: 0.0,
            offset: const Offset(5.0, 5.0),
          )
        ],
      );

  LinearGradient get isGolden {
    final tm = Managers.instance.theme;

    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        tm.solutionIsGoldenLight,
        tm.solutionIsGoldenDark,
      ],
      stops: const [0, 0.6],
    );
  }

  LinearGradient get unsolved {
    final tm = Managers.instance.theme;

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
    final tm = Managers.instance.theme;

    final solvedByMvp =
        widget.mvpPlayers!.contains(widget.solution.foundBy.name);

    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: solvedByMvp
          ? [
              tm.solutionSolvedByMvpColorLight,
              tm.solutionSolvedByMvpColorDark,
            ]
          : [
              tm.solutionSolvedColorLight!,
              tm.solutionSolvedColorDark!,
            ],
      stops: const [0.1, 1],
    );
  }

  LinearGradient get stolen {
    final tm = Managers.instance.theme;

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
