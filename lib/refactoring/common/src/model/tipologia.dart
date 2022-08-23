import 'package:atletica/refactoring/common/common.dart';
import 'package:atletica/refactoring/utils/duration.dart';
import 'package:atletica/results/result.dart';
import 'package:atletica/ripetuta/time_pattern.dart';

/* class _RegularExpressions {
  static final RegExp time = RegExp("^\\s*\\d+\\s*(('\\s*([0-5]?\\d\\s*)?)?(\"\\s*\\d?\\d?|\\.\\d\\d?\\s*\"?))?\\s*\$");
  static final RegExp integer = RegExp(r'^\d+$');
  static final RegExp real = RegExp(r'^\d+(.\d+)?$');
} */

/*
^\s*\d+\s*('\s*([0-5]?\d\s*"\s*\d?\d?)$
*/

/// [Tipologia] for [Target]s and [Result]s.
///
/// Manages how to display, parse and validate [Target]s and [Result]s
enum Tipologia {
  corsaDist,
  corsaTime;

  // TODO: migrate method in the control section as extension?
  String get name {
    switch (this) {
      case Tipologia.corsaDist:
        return 'corsa';
      case Tipologia.corsaTime:
        return 'corsa a tempo';
    }
  }

  String formatTarget(final ResultValue? target) {
    if (target == null) return '';
    switch (this) {
      case Tipologia.corsaDist:
        return target.join(
          (duration) => duration.formatted,
          (distance) => throw ArgumentError.value(target.runtimeType, 'target', 'Unexpected target for this Tipologia'),
        );
      case Tipologia.corsaTime:
        return target.join(
          (duration) => '${duration.formatted}/km',
          (distance) => distance.toString(),
        );
    }
  }

  bool validateTarget(final String? s) {
    switch (this) {
      case Tipologia.corsaDist:
        return matchTimePattern(s);
      case Tipologia.corsaTime:
        return matchTimePattern(s, false, true); // TODO: validate distance
    }
  }

  String get targetExample {
    switch (this) {
      case Tipologia.corsaDist:
        return 'es: 1\'20"50';
      case Tipologia.corsaTime:
        return 'es 4\'30"';
    }
  }

  String? get targetSuffix {
    switch (this) {
      case Tipologia.corsaDist:
      case Tipologia.corsaTime:
        return null;
    }
  }

  ResultValue? parseTarget(String target) {
    return ResultValue.durationNullable(parseTimePattern(target)); // TODO: parse distance
  }

  static Tipologia parse(final String? raw) {
    if (raw == null) return Tipologia.corsaDist;
    for (final Tipologia t in values) if (t.name == raw) return t;
    return Tipologia.corsaDist;
  }

  /* static final Tipologia palestra = Tipologia(
    name: 'palestra',
    icon: ({color}) => Icon(
      Mdi.weightLifter,
      color: color,
    ),
    targetFormatter: (target) => target?.toStringAsFixed(0) ?? '',
    targetValidator: (s) => s == null ? false : RegularExpressions.integer.hasMatch(s),
    targetScheme: 'es: 40 kg',
    targetSuffix: 'kg',
    targetParser: (target) => double.parse(target),
  );
  static final Tipologia esercizi = Tipologia(
    name: 'esercizi',
    icon: ({color}) => Icon(Mdi.yoga, color: color ?? Colors.black),
    targetFormatter: (target) => target?.toStringAsFixed(0) ?? '',
    targetValidator: (s) => s == null ? false : RegularExpressions.integer.hasMatch(s),
    targetScheme: 'es: 20x',
    targetSuffix: 'x',
    targetParser: (target) => double.parse(target),
  ); */
}
