import 'package:common/generic/managers/theme_manager.dart';
import 'package:flutter/material.dart';
import 'package:train_de_mots/generic/managers/managers.dart';
import 'package:train_de_mots/generic/widgets/theme_card.dart';

class TrackFixHeader extends StatefulWidget {
  const TrackFixHeader({super.key});

  @override
  State<TrackFixHeader> createState() => _TrackFixHeaderState();
}

class _TrackFixHeaderState extends State<TrackFixHeader> {
  @override
  void initState() {
    super.initState();

    final gm = Managers.instance.miniGames.trackFix;
    gm.onGameStarted.listen(_onGameStarted);
    gm.onClockTicked.listen(_onClockTicked);
  }

  @override
  void dispose() {
    final gm = Managers.instance.miniGames.trackFix;
    gm.onGameStarted.cancel(_onGameStarted);
    gm.onClockTicked.cancel(_onClockTicked);

    super.dispose();
  }

  void _onGameStarted() {
    setState(() {});
  }

  void _onClockTicked(Duration timeRemaining) {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final tm = ThemeManager.instance;

    return ThemeCard(
      child: Text(
        'Temps restant: ${Managers.instance.miniGames.trackFix.timeRemaining.inSeconds}',
        style: tm.clientMainTextStyle.copyWith(
            fontWeight: FontWeight.bold, fontSize: 26, color: tm.textColor),
      ),
    );
  }
}
