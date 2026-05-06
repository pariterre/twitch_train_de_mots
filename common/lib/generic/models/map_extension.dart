import 'dart:convert';

import 'package:crypto/crypto.dart';

extension MapExtension on Map {
  ///
  /// Value-based checksum of the game state. This must strickly be the same
  /// for the same game state.
  String checksum() {
    final jsonStr = jsonEncode(this);
    return sha256.convert(utf8.encode(jsonStr)).toString();
  }
}
