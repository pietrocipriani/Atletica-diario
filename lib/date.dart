import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';

class Date {
  final DateTime dateTime;

  Date(int year, [int month = 1, int day = 1])
      : dateTime = DateTime.utc(year, month, day, 12);
  Date.fromDateTime(DateTime date)
      : this(date.toUtc().year, date.toUtc().month, date.toUtc().day);
  Date.fromTimeStamp(Timestamp timestamp)
      : this.fromDateTime(timestamp.toDate());
  Date.now() : this.fromDateTime(DateTime.now());
  Date.parse(final String raw) : this.fromDateTime(DateTime.parse(raw));

  bool operator >(dynamic other) {
    assert(other is Date || other is DateTime || other is Timestamp);
    if (other is Date) return dateTime.isAfter(other.dateTime);
    if (other is DateTime) return dateTime.isAfter(other);
    if (other is Timestamp) return dateTime.isAfter(other.toDate());
    return null;
  }

  int get weekday => dateTime.weekday;

  bool operator >=(dynamic other) => this > other || this == other;
  bool operator <=(dynamic other) => this < other || this == other;

  bool operator <(dynamic other) {
    assert(other is Date || other is DateTime || other is Timestamp);
    if (other is Date) return dateTime.isBefore(other.dateTime);
    if (other is DateTime) return dateTime.isBefore(other);
    if (other is Timestamp) return dateTime.isBefore(other.toDate());
    return null;
  }

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

  @override
  bool operator ==(dynamic other) {
    assert(other is Date || other is DateTime || other is Timestamp);
    if (other is Date) return dateTime.isAtSameMomentAs(other.dateTime);
    if (other is DateTime) return dateTime.isAtSameMomentAs(other);
    if (other is Timestamp) return dateTime.isAtSameMomentAs(other.toDate());
    return null;
  }

  @override
  int get hashCode => hashList([dateTime]);

  String get formattedAsIdentifier {
    final String year = dateTime.year.toString().padLeft(4, '0');
    final String month = dateTime.month.toString().padLeft(2, '0');
    final String day = dateTime.day.toString().padLeft(2, '0');

    return '$year$month$day';
  }
}
