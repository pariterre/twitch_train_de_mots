import 'dart:async';

import 'package:common/models/ebs_helpers.dart';
import 'package:logging/logging.dart';
import 'package:twitch_manager/twitch_manager.dart' as tm;

final _logger = Logger('TwitchManagerMain');

class TwitchManager {
  ///
  /// Flag to check if the frontend is connected to the EBS. This is used to
  /// prevent the programmer from calling the methods before the Twitch
  /// frontend has connected to the EBS. If ones need to know when the
  /// frontend has connected to the EBS, they can listen to the
  /// [onHasConnectedToEbs] stream.
  bool _isConnectedToEbs = false;
  final _hasConnectedToEbsCompleter = Completer<bool>();
  Future<bool> get onHasConnectedToEbs => _hasConnectedToEbsCompleter.future;

  ///
  /// Interface reference to the TwitchFrontendManager.
  tm.TwitchFrontendManager? _frontendManager;

  ///
  /// Declare the singleton instance of the TwitchManager, calling this method
  /// automatically initializes the TwitchManager. However, ones is encouraged
  /// to call [TwitchManager.initialize()] before using the TwitchManager to make
  /// sure that the TwitchManager is configured correctly.
  static final _instance = TwitchManager._();
  static TwitchManager get instance => _instance;
  TwitchManager._() {
    tm.TwitchFrontendManager.factory(
      appInfo: tm.TwitchFrontendInfo(
        appName: 'Train de mots',
        ebsUri: Uri.parse('http://localhost:3010/frontend'),
      ),
      onHasConnectedCallback: () async {
        _logger.info('Connected to Twitch');
        _isConnectedToEbs = true;
        _hasConnectedToEbsCompleter.complete(_isConnectedToEbs);
      },
      pubSubCallback: (message) {
        _logger.info('Received message: $message');
      },
    ).then((manager) => _frontendManager = manager);
  }

  ///
  /// Post a request to pardon the stealer. The EBS answer OK if the user can
  /// pardon said stealer.
  Future<bool> pardonStealer() async {
    if (!_isInitialized) {
      _logger.severe('TwitchManager is not initialized');
      throw Exception('TwitchManager is not initialized');
    }

    final response = await _frontendManager!.apiToEbs.post(
        FrontendHttpPostEndpoints.pardon.toString(),
        {'message': 'Pardon my stealer'});
    return response['response'] == 'OK';
  }

  bool get _isInitialized {
    // If the programmer forgets to call TwitchManager.initialize()
    if (_frontendManager == null) return false;

    // If the programmer calls the pardon method before the TwitchManager has connected
    if (!_isConnectedToEbs) return false;

    return true;
  }

  // Initialize the TwitchManager
  static Future<void> initialize() async => instance;
}
