import 'package:atletica/refactoring/model/result_value.dart';
import 'package:atletica/refactoring/utils/distance.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sealed_unions/sealed_unions.dart';

class Target {
  Target.empty()
      : this(Map.fromIterable(
          // assert every targetCategory is inserted
          TargetCategory.values,
          key: (c) => c,
          value: (c) => Rx<ResultValue?>(null),
        ));
  Target.from(final Target other) : this(other._targets);
  Target(final Map<TargetCategory, Rx<ResultValue?>> targets) : _targets = Map.unmodifiable(targets);

  factory Target.parse(final object) {
    if (object is Map<String, Object?>) return Target.parseMap(object);
    if (object is num?) return Target.parseDouble(object?.toDouble());
    throw ArgumentError.value(object, 'object', 'unparsable type: ${object.runtimeType}');
  }

  Target.parseMap(final Map<String, Object?> map)
      : this(Map.fromIterable(
          // assert every targetCategory is inserted
          TargetCategory.values,
          key: (c) => c,
          value: (c) => _asObject(map[c.name] as int?).obs,
        ));

  // legacy
  Target.parseDouble(final double? value)
      : this(Map.fromIterable(
          // assert every targetCategory is inserted
          TargetCategory.values,
          key: (c) => c,
          value: (c) => (value == null ? null : Duration(milliseconds: (value * 1000).toInt())).obs,
        ));

  final Map<TargetCategory, Rx<ResultValue?>> _targets;

  /// returns the target related to `category`. Possible types: [Duration] & [Distance]
  ResultValue? operator [](final TargetCategory category) => _targets[category]!.value;

  /// sets the target. `value` must be of type [Duration] or [Distance]
  void operator []=(final TargetCategory category, final ResultValue? value) {
    _targets[category]!.value = value;
  }

  void setAll(final ResultValue? value) {
    for (final TargetCategory category in TargetCategory.values) {
      _targets[category]!.value = value;
    }
  }

  /// returs if there is no category differentation
  bool get isUnified {
    final ResultValue? target = this[TargetCategory.values.first];
    return _targets.values.every((e) => e.value == target);
  }

  void copy(final Target? other) {
    for (final TargetCategory category in TargetCategory.values) this[category] = other?[category];
  }

  void copyWhereNonNull(final Target other) {
    for (final TargetCategory category in TargetCategory.values) {
      final ResultValue? target = other[category];
      if (target != null) this[category] = target;
    }
  }

  // TODO: this is a non-scalable solution
  static int? _asInt(final ResultValue? target) {
    return target?.join(
      (duration) => duration.inMilliseconds,
      (distance) => ~distance.inMeters,
    );
  }

  static ResultValue? _asObject(final int? target) {
    if (target == null) return null;
    if (target >= 0) return ResultValue.duration(Duration(milliseconds: target));
    return ResultValue.distance(Distance(meters: ~target));
  }

  Map<String, int?> get asMap => _targets.map((key, value) => MapEntry(key.name, _asInt(value.value)));
}

enum TargetCategory {
  males,
  females;

  Color get color {
    switch (this) {
      case males:
        return Colors.cyan;
      case females:
        return Colors.pink;
    }
  }
}
