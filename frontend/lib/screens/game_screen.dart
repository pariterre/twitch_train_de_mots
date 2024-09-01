import 'package:flutter/material.dart';
import 'package:frontend/managers/twitch_manager.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Train de mots!'),
      ),
      body: FutureBuilder(
          future: TwitchManager.instance.onHasConnectedToEbs,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            return Center(
                child: ElevatedButton(
              onPressed: () async {
                final success = await TwitchManager.instance.pardonStealer();
                if (!context.mounted) return;

                // Show a snackbar with the result
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(success
                      ? 'Le voleur a été pardonné!'
                      : 'Le voleur n\'a pas été pardonné!'),
                ));
              },
              child: const Text('Pardon'),
            ));
          }),
    );
  }
}
