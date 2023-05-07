import 'package:atletica/refactoring/common/common.dart';
import 'package:atletica/refactoring/utils/cast.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Class for storing targets
class Target {
  Target.empty()
      : this(Map.fromIterable(
          // assert every targetCategory is inserted
          TargetCategory.values,
          key: (c) => c,
          value: (c) => Rx<ResultValue?>(null),
        ));

  /// copies another [Target]
  Target.from(final Target other) : this(other._targets);
  Target(final Map<TargetCategory, Rx<ResultValue?>> targets)
      : _targets = Map.unmodifiable(targets);

  /// Parses the [Target] from the database object. Support for legacy values
  factory Target.parse(final object) {
    if (object is Map<String, Object?>) return Target.parseMap(object);
    if (object is num?) return Target.parseDouble(object?.toDouble());
    throw ArgumentError.value(
        object, 'object', 'unparsable type: ${object.runtimeType}');
  }

  Target.parseMap(final Map<String, Object?> map)
      : this(Map.fromIterable(
          // assert every targetCategory is inserted
          TargetCategory.values,
          key: (c) => c,
          value: (c) {
            // dart dart dart... why couldn't you use generics?
            final category =
                cast<TargetCategory>(c, TargetCategory.defaultValue);
            return ResultValue.parse(cast<int?>(map[category.name], null)).obs;
          },
        ));

  @deprecated
  Target.parseDouble(final double? value)
      : this(Map.fromIterable(
          // assert every targetCategory is inserted
          TargetCategory.values,
          key: (c) => c,
          value: (c) =>
              (value == null ? null : ResultValue.parseLegacy(value)).obs,
        ));

  final Map<TargetCategory, Rx<ResultValue?>> _targets;

  /// returns the target related to `category`.
  ResultValue? operator [](final TargetCategory category) =>
      _targets[category]!.value;

  /// sets the target for the specified `category`
  void operator []=(final TargetCategory category, final ResultValue? value) {
    _targets[category]!.value = value;
  }

  /// sets the target for every [TargetCategory]
  void setAll(final ResultValue? value) {
    for (final TargetCategory category in TargetCategory.values) {
      _targets[category]!.value = value;
    }
  }

  /// returns if there is no category differentation
  bool get isUnified {
    final ResultValue? target = this[TargetCategory.values.first];
    return _targets.values.every((e) => e.value == target);
  }

  /// copies `other` in `this`
  ///
  /// if `other` is null `this` is emptied
  void copy(final Target? other) {
    for (final TargetCategory category in TargetCategory.values)
      this[category] = other?[category];
  }

  /// copies `other` in `this` for the non `null` categories
  void copyWhereNonNull(final Target other) {
    for (final TargetCategory category in TargetCategory.values) {
      final ResultValue? target = other[category];
      if (target != null) this[category] = target;
    }
  }

  /// returns a [Map] representation of `this` for the database
  Map<String, int?> get asMap =>
      _targets.map((key, value) => MapEntry(key.name, value.value?.asInt));
}

/// The categories for [Target]
// TODO: what about a 'generic' category? How is the usability then?
enum TargetCategory {
  males,
  females;

  static TargetCategory get defaultValue => males;

  String get code {
    switch (this) {
      case males:
        return 'M';
      case females:
        return 'F';
    }
  }

  // TODO: migrate in "view" section
  Color get color {
    switch (this) {
      case males:
        return Colors.cyan;
      case females:
        return Colors.pink.shade200;
    }
  }
}
