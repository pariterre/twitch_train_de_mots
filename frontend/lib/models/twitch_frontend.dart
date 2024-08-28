import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:js/js.dart';

import 'package:logging/logging.dart';

final _logger = Logger('TwitchFrontEnd.dart');

// Declare external JavaScript function and objects
@JS('Twitch.ext')
external TwitchExt get twitchExt;

@JS()
@anonymous
class Auth {
  external String get channelId;
  external String get clientId;
  external String get token;
  external String get helixToken;
  external String get userId;
}

// Define the Twitch Extension JavaScript API
@JS()
@anonymous
class TwitchExt {
  external void onAuthorized(Function(Auth auth) callback);
}

class TwitchFrontend {
  // Initialize the TwitchFrontEnd singleton
  static final TwitchFrontend _instance = TwitchFrontend._internal();
  static TwitchFrontend get instance {
    if (!_instance._isInitialized) {
      throw Exception('TwitchFrontend is not initialized');
    }
    return _instance;
  }

  TwitchFrontend._internal() {
    // Register the onAuthorized callback
    twitchExt.onAuthorized(allowInterop(_onAuthorizedCallback));
  }
  static void initialize({required Uri ebsUri}) {
    _instance._isInitialized = true;
  }

  // Internal state
  bool _isInitialized = false;
  bool _isAuthorized = false;

  // Information needed to make requests to the backend
  String? _ebsUri;
  String get ebsUri => _ebsUri!;

  String? _channelId;
  String get channelId => _channelId!;

  String? _clientId;
  String get clientId => _clientId!;

  String? _token;
  String get token => _token!;

  String? _helixToken;
  String get helixToken => _helixToken!;

  String? _userId;
  String get userId => _userId!;

  // Define the callback function
  void _onAuthorizedCallback(Auth auth) {
    _logger.info('Received auth token');
    _channelId = auth.channelId;
    _clientId = auth.clientId;
    _token = auth.token;
    _helixToken = auth.helixToken;
    _userId = auth.userId;

    try {
      _registerToEbs();
      _isAuthorized = true;
    } catch (e) {
      _logger.severe('Error registering to EBS: $e');
      _channelId = null;
      _clientId = null;
      _token = null;
      _helixToken = null;
      _userId = null;
      _isAuthorized = false;
    }
  }

  void _registerToEbs() async {
    // Making a simple GET request with the bearer token
    _sendGetRequestToEbs(Uri.parse('$ebsUri/initialize'));
  }

  Future<Map<String, dynamic>> _sendGetRequestToEbs(Uri endpoint) async {
    // Making a simple GET request with the bearer token
    try {
      final response = await http.get(endpoint, headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });

      if (response.statusCode == 200) {
        _logger.info('Successully connected to the server');
        return json.decode(response.body);
      } else {
        _logger.severe('Request failed with status: ${response.statusCode}');
        throw Exception('Request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      _logger.severe('Error making request: $e');
      throw Exception('Error making request: $e');
    }
  }
}
