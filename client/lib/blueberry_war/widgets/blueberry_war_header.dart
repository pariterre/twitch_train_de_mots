import 'package:common/generic/managers/theme_manager.dart';
import 'package:flutter/material.dart';
import 'package:train_de_mots/blueberry_war/widgets/blueberry_war_letter_displayer.dart';
import 'package:train_de_mots/generic/managers/managers.dart';
import 'package:train_de_mots/generic/widgets/theme_card.dart';

class BlueberryWarHeader extends StatefulWidget {
  const BlueberryWarHeader({super.key});

  @override
  State<BlueberryWarHeader> createState() => _BlueberryWarHeaderState();
}

class _BlueberryWarHeaderState extends State<BlueberryWarHeader> {
  Duration _previousTimeRemaining = Duration.zero;

  @override
  void initState() {
    super.initState();

    Managers.instance.tickerManager.onClockTicked.listen(_onClockTicked);

    final bwgm = Managers.instance.miniGames.blueberryWar;
    bwgm.onInitialized.listen(_refresh);
    bwgm.onRoundEnded.listen(_refresh);
  }

  @override
  void dispose() {
    Managers.instance.tickerManager.onClockTicked.cancel(_onClockTicked);

    final bwgm = Managers.instance.miniGames.blueberryWar;
    bwgm.onInitialized.cancel(_refresh);
    bwgm.onRoundEnded.cancel(_refresh);

    super.dispose();
  }

  void _onClockTicked(Duration deltaTime) {
    final timeRemaining =
        Managers.instance.miniGames.blueberryWar.timeRemaining ?? Duration.zero;

    if (_previousTimeRemaining.inSeconds != timeRemaining.inSeconds) {
      _previousTimeRemaining = timeRemaining;
      setState(() {});
    }
  }

  void _refresh() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final tm = ThemeManager.instance;
    final bwgm = Managers.instance.miniGames.blueberryWar;

    final timeRemaining = (bwgm.timeRemaining?.isNegative ?? true)
        ? 0
        : bwgm.timeRemaining!.inSeconds + 1;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 75.0),
          child: FittedBox(
            fit: BoxFit.contain,
            child: ThemeCard(
              child: Text(
                'Temps restant: $timeRemaining',
                style: tm.clientMainTextStyle.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 26,
                  color: tm.textColor,
                ),
              ),
            ),
          ),
        ),
        BlueberryWarLetterDisplayer(),
      ],
    );
  }
}
