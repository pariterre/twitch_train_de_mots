import 'package:common/managers/theme_manager.dart';
import 'package:common/widgets/themed_elevated_button.dart';
import 'package:flutter/material.dart';
import 'package:frontend/managers/game_manager.dart';
import 'package:frontend/managers/twitch_manager.dart';
import 'package:frontend/widgets/animations_overlay.dart';
import 'package:frontend/widgets/header.dart';
import 'package:logging/logging.dart';

final _logger = Logger('PlayScreen');

class PlayScreen extends StatelessWidget {
  const PlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        children: [
          Header(
              titleText: 'Le train est en route!\n'
                  'Prochaine station : ${GameManager.instance.currentRound + 1}!'),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Transform.scale(
                      scale: 0.8, child: const _PardonRequest()),
                ),
                Flexible(
                    child: Transform.scale(
                        scale: 0.8, child: const _BoostRequest())),
              ],
            ),
          ),
          const AnimationOverlay(),
        ],
      ),
    );
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

    final isSuccess = await GameManager.instance.pardonStealer();
    if (!isSuccess) setState(() => _canPlayerPardon = canPlayerPardonBack);
  }

  @override
  Widget build(BuildContext context) {
    final tm = ThemeManager.instance;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Padonner..',
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

    final isSuccess = await GameManager.instance.boostTrain();
    if (!isSuccess) setState(() => _canPlayerBoost = canPlayerBoostBack);
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
