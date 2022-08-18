class Distance {
  static const int _milliInKilo = 1000 * 1000;
  static const int _milliInBase = 1000;
  static const Distance zero = Distance();

  /// the total millimeters of this [Distance]
  ///
  /// millimeters is the resolution of this class
  final int _distance;

  const Distance({
    final int kilometers = 0,
    final int meters = 0,
    final int millimeters = 0,
  }) : _distance = kilometers * _milliInKilo + meters * _milliInBase + millimeters;

  int get inKilometers => _distance ~/ _milliInKilo;
  int get inMeters => _distance ~/ _milliInBase;
  int get inMillimeters => _distance;

  @override
  String toString() {
    if (inKilometers >= 1) {
      if (inMeters % 1000 != 0) return '$inKilometers.${inMeters ~/ 100} km';
      return '$inKilometers km';
    }
    if (inMeters >= 1) return '$inMeters m';
    return '$_distance mm';
  }

  @override
  bool operator ==(final other) {
    if (identical(this, other)) return true;
    if (runtimeType != other.runtimeType) return false;
    return other is Distance && _distance == other._distance;
  }

  @override
  int get hashCode => _distance.hashCode;
}
