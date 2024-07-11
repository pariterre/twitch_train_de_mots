class Range {
  final int min;
  final int max;

  Range(this.min, this.max) {
    if (min < 0 || max < 0) {
      throw ArgumentError('The range should be positive');
    } else if (min > max) {
      throw ArgumentError(
          'The minimum value should be less than the maximum value');
    }
  }

  bool contains(int value) => value >= min && value <= max;
}
