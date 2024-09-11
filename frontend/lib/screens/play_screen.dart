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
        Header(titleText: 'Le train est en route!\n' 'Bon voyage!'),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Pardon(),
            ],
          ),
        ),
      ],
    ));
  }
}

class _Pardon extends StatefulWidget {
  const _Pardon();

  @override
  State<_Pardon> createState() => _PardonState();
}

class _PardonState extends State<_Pardon> {
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

  void _updatePlayersWhoCanPardon(List<String> pardonners) {
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
