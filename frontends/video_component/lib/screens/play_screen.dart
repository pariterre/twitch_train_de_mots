import 'package:common/managers/theme_manager.dart';
import 'package:common/widgets/clock.dart';
import 'package:common/widgets/letter_displayer_common.dart';
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 40),
                const _LetterDisplayer(),
                const SizedBox(height: 10),
                Row(
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
                const SizedBox(height: 10),
                const _CooldownClock(),
              ],
            ),
          ),
          const AnimationOverlay(),
        ],
      ),
    );
  }
}

class _LetterDisplayer extends StatefulWidget {
  const _LetterDisplayer();

  @override
  State<_LetterDisplayer> createState() => _LetterDisplayerState();
}

class _LetterDisplayerState extends State<_LetterDisplayer> {
  @override
  void initState() {
    super.initState();

    final gm = GameManager.instance;
    gm.onLetterProblemChanged.addListener(_refresh);
  }

  @override
  void dispose() {
    final gm = GameManager.instance;
    gm.onLetterProblemChanged.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return GameManager.instance.problem == null
        ? Container()
        : Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: LetterDisplayerCommon(
                letterProblem: GameManager.instance.problem!),
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updatePlayersWhoCanPardon();
    });
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
    final myId = TwitchManager.instance.userId;
    _canPlayerPardon = pardonners.contains(myId);
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
        Text('Pardonner', style: tm.textFrontendSc),
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateBoostAvailability();
    });
  }

  @override
  void dispose() {
    final gm = GameManager.instance;
    gm.onBoostAvailabilityChanged.removeListener(_updateBoostAvailability);

    super.dispose();
  }

  void _updateBoostAvailability() {
    final gm = GameManager.instance;
    _canPlayerBoost = gm.boostCount > 0 &&
        !gm.boosters.contains(TwitchManager.instance.userId);
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
          'Booster le train',
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

class _CooldownClock extends StatefulWidget {
  const _CooldownClock();

  @override
  State<_CooldownClock> createState() => _CooldownClockState();
}

class _CooldownClockState extends State<_CooldownClock> {
  Duration _cooldownDuration = Duration.zero;
  Duration _cooldownRemaining = const Duration(seconds: -1);

  @override
  void initState() {
    super.initState();

    final gm = GameManager.instance;
    gm.onNewCooldowns.addListener(_showCooldown);

    _showCooldown();
  }

  @override
  void dispose() {
    final gm = GameManager.instance;
    gm.onNewCooldowns.removeListener(_showCooldown);
    super.dispose();
  }

  void _showCooldown() {
    final cooldowns = GameManager.instance.newCooldowns;
    if (!cooldowns.keys.contains(TwitchManager.instance.userId)) return;
    _logger.info('Showing the player cooldown');

    _cooldownDuration = cooldowns[TwitchManager.instance.userId]!;
    _cooldownRemaining = _cooldownDuration;

    // Subtract one second to account for time already passed
    _cooldownRemaining -= const Duration(seconds: 1);

    // Start a countdown that triggers a refresh every second
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      _cooldownRemaining -= const Duration(seconds: 1);
      if (!mounted) {
        return false;
      }
      setState(() {});
      return _cooldownRemaining >= Duration.zero;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tm = ThemeManager.instance;

    return Visibility(
      visible: _cooldownRemaining >= Duration.zero,
      maintainSize: true,
      maintainAnimation: true,
      maintainState: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Petite pause', style: tm.textFrontendSc),
          const SizedBox(width: 16),
          SizedBox(
              width: 20,
              height: 20,
              child: Clock(
                timeRemaining: _cooldownRemaining,
                maxDuration: _cooldownDuration,
                borderWidth: 3,
              )),
        ],
      ),
    );
  }
}
