import 'package:common/managers/theme_manager.dart';
import 'package:flutter/material.dart';
import 'package:train_de_mots/managers/game_manager.dart';
import 'package:train_de_mots/models/word_solution.dart';

class HelpFromTheControllerCard extends StatelessWidget {
  const HelpFromTheControllerCard({super.key});

  @override
  Widget build(BuildContext context) {
    final tm = ThemeManager.instance;

    return Card(
      color: tm.mainColor,
      elevation: 10,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aides du contrôleur :',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: tm.titleSize * 0.6,
                  color: tm.textColor),
            ),
            const SizedBox(
              width: 250,
              child: Column(
                children: [
                  _Pardon(),
                  _Boost(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pardon extends StatefulWidget {
  const _Pardon();

  @override
  State<_Pardon> createState() => _PardonState();
}

class _PardonState extends State<_Pardon> {
  String? _lastStealer;

  @override
  void initState() {
    super.initState();

    final gm = GameManager.instance;
    gm.onNewPardonGranted.addListener(_refresh);
    gm.onStealerPardoned.addListener(_onStealerPardoned);
    gm.onSolutionWasStolen.addListener(_onSolutionWasStolen);
    gm.onRoundIsOver.addListener(_resetCard);
  }

  @override
  void dispose() {
    final gm = GameManager.instance;
    gm.onNewPardonGranted.removeListener(_refresh);
    gm.onStealerPardoned.removeListener(_onStealerPardoned);
    gm.onSolutionWasStolen.removeListener(_onSolutionWasStolen);
    gm.onRoundIsOver.removeListener(_resetCard);

    super.dispose();
  }

  void _refresh() => setState(() {});

  void _onStealerPardoned(WordSolution? solution) {
    // If isStolen is true, it means it was pardoned by the wrong user
    if (solution == null || solution.isStolen) return;

    _lastStealer = null;
    setState(() {});
  }

  void _onSolutionWasStolen(WordSolution solution) {
    _lastStealer = solution.stolenFrom.name;
    setState(() {});
  }

  void _resetCard(_) {
    _lastStealer = null;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final gm = GameManager.instance;
    final tm = ThemeManager.instance;

    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            '!pardon${_lastStealer == null ? '' : ' ($_lastStealer)'}',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: tm.titleSize * 0.6, color: tm.textColor),
          ),
        ),
        Text('x ${gm.remainingPardon}',
            style: TextStyle(
                fontStyle: FontStyle.italic,
                fontSize: tm.titleSize * 0.6,
                color: tm.textColor)),
      ],
    );
  }
}

class _Boost extends StatefulWidget {
  const _Boost();

  @override
  State<_Boost> createState() => _BoostState();
}

class _BoostState extends State<_Boost> {
  @override
  void initState() {
    super.initState();

    final gm = GameManager.instance;
    gm.onTrainGotBoosted.addListener(_refreshWithParameter);
    gm.onClockTicked.addListener(_refresh);
  }

  @override
  void dispose() {
    final gm = GameManager.instance;
    gm.onTrainGotBoosted.removeListener(_refreshWithParameter);
    gm.onClockTicked.removeListener(_refresh);

    super.dispose();
  }

  void _refresh() => setState(() {});
  void _refreshWithParameter(_) => setState(() {});

  @override
  Widget build(BuildContext context) {
    final gm = GameManager.instance;
    final tm = ThemeManager.instance;

    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '!boost',
          style: TextStyle(fontSize: tm.titleSize * 0.6, color: tm.textColor),
        ),
        Text(
            gm.isTrainBoosted
                ? 'Boost (${gm.trainBoostRemainingTime!.inSeconds})'
                : 'x ${gm.remainingBoosts}',
            style: TextStyle(
                fontStyle: FontStyle.italic,
                fontSize: tm.titleSize * 0.6,
                color: tm.textColor)),
      ],
    );
  }
}
