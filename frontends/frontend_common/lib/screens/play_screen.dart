import 'package:common/generic/managers/theme_manager.dart';
import 'package:common/generic/widgets/clock.dart';
import 'package:common/generic/widgets/letter_displayer_common.dart';
import 'package:common/generic/widgets/themed_elevated_button.dart';
import 'package:flutter/material.dart';
import 'package:frontend_common/managers/game_manager.dart';
import 'package:frontend_common/managers/twitch_manager.dart';
import 'package:frontend_common/widgets/animations_overlay.dart';
import 'package:frontend_common/widgets/header.dart';
import 'package:logging/logging.dart';

final _logger = Logger('PlayScreen');

class PlayScreen extends StatefulWidget {
  const PlayScreen(
      {super.key, required this.isMobile, required this.showTextInput});

  final bool showTextInput;
  final bool isMobile;

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
  bool _textFieldHasFocus = false;
  bool get _showReducedUi => widget.isMobile && _textFieldHasFocus;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Visibility(
          maintainState: true,
          visible: !_showReducedUi,
          child: FittedBox(
            fit: BoxFit.contain,
            child: Header(
                titleText: 'Le train est en route!\n'
                    'Prochaine station : ${GameManager.instance.currentRound + 1}!'),
          ),
        ),
        LayoutBuilder(builder: (context, constraints) {
          final tm = ThemeManager.instance;

          return Align(
            alignment: _showReducedUi ? Alignment.topCenter : Alignment.center,
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: 380,
                child: Padding(
                  padding: const EdgeInsets.only(
                      left: 20.0, right: 20.0, bottom: 20.0),
                  child: Column(
                    children: [
                      Visibility(
                          maintainState: true,
                          visible: !_showReducedUi,
                          child: const SizedBox(height: 90)),
                      const _TimeDisplayer(),
                      const SizedBox(height: 10),
                      SizedBox(
                          width: constraints.maxWidth,
                          child: const _LetterDisplayer()),
                      const SizedBox(height: 20),
                      if (widget.isMobile)
                        _TextInput(
                          onFocusChanged: (hasFocus) =>
                              setState(() => _textFieldHasFocus = hasFocus),
                        ),
                      const SizedBox(height: 20),
                      Visibility(
                        maintainState: true,
                        visible: !_showReducedUi,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Aides du contrôleur :',
                                    style: tm.textFrontendSc),
                                const SizedBox(height: 4),
                                const Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _PardonRequest(),
                                    SizedBox(width: 8),
                                    _BoostRequest(),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 30),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Soudoyer le contrôleur (bits) :',
                                    style: tm.textFrontendSc),
                                const SizedBox(height: 4),
                                const Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _ChangeLaneRequest(),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            if (!widget.isMobile)
                              const _CooldownClock(withTitle: true),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
        const AnimationOverlay(),
      ],
    );
  }
}

class _TimeDisplayer extends StatefulWidget {
  const _TimeDisplayer();

  @override
  State<_TimeDisplayer> createState() => _TimeDisplayerState();
}

class _TimeDisplayerState extends State<_TimeDisplayer> {
  @override
  void initState() {
    super.initState();

    final gm = GameManager.instance;
    gm.onGameTicked.listen(refresh);
  }

  @override
  void dispose() {
    final gm = GameManager.instance;
    gm.onGameTicked.cancel(refresh);

    super.dispose();
  }

  void refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final gm = GameManager.instance;
    final tm = ThemeManager.instance;

    return Text(
        gm.timeRemaining.inSeconds > 0
            ? 'Temps restant ${gm.timeRemaining.inSeconds}'
            : 'Arrivée en gare',
        style: tm.textFrontendSc);
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
    gm.onLetterProblemChanged.listen(_refresh);
  }

  @override
  void dispose() {
    final gm = GameManager.instance;
    gm.onLetterProblemChanged.cancel(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return GameManager.instance.problem == null
        ? Container()
        : LetterDisplayerCommon(letterProblem: GameManager.instance.problem!);
  }
}

class _TextInput extends StatefulWidget {
  const _TextInput({required this.onFocusChanged});

  final ValueChanged<bool> onFocusChanged;

