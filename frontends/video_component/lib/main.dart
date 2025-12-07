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
    useEbsMock: const bool.fromEnvironment('USE_EBS_MOCK', defaultValue: false),
    useTwitchAuthenticatorMock: const bool.fromEnvironment(
        'USE_TWITCH_AUTHENTICATOR_MOCK',
        defaultValue: false),
    useLocalEbs:
        const bool.fromEnvironment('USE_LOCAL_EBS', defaultValue: false),
  );
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MainExtension(
    isFullScreen: true,
    isMobile: false,
    showTextInput: false,
    alwaysOpaque: false,
    canBeHidden: false,
  ));
}
