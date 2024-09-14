import 'package:common/managers/theme_manager.dart';
import 'package:common/widgets/themed_elevated_button.dart';
import 'package:flutter/material.dart';
import 'package:frontend/managers/game_manager.dart';
import 'package:frontend/managers/twitch_manager.dart';
import 'package:frontend/widgets/header.dart';
import 'package:logging/logging.dart';

final _logger = Logger('PlayScreen');

class PlayScreen extends StatelessWidget {
  const PlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
        child: Stack(
      children: [
        Header(
            titleText: 'Le train est en route!\n'
                'Bon voyage!'), // TODO Add the next station
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PardonRequest(),
              SizedBox(height: 30.0),
              _BoostRequest(),
            ],
          ),
        ),
      ],
    ));
  }
}

class _PardonRequest extends StatefulWidget {
  const _PardonRequest();

  @override
  State<_PardonRequest> createState() => _PardonRequestState();
}

class _PardonRequestState extends State<_PardonRequest> {
  bool _canPlayerPardon = false;

  @override
  void initState() {
    super.initState();

    final gm = GameManager.instance;
    gm.onPardonnersChanged.addListener(_updatePlayersWhoCanPardon);
  }

  @override
  void dispose() {
    final gm = GameManager.instance;
    gm.onPardonnersChanged.removeListener(_updatePlayersWhoCanPardon);

    super.dispose();
  }

  void _updatePlayersWhoCanPardon() {
    final pardonners = GameManager.instance.pardonners;
    _logger.info('Update current pardonners to: $pardonners');
    final myId = TwitchManager.instance.opaqueUserId;
    _canPlayerPardon = pardonners.any((id) => id == myId);
    setState(() {});
  }

  void _onPardonPressed() async {
    final canPlayerPardonBack = _canPlayerPardon;
    setState(() => _canPlayerPardon = false);

    final isSuccess = await TwitchManager.instance.pardonStealer();
    if (!isSuccess) setState(() => _canPlayerPardon = canPlayerPardonBack);

    if (!mounted) return;
    // TODO Change the snack bar and change it to bouncy bounds
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
          isSuccess ? 'Pardon request successful' : 'Pardon request failed'),
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final tm = ThemeManager.instance;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Donner son pardon...',
          style: tm.textFrontendSc,
        ),
        const SizedBox(height: 8),
        ThemedElevatedButton(
          onPressed: _canPlayerPardon ? _onPardonPressed : null,
          buttonText: 'Pardon',
        ),
      ],
    );
  }
}

class _BoostRequest extends StatefulWidget {
  const _BoostRequest();

  @override
  State<_BoostRequest> createState() => _BoostRequestState();
}

class _BoostRequestState extends State<_BoostRequest> {
  bool _canPlayerBoost = true;

  @override
  void initState() {
    super.initState();

    final gm = GameManager.instance;
    gm.onBoostAvailabilityChanged.addListener(_updateBoostAvailability);
  }

  @override
  void dispose() {
    final gm = GameManager.instance;
    gm.onBoostAvailabilityChanged.removeListener(_updateBoostAvailability);

    super.dispose();
  }

  void _updateBoostAvailability() {
    _canPlayerBoost = GameManager.instance.boostCount > 0;
    _logger.info(_canPlayerBoost
        ? 'The player can boost the train'
        : 'The player cannot boost the train');
    setState(() {});
  }

  void _onBoostPressed() async {
    final canPlayerBoostBack = _canPlayerBoost;
    setState(() => _canPlayerBoost = false);

    final isSuccess = await TwitchManager.instance.boostTrain();
    if (!isSuccess) setState(() => _canPlayerBoost = canPlayerBoostBack);

    if (!mounted) return;
    // TODO Change the snack bar and change it to bouncy bounds
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content:
          Text(isSuccess ? 'Boost request successful' : 'Boost request failed'),
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final tm = ThemeManager.instance;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Booster le train!',
          style: tm.textFrontendSc,
        ),
        const SizedBox(height: 8),
        ThemedElevatedButton(
          onPressed: _canPlayerBoost ? _onBoostPressed : null,
          buttonText: 'Boost',
        ),
      ],
    );
  }
}
