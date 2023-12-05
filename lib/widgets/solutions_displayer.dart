import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:train_de_mots/models/custom_scheme.dart';
import 'package:train_de_mots/managers/configuration_manager.dart';
import 'package:train_de_mots/models/game_manager.dart';
import 'package:train_de_mots/models/solution.dart';
import 'package:train_de_mots/widgets/clock.dart';
import 'package:train_de_mots/widgets/fireworks.dart';

class SolutionsDisplayer extends ConsumerStatefulWidget {
  const SolutionsDisplayer({super.key});

  @override
  ConsumerState<SolutionsDisplayer> createState() => _SolutionsDisplayerState();
}

class _SolutionsDisplayerState extends ConsumerState<SolutionsDisplayer> {
  final _fireworksControllers = <Solution, FireworksController>{};

  @override
  void initState() {
    super.initState();

    final gm = ref.read(gameManagerProvider);
    gm.onRoundStarted.addListener(_reinitializeFireworks);
    gm.onSolutionFound.addListener(_onSolutionFound);
    gm.onPlayerUpdate.addListener(_onPlayerUpdate);
    _reinitializeFireworks();
  }

  @override
  void dispose() {
    super.dispose();

    final gm = ref.read(gameManagerProvider);
    gm.onRoundStarted.removeListener(_reinitializeFireworks);
    gm.onSolutionFound.removeListener(_onSolutionFound);
    gm.onPlayerUpdate.removeListener(_onPlayerUpdate);
  }

  void _reinitializeFireworks() {
    if (!mounted) return;

    _fireworksControllers.clear();
    final solutions = ref.read(gameManagerProvider).problem!.solutions;
    for (final solution in solutions) {
      _fireworksControllers[solution] = FireworksController(
          huge: solution.word.length == solutions.nbLettersInLongest);
    }

    setState(() {});
  }

  void _onSolutionFound(solution) {
    _fireworksControllers[solution]?.trigger();
  }

  void _onPlayerUpdate() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final scheme = ref.read(schemeProvider);
    final solutions = ref.read(gameManagerProvider).problem!.solutions;

    List<Solutions> solutionsByLength = [];
    for (var i = solutions.nbLettersInSmallest;
        i <= solutions.nbLettersInLongest;
        i++) {
      solutionsByLength.add(solutions.solutionsOfLength(i));
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var solutions in solutionsByLength)
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
                        color: scheme.textColor,
                        fontSize: scheme.textSize),
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

class _SolutionWrapper extends ConsumerStatefulWidget {
  const _SolutionWrapper({required this.solutions});

  final Solutions solutions;

  @override
  ConsumerState<_SolutionWrapper> createState() => _SolutionWrapperState();
}

class _SolutionWrapperState extends ConsumerState<_SolutionWrapper> {
  @override
  void initState() {
    super.initState();
    ref.read(gameManagerProvider).onSolutionFound.addListener(_onSolutionFound);
  }

  @override
  void dispose() {
    super.dispose();
    ref
        .read(gameManagerProvider)
        .onSolutionFound
        .removeListener(_onSolutionFound);
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

class _SolutionTile extends ConsumerStatefulWidget {
  const _SolutionTile({super.key, required this.solution, this.fireworks});

  final Solution solution;
  final FireworksController? fireworks;

  @override
  ConsumerState<_SolutionTile> createState() => _SolutionTileState();
}

class _SolutionTileState extends ConsumerState<_SolutionTile> {
  @override
  void initState() {
    super.initState();

    final cm = ConfigurationManager.instance;
    cm.onChanged.addListener(_refresh);
  }

  @override
  void dispose() {
    super.dispose();

    final cm = ConfigurationManager.instance;
    cm.onChanged.removeListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final cm = ConfigurationManager.instance;

    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        child: SizedBox(
          width: ref.watch(schemeProvider).textSize * 12,
          height: 50,
          child: cm.showAnswersTooltip
              ? Tooltip(
                  message: widget.solution.isFound ? '' : widget.solution.word,
                  verticalOffset: -5,
                  textStyle: TextStyle(
                      fontSize: ref.read(schemeProvider).textSize,
                      color: Colors.white),
                  child: _buildTile(ref),
                )
              : _buildTile(ref),
        ));
  }

  Widget _buildTile(WidgetRef ref) {
    final scheme = ref.read(schemeProvider);
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
                        fontSize: ref.read(schemeProvider).textSize,
                        fontWeight: FontWeight.bold,
                        color: widget.solution.isFound
                            ? scheme.textSolvedColor
                            : scheme.textUnsolvedColor),
                  ),
                  Text(
                    ' (${widget.solution.foundBy.name})',
                    style: TextStyle(
                        fontSize: ref.read(schemeProvider).textSize,
                        color: widget.solution.isFound
                            ? scheme.textSolvedColor
                            : scheme.textUnsolvedColor),
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
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        ref.read(schemeProvider).solutionUnsolvedColorLight!,
        ref.read(schemeProvider).solutionUnsolvedColorDark!,
      ],
      stops: const [0, 0.6],
    );
  }

  LinearGradient get solved => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          ref.read(schemeProvider).solutionSolvedColorLight!,
          ref.read(schemeProvider).solutionSolvedColorDark!,
        ],
        stops: const [0.1, 1],
      );

  LinearGradient get stolen => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          ref.read(schemeProvider).solutionStolenColorLight!,
          ref.read(schemeProvider).solutionStolenColorDark!,
        ],
        stops: const [0.1, 1],
      );
}
