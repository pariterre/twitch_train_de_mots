class SerializableBlueberryWarGameState {
  //implements SerializableMiniGameState {
  SerializableBlueberryWarGameState();

  Map<String, dynamic> serialize() {
    return {};
  }

  static SerializableBlueberryWarGameState deserialize(
    Map<String, dynamic> data,
  ) {
    return SerializableBlueberryWarGameState();
  }

  SerializableBlueberryWarGameState copyWith() {
    return SerializableBlueberryWarGameState();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SerializableBlueberryWarGameState;
  }

  @override
  int get hashCode => 1.hashCode;
}
