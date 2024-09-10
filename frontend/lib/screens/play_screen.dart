import 'package:common/widgets/themed_elevated_button.dart';
import 'package:flutter/material.dart';
import 'package:frontend/managers/game_manager.dart';
import 'package:frontend/managers/twitch_manager.dart';
import 'package:logging/logging.dart';

final _logger = Logger('PlayScreen');

class PlayScreen extends StatefulWidget {
  const PlayScreen({super.key});

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
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
    final isSuccess = await TwitchManager.instance.pardonStealer();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
          isSuccess ? 'Pardon request successful' : 'Pardon request failed'),
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ThemedElevatedButton(
          onPressed: _canPlayerPardon ? _onPardonPressed : null,
          buttonText: 'Pardon',
        ),
      ],
    ));
  }
}
