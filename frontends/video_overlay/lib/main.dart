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
    useTwitchEbsMocker: const bool.fromEnvironment('USE_TWITCH_EBS_MOCKER',
        defaultValue: false),
    useMockerAuthenticator: const bool.fromEnvironment(
        'USE_MOCKER_AUTHENTICATOR',
        defaultValue: false),
    useLocalEbs:
        const bool.fromEnvironment('USE_LOCAL_EBS', defaultValue: false),
  );
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MainExtension(
    isFullScreen: false,
    isMobile: false,
    showTextInput: false,
    alwaysOpaque: true,
    canBeHidden: true,
  ));
}
