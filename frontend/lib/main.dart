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

  if (_useTwitchProvider) {
    await TwitchIntegrationManager.initialize(
      useEbsMock:
          const bool.fromEnvironment('USE_EBS_MOCK', defaultValue: false),
      useTwitchAuthenticatorMock: const bool.fromEnvironment(
          'USE_TWITCH_AUTHENTICATOR_MOCK',
          defaultValue: false),
      ebsUri: Uri.parse(useLocalEbs
          ? 'ws://localhost:3011'
          : 'wss://twitchserver.pariterre.net:3011'),
    );
  } else {
    await NoIntegrationManager.initialize(
      useEbsMock:
          const bool.fromEnvironment('USE_EBS_MOCK', defaultValue: false),
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

bool get _useTwitchProvider =>
    const bool.fromEnvironment('USE_TWITCH_PROVIDER', defaultValue: false);

TwitchIntegrationManager get _twitchIntegrationManager =>
    IntegrationManager.instance as TwitchIntegrationManager;

bool get _isFullScreen => _useTwitchProvider
    ? _twitchIntegrationManager.anchor != TwitchAnchor.overlay
    : true;

bool get _isMobile => _useTwitchProvider
    ? _twitchIntegrationManager.platform == TwitchPlatform.mobile
    : false;

bool get _showTextInput => _useTwitchProvider
    ? _twitchIntegrationManager.platform == TwitchPlatform.mobile
    : true;

bool get _alwaysOpaque => _useTwitchProvider
    ? _twitchIntegrationManager.anchor != TwitchAnchor.component
    : true;

bool get _canBeHidden => _useTwitchProvider
    ? _twitchIntegrationManager.anchor == TwitchAnchor.overlay
    : false;
