import 'package:atletica/refactoring/common/common.dart';
import 'package:atletica/refactoring/utils/distance.dart';
import 'package:sealed_unions/sealed_unions.dart';

/// Union type for possible types of values for results / targets
class ResultValue extends Union2Impl<Duration, Distance> implements Comparable<ResultValue> {
  static const Doublet<Duration, Distance> _factory = Doublet();

  factory ResultValue.duration(final Duration duration) => ResultValue._(_factory.first(duration));
  factory ResultValue.distance(final Distance distance) => ResultValue._(_factory.second(distance));

  @deprecated
  static ResultValue? parseLegacy(final double? value) {
    if (value == null) return null;
    return ResultValue.durationNullable(Duration(milliseconds: (value * 1000).truncate()));
  }

  /// parses the value from the [int] (database) representation
  static ResultValue? parse(final int? value) {
    if (value == null) return null;
    if (value >= 0) return ResultValue.duration(Duration(milliseconds: value));
    return ResultValue.distance(Distance(meters: ~value));
  }

  static ResultValue? durationNullable(final Duration? duration) {
    if (duration == null) return null;
    return ResultValue.duration(duration);
  }

  static ResultValue? distanceNullable(final Distance? distance) {
    if (distance == null) return null;
    return ResultValue.distance(distance);
  }

  ResultValue._(final Union2<Duration, Distance> union) : super(union);

  /// Returns the value contained in this Union. [Object] is the last common ancestor for [Duration] and [Distance]
  Object get value => join((_) => _, (_) => _);

  /// checks whether two [ResultValue]s are equal. Uses [Duration] and [Distance] equality method
  @override
  bool operator ==(final Object other) {
    if (identical(this, other)) return true;
    if (runtimeType != other.runtimeType) return false;
    return other is ResultValue && value == other.value;
  }

  // TODO: this is a non-scalable solution
  /// returns an int representation for `this`. For database purpose
  int get asInt => join(
        (duration) => duration.inMilliseconds,
        (distance) => ~distance.inMeters,
      );

  /// returns the double representation of `value` for legacy value
  @deprecated
  double get asLegacy => join(
        (duration) => duration.inMilliseconds / 1000,
        (distance) => distance.inMeters.toDouble(),
      );

  @override
  int get hashCode => value.hashCode;

  @override
  int compareTo(final ResultValue other) {
    return join(
      (d1) {
        final d2 = other.value;
        if (d2 is! Duration) throw UnsupportedError('cannot perform comparison between Duration and Distance');
        return d1.compareTo(d2);
      },
      (d1) {
        final d2 = other.value;
        if (d2 is! Distance) throw UnsupportedError('cannot perform comparison between Duration and Distance');
        return d1.compareTo(d2);
      },
    );
  }

  bool operator <(final ResultValue other) => compareTo(other) < 0;
  bool operator <=(final ResultValue other) => compareTo(other) <= 0;
  bool operator >(final ResultValue other) => compareTo(other) > 0;
  bool operator >=(final ResultValue other) => compareTo(other) >= 0;
}

/// Union type with types of [ResultValue] or [Target]
class ResultValueOrTarget extends Union3Impl<Duration, Distance, Target> {
  static const Triplet<Duration, Distance, Target> _factory = Triplet();

  factory ResultValueOrTarget.resultValue(final ResultValue value) => value.join(
        (duration) => ResultValueOrTarget.duration(duration),
        (distance) => ResultValueOrTarget.distance(distance),
      );
  factory ResultValueOrTarget.duration(final Duration duration) => ResultValueOrTarget._(_factory.first(duration));
  factory ResultValueOrTarget.distance(final Distance distance) => ResultValueOrTarget._(_factory.second(distance));
  factory ResultValueOrTarget.target(final Target target) => ResultValueOrTarget._(_factory.third(target));

  static ResultValueOrTarget? durationNullable(final Duration? duration) {
    if (duration == null) return null;
    return ResultValueOrTarget.duration(duration);
  }

  static ResultValueOrTarget? distanceNullable(final Distance? distance) {
    if (distance == null) return null;
    return ResultValueOrTarget.distance(distance);
  }

  static ResultValueOrTarget? targetNullable(final Target? target) {
    if (target == null) return null;
    return ResultValueOrTarget.target(target);
  }

  static ResultValueOrTarget? resultValueNullable(final ResultValue? value) {
    if (value == null) return null;
    return ResultValueOrTarget.resultValue(value);
  }

  ResultValueOrTarget._(final Union3<Duration, Distance, Target> union) : super(union);

  Object get value => join((_) => _, (_) => _, (_) => _);

  @override
  bool operator ==(final Object other) {
    if (identical(this, other)) return true;
    if (runtimeType != other.runtimeType) return false;
    return other is ResultValue && value == other.value;
  }

  @override
  int get hashCode => value.hashCode;
}
