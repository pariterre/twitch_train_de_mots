import 'package:common/generic/managers/theme_manager.dart';
import 'package:common/generic/models/game_status.dart';
import 'package:common/generic/widgets/clock.dart';
import 'package:common/generic/widgets/fireworks.dart';
import 'package:common/generic/widgets/growing_widget.dart';
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

    final tm = ThemeManager.instance;
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
    _mvpPlayers.addAll((team?.mvpScore ?? []).map((e) => e.name));
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

    final tm = ThemeManager.instance;
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

  final _spacingBetweenTiles = 2.0;
  final _solutionTileHeight = 35.0;

  Widget _buildTitle({
    required bool isTransparent,
    required int letterCount,
  }) {
    final tm = ThemeManager.instance;

    return Padding(
      padding: EdgeInsets.only(top: _spacingBetweenTiles),
      child: SizedBox(
        height: _solutionTileHeight,
        child: Center(
          child: Text(
            'Mots de $letterCount lettres',
            style: tm.clientMainTextStyle.copyWith(
                fontWeight: FontWeight.bold,
                color: isTransparent ? Colors.transparent : tm.textColor,
                fontSize: tm.textSize * 1.3),
          ),
        ),
      ),
    );
  }

  Widget _buildTile(
      {required WordSolution solution, required bool isFireworks}) {
    return Padding(
      padding:
          EdgeInsets.only(top: _spacingBetweenTiles, left: 12.0, right: 12.0),
      child: _SolutionTile(
        key: ValueKey(solution),
        fireworks: isFireworks ? _fireworksControllers[solution] : null,
        solution: solution,
        mvpPlayers: _mvpPlayers,
        tileHeight: _solutionTileHeight,
      ),
    );
  }

  Widget _buildEmptyTile() {
    return SizedBox(height: _solutionTileHeight + _spacingBetweenTiles);
  }

  List<List<Widget>> _buildGrid({
    required List<WordSolutions> solutionsByLength,
    required bool isFireworks,
    required int elementsByColumn,
  }) {
    final List<List<Widget>> widgetsByColumns = [];
    final List<Widget> currentColumn = [];
    for (final solutions in solutionsByLength) {
      if (solutions.isEmpty) continue;

      // Decide where to put the title
      if (currentColumn.length + solutions.length + 1 <= elementsByColumn) {
        // Check if we can fit the all the solutions in the current column
        // Note: the +1 for the title and spacing above title
        if (currentColumn.isNotEmpty) currentColumn.add(_buildEmptyTile());
        currentColumn.add(_buildTitle(
          isTransparent: isFireworks,
          letterCount: solutions.first.word.length,
        ));
      } else if (solutions.length <= elementsByColumn) {
        // Check if we can fit the whole column in the next column
        // Note: the +1 for the title as there is no spacing above title
        widgetsByColumns.add(currentColumn.toList());
        currentColumn.clear();
        currentColumn.add(_buildTitle(
          isTransparent: isFireworks,
          letterCount: solutions.first.word.length,
        ));
      } else if (elementsByColumn - currentColumn.length >= 5) {
        // We can fit at least three solutions in the current column
        // The 5 is for the title and the spacing with at least 3 solutions
        if (currentColumn.isNotEmpty) currentColumn.add(_buildEmptyTile());
        currentColumn.add(_buildTitle(
          isTransparent: isFireworks,
          letterCount: solutions.first.word.length,
        ));
      } else {
        // Otherwise, skip a column and write the title at top of next column
        widgetsByColumns.add(currentColumn.toList());
        currentColumn.clear();
        currentColumn.add(_buildTitle(
          isTransparent: isFireworks,
          letterCount: solutions.first.word.length,
        ));
      }

      // Fill the remaining space with the solutions, changing column if necessary
      for (final solution in solutions) {
        if (currentColumn.length > elementsByColumn) {
          widgetsByColumns.add(currentColumn.toList());
          currentColumn.clear();
          currentColumn.add(_buildEmptyTile());
        }

        currentColumn
            .add(_buildTile(solution: solution, isFireworks: isFireworks));
      }
    }
    widgetsByColumns.add(currentColumn.toList());
    return widgetsByColumns;
  }

  @override
  Widget build(BuildContext context) {
    final gm = Managers.instance.train;

    if (gm.problem == null) return Container();

    final solutions = gm.problem!.solutions;

    List<WordSolutions> solutionsByLength = [];
    for (var i = solutions.nbLettersInSmallest;
        i <= solutions.nbLettersInLongest;
        i++) {
      solutionsByLength.add(solutions.solutionsOfLength(i));
    }

    return LayoutBuilder(builder: (context, constraints) {
      final elementsByColumn = constraints.maxHeight ~/
          (_solutionTileHeight + 5 * _spacingBetweenTiles);

      return FittedBox(
        fit: BoxFit.fitWidth,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Stack(
            children: [
              ...[false, true].map(
                (isFirework) => Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ..._buildGrid(
                      solutionsByLength: solutionsByLength,
                      isFireworks: isFirework,
                      elementsByColumn: elementsByColumn,
                    ).map((widgets) => Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: widgets,
                        ))
                  ],
                ),
              )
            ],
          ),
        ),
      );
    });
  }
}

