import 'dart:math';

extension RandomExtension on Random {
  int nextSkewedInt({
    int min = 0,
    required int max,
    required int skewTowards,
    int stdWidthAdjustment = 6,
  }) {
    assert(min < max);
    assert(skewTowards >= min && skewTowards < max);

    final stdDev =
        (max - min) / stdWidthAdjustment; // Adjust for bell curve width

    double gaussian = nextGaussian() * stdDev + skewTowards;
    return gaussian.round().clamp(min, max - 1);
  }

  double nextGaussian() {
    // Box-Muller transform to generate a standard normal distribution
    final u1 = nextDouble();
    final u2 = nextDouble();
    final z0 = sqrt(-2.0 * log(u1)) * cos(2.0 * pi * u2);
    return z0;
  }
}
