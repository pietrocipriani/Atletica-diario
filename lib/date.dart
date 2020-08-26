import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';


/// utility class for manage [dates] only (no [times]) for equivalence simplicity
class Date {

  /// `dateTime` is the [date holder] for the current instance
  /// 
  /// time is setted to `"12:00:00.000Z"` to overcome TimeZone conversion errors
  final DateTime dateTime;

  /// base `constructor` from `year`, `month` and `day`
  Date(int year, [int month = 1, int day = 1])
      : dateTime = DateTime.utc(year, month, day, 12);
  
  /// `constructor` from `DateTime` ([time] is dropped)
  Date.fromDateTime(DateTime date)
      : this(date.toUtc().year, date.toUtc().month, date.toUtc().day);

  /// `constructor` from `TimeStamp` ([time] is dropped)
  Date.fromTimeStamp(Timestamp timestamp)
      : this.fromDateTime(timestamp.toDate());
  
  /// creates an instance referred to [current day]
  Date.now() : this.fromDateTime(DateTime.now());

  /// use to parse `formattedAsIdentifier`
  Date.parse(final String raw) : this.fromDateTime(DateTime.parse(raw+'T12:00:00Z'));

  /// operator to perform a comparison against `other`
  /// 
  /// if `other` is `DateTime` or `Timestamp`, [time] is not ignored
  bool operator >(dynamic other) {
    assert(other is Date || other is DateTime || other is Timestamp);
    if (other is Date) return dateTime.isAfter(other.dateTime);
    if (other is DateTime) return dateTime.isAfter(other);
    if (other is Timestamp) return dateTime.isAfter(other.toDate());
    return null;
  }

  /// see `DateTime.weekday` for informations
  int get weekday => dateTime.weekday;

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
    if (other is Date) return dateTime.isBefore(other.dateTime);
    if (other is DateTime) return dateTime.isBefore(other);
    if (other is Timestamp) return dateTime.isBefore(other.toDate());
    return null;
  }

  /// performs the addition of `days` days to current `Date`
  /// 
  /// returns a new instance
  Date operator +(int days) =>
      Date.fromDateTime(dateTime.add(Duration(days: days)));

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
        : other is Date ? other.dateTime : other.toDate();
    return dateTime.difference(date);
  }

  /// operator to perform a comparison against `other`
  /// 
  /// if `other` is `DateTime` or `Timestamp`, [time] is not ignored
  @override
  bool operator ==(dynamic other) {
    assert(other is Date || other is DateTime || other is Timestamp);
    if (other is Date) return dateTime.isAtSameMomentAs(other.dateTime);
    if (other is DateTime) return dateTime.isAtSameMomentAs(other);
    if (other is Timestamp) return dateTime.isAtSameMomentAs(other.toDate());
    return null;
  }

  /// override needed to accomplish `operator ==` requirements
  @override
  int get hashCode => hashList([dateTime]);

  /// returns current [Date] as `yyyymmdd`
  /// 
  /// useful as [identifier] in [firestore results] 
  String get formattedAsIdentifier {
    final String year = dateTime.year.toString().padLeft(4, '0');
    final String month = dateTime.month.toString().padLeft(2, '0');
    final String day = dateTime.day.toString().padLeft(2, '0');

    return '$year$month$day';
  }
}
