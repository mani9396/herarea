class DistanceFormatter {
  /// Formats a distance in kilometers to a consistent string format with 1 decimal place.
  /// Example: 2.68060800172096 -> "2.7 km away"
  static String format(double distanceKm) {
    return '${distanceKm.toStringAsFixed(1)} km away';
  }
}
