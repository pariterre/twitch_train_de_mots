import 'package:common/managers/theme_manager.dart';
import 'package:flutter/material.dart';
import 'package:frontend/managers/twitch_manager.dart';
import 'package:frontend/widgets/main_extension.dart';
import 'package:logging/logging.dart';

void main() async {
  Logger.root.onRecord.listen((record) {
    final message = 'TRAIN DE MOTS - ${record.time}: ${record.message}';
    debugPrint(message);
  });
  await TwitchManager.initialize(useMocker: true, useLocalEbs: false);
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeManager.initialize();

  runApp(const MainExtension(isFullScreen: false));
}
