import 'package:web/web.dart';

class AudioContextWrapper {
  final _context = AudioContext();

  String get state => _context.state;
}