  @override
  State<_TextInput> createState() => _TextInputState();
}

class _TextInputState extends State<_TextInput> {
  late final FocusNode _focusNode = FocusNode()
    ..addListener(() => widget.onFocusChanged(_focusNode.hasFocus));
  late final TextEditingController _controller = TextEditingController()
    ..addListener(() {
      _controller.value = _controller.value.copyWith(
        text: _controller.text.toUpperCase(),
        selection: _controller.selection,
        composing: TextRange.empty,
      );
      setState(() {});
    });

  void _onSendPressed() {
    final text = _controller.text;
    _controller.clear();

    TwitchManager.instance.tryWord(text);
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tm = ThemeManager.instance;

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            decoration: InputDecoration(
              enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white)),
              focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white)),
              fillColor: Colors.white,
              labelText: 'Tenter une réponse',
              labelStyle: tm.textFrontendSc,
            ),
            onSubmitted: (value) => _onSendPressed(),
            cursorColor: Colors.white,
            style: tm.textInputFrontend.copyWith(letterSpacing: 5.0),
          ),
        ),
        Stack(
          alignment: Alignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5.0),
              child: IconButton(
                  onPressed:
                      _controller.text.isNotEmpty ? _onSendPressed : null,
                  icon: Icon(
                    Icons.send,
                    color: _controller.text.isNotEmpty
                        ? Colors.white
                        : Colors.grey,
                  )),
            ),
            const _CooldownClock(withTitle: false),
          ],
        ),
      ],
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
    gm.onPardonnersChanged.listen(_updatePlayersWhoCanPardon);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updatePlayersWhoCanPardon();
    });
  }

  @override
  void dispose() {
    final gm = GameManager.instance;
    gm.onPardonnersChanged.cancel(_updatePlayersWhoCanPardon);

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
    return FittedBox(
      fit: BoxFit.fitWidth,
      child: SizedBox(
        height: 40,
        child: FittedBox(
          fit: BoxFit.fitHeight,
          child: ThemedElevatedButton(
            onPressed: _canPlayerPardon ? _onPardonPressed : null,
            buttonText: 'Pardon',
          ),
        ),
      ),
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
    gm.onBoostAvailabilityChanged.listen(_updateBoostAvailability);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateBoostAvailability();
    });
  }

  @override
  void dispose() {
    final gm = GameManager.instance;
    gm.onBoostAvailabilityChanged.cancel(_updateBoostAvailability);

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
    return FittedBox(
      fit: BoxFit.fitWidth,
      child: SizedBox(
        height: 40,
        child: FittedBox(
          fit: BoxFit.fitHeight,
          child: ThemedElevatedButton(
            onPressed: _canPlayerBoost ? _onBoostPressed : null,
            buttonText: 'Boost',
          ),
        ),
      ),
    );
  }
}

class _ChangeLaneRequest extends StatelessWidget {
  const _ChangeLaneRequest();

  void _onChangeLanePressed() async =>
      await GameManager.instance.requestChangeLane();

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.fitWidth,
      child: SizedBox(
        height: 40,
        child: FittedBox(
          fit: BoxFit.fitHeight,
          child: ThemedElevatedButton(
            onPressed: _onChangeLanePressed,
            buttonText: 'Changer de voie',
          ),
        ),
      ),
    );
  }
}

class _CooldownClock extends StatefulWidget {
  const _CooldownClock({required this.withTitle});

  final bool withTitle;

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
    gm.onNewCooldowns.listen(_showCooldown);

    _showCooldown();
  }

  @override
  void dispose() {
    final gm = GameManager.instance;
    gm.onNewCooldowns.cancel(_showCooldown);
    super.dispose();
  }

  void _showCooldown() {
    final cooldowns = GameManager.instance.newCooldowns;
    if (!cooldowns.keys.contains(TwitchManager.instance.userId)) return;
    _logger.info('Showing the player cooldown');

    _cooldownDuration = cooldowns[TwitchManager.instance.userId]!;
    _cooldownRemaining = _cooldownDuration;

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

  bool get _isOnCooldown => _cooldownRemaining >= Duration.zero;

  @override
  Widget build(BuildContext context) {
    final tm = ThemeManager.instance;

    return LayoutBuilder(builder: (context, constraints) {
      return Visibility(
        visible: _isOnCooldown,
        maintainSize: true,
        maintainAnimation: true,
        maintainState: true,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.withTitle)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                      fit: BoxFit.fitWidth,
                      child: Text('Petite pause', style: tm.textFrontendSc)),
                  const SizedBox(width: 16),
                ],
              ),
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
    });
  }
}
