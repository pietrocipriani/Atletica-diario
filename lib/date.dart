import 'package:cloud_firestore/cloud_firestore.dart';

/// utility class for manage [dates] only (no [times]) for equivalence simplicity
/// `dateTime` is the [date holder] for the current instance
///
/// time is setted to `"12:00:00.000Z"` to overcome TimeZone conversion errors
class Date extends DateTime {
  /// base `constructor` from `year`, `month` and `day`
  Date(int year, [int month = 1, int day = 1])
      : super.utc(year, month, day, 12);

  /// `constructor` from `DateTime` ([time] is dropped)
  Date.fromDateTime(DateTime date)
      : this(date.toUtc().year, date.toUtc().month, date.toUtc().day);

  /// `constructor` from `TimeStamp` ([time] is dropped)
  Date.fromTimeStamp(Timestamp timestamp)
      : this.fromDateTime(timestamp.toDate());

  /// creates an instance referred to [current day]
  Date.now() : this.fromDateTime(DateTime.now());

  /// use to parse `formattedAsIdentifier`
  Date.parse(final String raw)
      : this.fromDateTime(DateTime.parse(raw + 'T12:00:00Z'));

  /// operator to perform a comparison against `other`
  ///
  /// if `other` is `DateTime` or `Timestamp`, [time] is not ignored
  bool operator >(dynamic other) {
    assert(other is Date || other is DateTime || other is Timestamp);
    if (other is Date) return isAfter(other);
    if (other is DateTime) return isAfter(other);
    if (other is Timestamp) return isAfter(other.toDate());
    throw StateError('cannot compare Date to ${other.runtimeType}');
  }

  /// see `DateTime.weekday` for informations
  int get weekday => weekday;

  /// operator to perform a comparison against `other`
  ///
  /// if `other` is `DateTime` or `Timestamp`, [time] is not ignored
  bool operator >=(dynamic other) => this > other || this == other;

  /// operator to perform a comparison against `other`
  ///
  /// if `other` is `DateTime` or `Timestamp`, [time] is not ignored
  bool operator <=(dynamic other) => this < other || this == other;

  /// operator to perform a comparison against `other`
  ///
  /// if `other` is `DateTime` or `Timestamp`, [time] is not ignored
  bool operator <(dynamic other) {
    assert(other is Date || other is DateTime || other is Timestamp);
    if (other is Date) return isBefore(other);
    if (other is DateTime) return isBefore(other);
    if (other is Timestamp) return isBefore(other.toDate());
    throw StateError('cannot compare Date to ${other.runtimeType}');
  }

  /// performs the addition of `days` days to current `Date`
  ///
  /// returns a new instance
  Date operator +(int days) => Date.fromDateTime(add(Duration(days: days)));

  /// if `other` is an `int`, returns the date before `other` days to `this`
  ///
  /// if `other` is a `Date` it returns the corrispective `Duration` to the difference
  dynamic operator -(dynamic other) {
    assert(other is int ||
        other is Date ||
        other is DateTime ||
        other is Timestamp);
    if (other is int) return this + (-other);
    final DateTime date = other is DateTime
        ? other
        : other is Date
            ? other
            : other.toDate();
    return difference(date);
  }

  /// operator to perform a comparison against `other`
  ///
  /// if `other` is `DateTime` or `Timestamp`, [time] is not ignored
  @override
  bool operator ==(dynamic other) {
    assert(other is Date || other is DateTime || other is Timestamp);
    if (other is Date) return isAtSameMomentAs(other);
    if (other is DateTime) return isAtSameMomentAs(other);
    if (other is Timestamp) return isAtSameMomentAs(other.toDate());
    throw StateError('cannot compare Date to ${other.runtimeType}');
  }

  // override needed to accomplish `operator ==` requirements
  @override
  int get hashCode => super.hashCode;

  /// returns current [Date] as `yyyymmdd`
  ///
  /// useful as [identifier] in [firestore results]
  String get formattedAsIdentifier {
    final String y = year.toString().padLeft(4, '0');
    final String m = month.toString().padLeft(2, '0');
    final String d = day.toString().padLeft(2, '0');

    return '$y$m$d';
  }
}
