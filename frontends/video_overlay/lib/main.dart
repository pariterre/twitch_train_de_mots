import 'package:flutter/material.dart';
import 'package:frontend_common/managers/twitch_manager.dart';
import 'package:frontend_common/widgets/main_extension.dart';
import 'package:logging/logging.dart';

void main() async {
  Logger.root.onRecord.listen((record) {
    final message = 'TRAIN DE MOTS - ${record.time}: ${record.message}';
    debugPrint(message);
  });
  await TwitchManager.initialize(
      useMocker: false, useMockerAuthenticator: false, useLocalEbs: false);
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MainExtension(
    isFullScreen: false,
    alwaysOpaque: true,
    canBeHidden: true,
  ));
}
