import 'package:common/managers/theme_manager.dart';
import 'package:flutter/material.dart';
import 'package:train_de_mots/generic/managers/managers.dart';
import 'package:train_de_mots/generic/widgets/theme_card.dart';
import 'package:train_de_mots/words_train/models/word_solution.dart';

class HelpFromTheControllerCard extends StatelessWidget {
  const HelpFromTheControllerCard({super.key});

  @override
  Widget build(BuildContext context) {
    final tm = ThemeManager.instance;

    return ThemeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aides du contrôleur :',
            style: tm.clientMainTextStyle.copyWith(
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

    final gm = Managers.instance.train;
    gm.onNewPardonGranted.listen(_refresh);
    gm.onStealerPardoned.listen(_onStealerPardoned);
    gm.onSolutionWasStolen.listen(_onSolutionWasStolen);
    gm.onRoundIsOver.listen(_resetCardInterfaced);
    gm.onRoundStarted.listen(_resetCard);
  }

  @override
  void dispose() {
    final gm = Managers.instance.train;
    gm.onNewPardonGranted.cancel(_refresh);
    gm.onStealerPardoned.cancel(_onStealerPardoned);
    gm.onSolutionWasStolen.cancel(_onSolutionWasStolen);
    gm.onRoundIsOver.cancel(_resetCardInterfaced);
    gm.onRoundStarted.cancel(_resetCard);

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

  void _resetCardInterfaced(_) => _resetCard();

  void _resetCard() => setState(() => _lastStealer = null);

  @override
  Widget build(BuildContext context) {
    final gm = Managers.instance.train;
    final tm = ThemeManager.instance;

    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            '!pardon${_lastStealer == null ? '' : ' ($_lastStealer)'}',
            overflow: TextOverflow.ellipsis,
            style: tm.clientMainTextStyle
                .copyWith(fontSize: tm.titleSize * 0.6, color: tm.textColor),
          ),
        ),
        Text('x ${gm.remainingPardon}',
            style: tm.clientMainTextStyle.copyWith(
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

    final gm = Managers.instance.train;
    gm.onTrainGotBoosted.listen(_refreshWithParameter);
    gm.onClockTicked.listen(_refresh);
  }

  @override
  void dispose() {
    final gm = Managers.instance.train;
    gm.onTrainGotBoosted.cancel(_refreshWithParameter);
    gm.onClockTicked.cancel(_refresh);

    super.dispose();
  }

  void _refresh() => setState(() {});
  void _refreshWithParameter(_) => setState(() {});

  @override
  Widget build(BuildContext context) {
    final gm = Managers.instance.train;
    final tm = ThemeManager.instance;

    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '!boost',
          style: tm.clientMainTextStyle
              .copyWith(fontSize: tm.titleSize * 0.6, color: tm.textColor),
        ),
        Text(
            gm.isTrainBoosted
                ? 'Boost (${gm.trainBoostRemainingTime!.inSeconds})'
                : 'x ${gm.remainingBoosts}',
            style: tm.clientMainTextStyle.copyWith(
                fontStyle: FontStyle.italic,
                fontSize: tm.titleSize * 0.6,
                color: tm.textColor)),
      ],
    );
  }
}
