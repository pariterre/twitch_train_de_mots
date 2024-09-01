import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:http/http.dart' as http;

class _Bearer {
  final String token;
  final DateTime expiration;

  _Bearer(this.token, {required this.expiration});

  bool get isExpired => DateTime.now().isAfter(expiration);
}

void initialize({
  required String broadcasterId,
  required String extensionId,
  required String extensionVersion,
  required String extensionSecret,
  required String sharedSecret,
}) {
  TwitchManagerExtension._internal(
    broadcasterId: broadcasterId,
    extensionId: extensionId,
    extensionVersion: extensionVersion,
    extensionSecret: extensionSecret,
    sharedSecret: sharedSecret,
  );
}

class TwitchManagerExtension {
  // Prepare the singleton instance
  static TwitchManagerExtension? _instance;
  static TwitchManagerExtension get instance {
    if (_instance == null) {
      throw Exception(
          'TwitchManagerExtension is not initialized, call initialize() first');
    }
    return _instance!;
  }

  static Future<void> initialize({
    required String broadcasterId,
    required String extensionId,
    required String extensionVersion,
    required String extensionSecret,
    required String sharedSecret,
  }) async {
    if (_instance != null) {
      throw Exception('TwitchManagerExtension is already initialized');
    }

    _instance = TwitchManagerExtension._internal(
      broadcasterId: broadcasterId,
      extensionId: extensionId,
      extensionVersion: extensionVersion,
      extensionSecret: extensionSecret,
      sharedSecret: sharedSecret,
    );
  }

  TwitchManagerExtension._internal({
    required this.broadcasterId,
    required this.extensionId,
    required this.extensionVersion,
    required this.extensionSecret,
    required this.sharedSecret,
  });

  final String broadcasterId;

  final String extensionId;
  final String extensionVersion;
  final String? extensionSecret;

  _Bearer? _extensionBearer;
  Future<String> _getExtensionBearerToken() async {
    if (extensionSecret == null) {
      throw ArgumentError('Extension secret is required, please generate one '
          'from the Twitch developer console');
    }

    if (_extensionBearer == null) {
      final response =
          await http.post(Uri.https('id.twitch.tv', 'oauth2/token'), body: {
        'client_id': extensionId,
        'client_secret': extensionSecret,
        'grant_type': 'client_credentials',
      });
      final data = json.decode(response.body);
      _extensionBearer = _Bearer(data['access_token'],
          expiration:
              DateTime.now().add(Duration(seconds: data['expires_in'])));
    }
    return _extensionBearer!.token;
  }

  Future<Uri> getAuthorizationExtensionBearerUri() async {
    // Generate a random 16-bigs hexadecimal state
    final state = List.generate(16, (index) => Random().nextInt(16))
        .map((e) => e.toRadixString(16))
        .join();

    final authorizationUrl = Uri.https('id.twitch.tv', 'oauth2/authorize', {
      'response_type': 'code',
      'client_id': extensionId,
      'redirect_uri': 'https://localhost',
      'scope': 'user:write:chat user:bot',
      'state': state,
    });

    // TODO Connect to the backend to get the code using an http get request
    // This should be done in the config page of the extension
    print('Navigate to the following URL to authorize the extension:');
    print(authorizationUrl);

    return authorizationUrl;
  }

  final String sharedSecret;
  _Bearer? _sharedBearerToken;
  Future<String> _getSharedBearerToken() async {
    if (_sharedBearerToken == null || _sharedBearerToken!.isExpired) {
      final jwt = JWT({
        'user_id': broadcasterId,
        'role': 'external',
        'exp': (DateTime.now().add(Duration(days: 1))).millisecondsSinceEpoch,
        'channel_id': broadcasterId,
        'pubsub_perms': {
          'send': ['broadcast']
        }
      });
      _sharedBearerToken = _Bearer(
          jwt.sign(SecretKey(sharedSecret, isBase64Encoded: true),
              expiresIn: Duration(days: 1)),
          expiration: DateTime.now().add(Duration(days: 1)));
    }
    return _sharedBearerToken!.token;
  }

  Future<void> sendChatMessage(String message,
      {bool sendUnderExtensionName = true}) async {
    if (sendUnderExtensionName) {
      await _postApiRequest(
        endPoint: 'helix/extensions/chat',
        queryParameters: {'broadcaster_id': broadcasterId},
        body: {
          'text': message,
          'extension_id': extensionId,
          'extension_version': extensionVersion,
        },
      );
    } else {
      await _postExtensionRequest(
        endPoint: 'helix/chat/messages',
        queryParameters: {'broadcaster_id': broadcasterId},
        body: {
          'message': message,
          'broadcaster_id': broadcasterId,
          'sender_id': broadcasterId,
        },
      );
    }
  }

  Future<void> sendExtentionMessage(String message) async {
    await _postApiRequest(
      endPoint: 'helix/extensions/pubsub',
      body: {
        'message': message,
        'broadcaster_id': broadcasterId,
        'target': ['broadcast']
      },
    );
  }

  JWT verifyAndDecode(String jwt) {
    return JWT.verify(jwt, SecretKey(sharedSecret, isBase64Encoded: true));
  }

  Future<bool> _postApiRequest({
    required String endPoint,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? body,
  }) async {
    final bearer = await _getSharedBearerToken();

    final response =
        await http.post(Uri.https('api.twitch.tv', endPoint, queryParameters),
            headers: <String, String>{
              HttpHeaders.authorizationHeader: 'Bearer $bearer',
              'Client-Id': extensionId,
              HttpHeaders.contentTypeHeader: 'application/json',
            },
            body: json.encode(body));

    return response.statusCode == 204;
  }

  Future<bool> _postExtensionRequest({
    required String endPoint,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? body,
  }) async {
    final response =
        await http.post(Uri.https('api.twitch.tv', endPoint, queryParameters),
            headers: <String, String>{
              HttpHeaders.authorizationHeader:
                  'Bearer ${await _getExtensionBearerToken()}',
              'Client-Id': extensionId,
              HttpHeaders.contentTypeHeader: 'application/json',
            },
            body: json.encode(body));

    return response.statusCode == 204;
  }
}