class _SolutionTile extends StatefulWidget {
  const _SolutionTile(
      {super.key,
      required this.solution,
      this.fireworks,
      this.mvpPlayers,
      required this.tileHeight});

  final List<String>? mvpPlayers;
  final WordSolution solution;
  final FireworksController? fireworks;
  final double tileHeight;

  @override
  State<_SolutionTile> createState() => _SolutionTileState();
}

class _SolutionTileState extends State<_SolutionTile> {
  @override
  void initState() {
    super.initState();

    final cm = Managers.instance.configuration;
    cm.onChanged.listen(_refresh);

    final tm = ThemeManager.instance;
    tm.onChanged.listen(_refresh);

    final gm = Managers.instance.train;
    gm.onRoundIsPreparing.listen(_refresh);
    gm.onShowcaseSolutionsRequest.listen(_refresh);
    gm.onTrainGotBoosted.listen(_showBoostedTile);
    gm.onTrainBoostEnded.listen(_refresh);
  }

  @override
  void dispose() {
    final cm = Managers.instance.configuration;
    cm.onChanged.cancel(_refresh);

    final tm = ThemeManager.instance;
    tm.onChanged.cancel(_refresh);

    final gm = Managers.instance.train;
    gm.onRoundIsPreparing.cancel(_refresh);
    gm.onShowcaseSolutionsRequest.cancel(_refresh);
    gm.onTrainGotBoosted.cancel(_showBoostedTile);
    gm.onTrainBoostEnded.cancel(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  void _showBoostedTile(dynamic _) => setState(() {});

  @override
  Widget build(BuildContext context) {
    final cm = Managers.instance.configuration;
    final tm = ThemeManager.instance;

    return SizedBox(
      width: widget.tileHeight * 7,
      height: widget.tileHeight,
      child: cm.showAnswersTooltip
          ? Tooltip(
              message: widget.solution.isFound ? '' : widget.solution.word,
              verticalOffset: -5,
              textStyle: TextStyle(fontSize: tm.textSize, color: Colors.white),
              child: _buildTile(),
            )
          : _buildTile(),
    );
  }

  Widget _buildTile() {
    final gm = Managers.instance.train;
    final tm = ThemeManager.instance;

    if (widget.fireworks != null) {
      return Fireworks(
          key: widget.fireworks!.key, controller: widget.fireworks!);
    }
    final showCooldown = widget.solution.isFound &&
        (widget.solution.foundBy.lastSolutionFound == widget.solution &&
            widget.solution.foundBy.isInCooldownPeriod);
    final cooldownTimer =
        showCooldown ? widget.solution.foundBy.cooldownTimer : null;

    final tile = Container(
        decoration: _boxDecoration,
        padding: EdgeInsets.symmetric(horizontal: tm.textSize / 2),
        child: widget.solution.isFound ||
                gm.gameStatus == WordsTrainGameStatus.roundEnding
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
                              fontSize: tm.textSize,
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
                                  fontSize: tm.textSize,
                                  color: tm.textSolvedColor),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (showCooldown &&
                      gm.gameStatus == WordsTrainGameStatus.roundStarted)
                    Padding(
                      padding: const EdgeInsets.only(left: 15.0),
                      child: SizedBox(
                        height: 15,
                        child: Clock(
                          timeRemaining:
                              cooldownTimer?.timeRemaining ?? Duration.zero,
                          maxDuration:
                              cooldownTimer?.totalDuration ?? Duration.zero,
                        ),
                      ),
                    ),
                ],
              )
            : widget.solution.isGolden
                ? Center(
                    child: SizedBox(
                      width: gm.isTrainBoosted ? 80 : 60,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(Icons.star, color: Colors.amber),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(gm.isTrainBoosted ? 'x10' : 'x5',
                                style: TextStyle(
                                    color: Colors.amber,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  )
                : gm.isTrainBoosted
                    ? Center(
                        child: Text(
                          'x2',
                          style: TextStyle(
                              fontSize: tm.textSize,
                              fontWeight: FontWeight.bold,
                              color: tm.solutionUnsolvedColorLight),
                        ),
                      )
                    : SizedBox.shrink());

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
    final tm = ThemeManager.instance;

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
