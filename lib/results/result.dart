import 'package:atletica/athlete/results/result_widget.dart';
import 'package:atletica/cache.dart';
import 'package:atletica/date.dart';
import 'package:atletica/persistence/auth.dart';
import 'package:atletica/results/simple_training.dart';
import 'package:atletica/schedule/schedule.dart';
import 'package:atletica/training/training.dart';
import 'package:atletica/main.dart' show IterableExtension;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class Result with Notifier<Result> {
  static final Cache<DocumentReference, Result> _cache = Cache();

  static void Function(Callback c) signInGlobal = _cache.signIn;
  static void Function(Callback c) signOutGlobal = _cache.signOut;

  static void Function() cacheReset = _cache.reset;

  static void remove(final DocumentReference ref) {
    final Result? r = _cache.remove(ref);
    if (r != null) _cache.notifyAll(r, Change.DELETED);
  }

  static Iterable<Result> get cachedResults => _cache.values;

  static bool get isEmpty => _cache.isEmpty;
  static bool get isNotEmpty => _cache.isNotEmpty;

  static Iterable<Result> ofDate(final Date date) =>
      cachedResults.where((r) => r.date == date);
  static Result? tryOf(final DocumentReference? ref) {
    if (ref == null) return null;
    try {
      return Result.of(ref);
    } on StateError {
      return null;
    }
  }

  static Result? ofSchedule(final ScheduledTraining st) {
    final Training? t = st.work;
    if (t == null) return null;
    return ofDate(st.date).firstWhereNullable(
      (r) => r.isCompatible(t, true),
      orElse: () =>
          ofDate(st.date).firstWhereNullable((r) => r.isCompatible(t)),
    );
  }

  factory Result.of(final DocumentReference ref) {
    final Result? a = _cache[ref];
    if (a == null) throw StateError('cannot find Result of ${ref.path}');
    return a;
  }

  factory Result.parse(final DocumentSnapshot raw) {
    final Result a = _cache[raw.reference] ??= Result._parse(raw);
    _cache.notifyAll(a, Change.ADDED);
    return a;
  }
  Result._parse(DocumentSnapshot raw)
      : reference = raw.reference,
        date = raw.getNullable('date') == null
            ? Date.parse(raw.id)
            : Date.fromTimeStamp(raw['date']),
        training = raw['training'],
        results = Map.fromEntries(
          raw['results']
              .map((r) => parseRawResult(r))
              .where((e) => e != null)
              .map<MapEntry<SimpleRipetuta, double?>>(
                (e) => MapEntry<SimpleRipetuta, double?>(
                    SimpleRipetuta(e.key), e.value),
              ),
        ),
        fatigue = raw.getNullable('fatigue'),
        info = raw.getNullable('info') ?? '' {
    //if (raw.getNullable('date') == null) userC.saveResult(this);
  }

  factory Result.updateOrParse(final DocumentSnapshot raw) {
    try {
      return Result.update(raw);
    } on StateError {
      return Result.parse(raw);
    }
  }
  factory Result.update(final DocumentSnapshot raw) {
    final Result r = Result.of(raw.reference);
    r.fatigue = raw['fatigue'];
    r.info = raw['info'];
    int count = 0;
    for (SimpleRipetuta rip in r.ripetute) {
      final MapEntry? e = parseRawResult(raw['results'][count++]);
      if (e == null || e.key != rip.name)
        return throw StateError('cannot update rip');
      r[rip] = e.value;
    }
    r.notifyAll(r, Change.UPDATED);
    return r;
  }

  final DocumentReference? reference;
  final Date date;
  final String training;
  final Map<SimpleRipetuta, double?> results;
  int? fatigue;
  String? info;

  Result.temp(Training training, this.date)
      : reference = null,
        training = training.name,
        results = Map.fromIterable(
          training.ripetute,
          key: (r) => SimpleRipetuta.from(r),
          value: (_) => null,
        );

  /// `training` is ScheduledTraining or Training
  bool isCompatible(final Training? training, [final bool sameName = false]) {
    if (training == null) return false;
    if (sameName && training.name != this.training) return false;
    return listEquals(
      results.keys.map((sr) => sr.name).toList(),
      training.ripetute.map((rip) => rip.template).toList(),
    );
  }

  bool isNotCompatible(final Training? training,
          [final bool sameName = false]) =>
      !isCompatible(training, sameName);

  bool get isOrphan {
    if (ScheduledTraining.ofDate(date).any((st) => isCompatible(st.work, true)))
      return false;
    return ScheduledTraining.ofDate(date)
        .every((st) => isNotCompatible(st.work));
  }

  double? resultAt(int index) {
    return results.values.elementAt(index);
  }

  bool equals(Result result) {
    return listEquals(
      ripetute.map((r) => r.name).toList(),
      result.ripetute.map((r) => r.name).toList(),
    );
  }

  bool get isBooking => results.values.every((r) => r == null);

  void operator []=(final SimpleRipetuta rip, final double? value) =>
      results[rip] = value;
  double? operator [](final SimpleRipetuta rip) => results[rip];

  Iterable<SimpleRipetuta> get ripetute => results.keys;
  Iterable<MapEntry<SimpleRipetuta, double?>> get asIterable => results.entries;

  String get uniqueIdentifier => ripetute.join(':');
}
