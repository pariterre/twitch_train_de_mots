import 'package:train_de_mots/blueberry_war/models/agent.dart';
import 'package:train_de_mots/blueberry_war/to_remove/generic_listener.dart';

class LetterAgent extends Agent {
  final bool isBoss;
  int problemIndex;
  String letter;
  DateTime _lastHitTime = DateTime.now();

  final onHit = GenericListener<Function>();

  int _numberOfHits = 0;
  void hit() {
    // Prevent hitting too frequently
    if (DateTime.now().difference(_lastHitTime).inMilliseconds < 500) {
      return;
    }
    _lastHitTime = DateTime.now();

    if (isDestroyed) return;

    _numberOfHits++;
    onHit.notifyListeners((callback) => callback());
    if (isDestroyed) onDestroyed.notifyListeners((callback) => callback());
  }

  bool get isWeak => _numberOfHits == 1;
  @override
  bool get isDestroyed => _numberOfHits >= 2;

  @override
  AgentShape get shape => AgentShape.rectangle;

  LetterAgent({
    required super.id,
    required this.isBoss,
    required this.problemIndex,
    required this.letter,
    required super.position,
    required super.velocity,
    required super.radius,
    required super.mass,
    required super.coefficientOfFriction,
  });
}
