import 'package:common/blueberry_war/models/agent.dart';
import 'package:common/generic/models/generic_listener.dart';

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
    required super.maxVelocity,
    required super.radius,
    required super.mass,
    required super.coefficientOfFriction,
  });

  @override
  AgentType get agentType => AgentType.letter;

  @override
  Map<String, dynamic> serialize() => {
        'id': id,
        'agent_type': agentType.index,
        'position': position.serialize(),
        'velocity': velocity.serialize(),
        'max_velocity': maxVelocity,
        'radius': radius.serialize(),
        'mass': mass,
        'coefficient_of_friction': coefficientOfFriction,
        'shape': shape.index,
        'is_boss': isBoss,
        'problem_index': problemIndex,
        'letter': letter,
        'number_of_hits': _numberOfHits,
      };

  static LetterAgent deserialize(Map<String, dynamic> map) {
    return LetterAgent(
      id: map['id'] as int,
      isBoss: map['is_boss'] as bool,
      problemIndex: map['problem_index'] as int,
      letter: map['letter'] as String,
      position: Vector2Extension.deserialize(map['position']),
      velocity: Vector2Extension.deserialize(map['velocity']),
      maxVelocity: (map['max_velocity'] as num).toDouble(),
      radius: Vector2Extension.deserialize(map['radius']),
      mass: (map['mass'] as num).toDouble(),
      coefficientOfFriction: (map['coefficient_of_friction'] as num).toDouble(),
    );
  }
}
