import 'package:atletica/athlete/results/result_widget.dart';
import 'package:atletica/date.dart';
import 'package:atletica/persistence/auth.dart';
import 'package:atletica/results/simple_training.dart';
import 'package:atletica/schedule/schedule.dart';
import 'package:atletica/training/training.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

//TODO: multiple training for day (for meeting purposes mainly)
class Result {
  DocumentReference? reference;
  final Date date;
  final String training;
  final Map<SimpleRipetuta, double?> results;
  int? fatigue;
  String? info;

  Result(DocumentSnapshot raw)
      : reference = raw.reference,
        date = raw['date'] == null
            ? Date.parse(raw.id)
            : Date.fromTimeStamp(raw['date']),
        training = raw['training'],
        results = Map.fromEntries(
          raw['results']
              .map((r) => parseRawResult(r))
              .where((e) => e != null)
              .map<MapEntry<SimpleRipetuta, double>>(
                (e) => MapEntry<SimpleRipetuta, double>(
                    SimpleRipetuta(e.key), e.value),
              ),
        ),
        fatigue = raw['fatigue'],
        info = raw['info'] ?? '' {
    if (raw['date'] == null) userA.saveResult(this);
  }

  Result.empty(Training training, this.date)
      : training = training.name,
        results = Map.fromIterable(
          training.ripetute,
          key: (r) => SimpleRipetuta.from(r),
          value: (_) => null,
        );

  /// `training` is ScheduledTraining or Training
  bool isCompatible(final dynamic training, [final bool sameName = false]) {
    assert(training is ScheduledTraining || training is Training);
    final Training a = training is ScheduledTraining ? training.work : training;
    if (a == null) return false;
    if (sameName && a.name != this.training) return false;
    return listEquals(
      results.keys.map((sr) => sr.name).toList(),
      a.ripetute.map((rip) => rip.template).toList(),
    );
  }

  bool isNotCompatible(final dynamic training, [final bool sameName = false]) =>
      !isCompatible(training, sameName);

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

  void set(final SimpleRipetuta rip, final double? value) =>
      results[rip] = value;
  double? operator [](final SimpleRipetuta rip) => results[rip];

  Iterable<SimpleRipetuta> get ripetute => results.keys;
  Iterable<MapEntry<SimpleRipetuta, double?>> get asIterable => results.entries;

  String get uniqueIdentifier => ripetute.join(':');
}
