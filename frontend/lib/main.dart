import 'package:flutter/material.dart';
import 'package:frontend/managers/twitch_manager.dart';
import 'package:frontend/widgets/main_extension.dart';
import 'package:logging/logging.dart';

void main() async {
  Logger.root.onRecord.listen((record) {
    final message = 'TRAIN DE MOTS - ${record.time}: ${record.message}';
    debugPrint(message);
  });

  final useLocalEbs =
      const bool.fromEnvironment('USE_LOCAL_EBS', defaultValue: false);

  if (_useCodeToConnect) {
    // TODO
  } else {
    await TwitchManager.initialize(
      useEbsMock:
          const bool.fromEnvironment('USE_EBS_MOCK', defaultValue: false),
      useTwitchAuthenticatorMock: const bool.fromEnvironment(
          'USE_TWITCH_AUTHENTICATOR_MOCK',
          defaultValue: false),
      ebsUri: Uri.parse(useLocalEbs
          ? 'ws://localhost:3011'
          : 'wss://twitchserver.pariterre.net:3011'),
    );
  }
  WidgetsFlutterBinding.ensureInitialized();

  runApp(MainExtension(
    isFullScreen: _isFullScreen,
    isMobile: _isMobile,
    showTextInput: _showTextInput,
    alwaysOpaque: _alwaysOpaque,
    canBeHidden: _canBeHidden,
  ));
}

bool get _useBuildConfiguration =>
    const bool.fromEnvironment('USE_BUILD_CONFIGURATION', defaultValue: false);

bool get _isFullScreen => _useBuildConfiguration
    ? const bool.fromEnvironment('USE_IS_FULLSCREEN', defaultValue: true)
    : switch (TwitchManager.instance.anchor) {
        TwitchAnchor.overlay => false,
        _ => true
      };

bool get _isMobile => _useBuildConfiguration
    ? const bool.fromEnvironment('USE_IS_MOBILE', defaultValue: false)
    : switch (TwitchManager.instance.platform) {
        TwitchPlatform.mobile => true,
        _ => false,
      };

bool get _showTextInput => _useBuildConfiguration
    ? const bool.fromEnvironment('USE_SHOW_TEXT_INPUT', defaultValue: false)
    : _isMobile;

bool get _alwaysOpaque => _useBuildConfiguration
    ? const bool.fromEnvironment('USE_ALWAYS_OPAQUE', defaultValue: true)
    : switch (TwitchManager.instance.anchor) {
        TwitchAnchor.component => false,
        _ => true
      };

bool get _canBeHidden => _useBuildConfiguration
    ? const bool.fromEnvironment('USE_CAN_BE_HIDDEN', defaultValue: false)
    : switch (TwitchManager.instance.anchor) {
        TwitchAnchor.overlay => true,
        _ => false
      };

bool get _useCodeToConnect =>
    const bool.fromEnvironment('USE_CODE_TO_CONNECT', defaultValue: false);
