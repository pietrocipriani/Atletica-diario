import 'package:Atletica/athlete/results/result_widget.dart';
import 'package:Atletica/date.dart';
import 'package:Atletica/results/simple_training.dart';
import 'package:Atletica/schedule/schedule.dart';
import 'package:Atletica/training/allenamento.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class Result {
  final Date date;
  final String training;
  final Map<SimpleRipetuta, double> results;

  Result(DocumentSnapshot raw)
      : date = Date.parse(raw.id),
        training = raw['training'],
        results = Map.fromEntries(
          raw['results']
              .map((r) => parseRawResult(r))
              .where((e) => e != null)
              .map<MapEntry<SimpleRipetuta, double>>(
                (e) => MapEntry<SimpleRipetuta, double>(
                    SimpleRipetuta(e.key), e.value),
              ),
        );

  Result.empty(Allenamento training, this.date)
      : training = training.name,
        results = Map.fromIterable(
          training.ripetute,
          key: (r) => SimpleRipetuta.from(r),
          value: (_) => null,
        );

  /// `training` is ScheduledTraining or Allenamento
  bool isCompatible(dynamic training) {
    assert(training is ScheduledTraining || training is Allenamento);
    final Allenamento a =
        training is ScheduledTraining ? training.work : training;
    return listEquals(
      results.keys.map((sr) => sr.name).toList(),
      a.ripetute.map((rip) => rip.template).toList(),
    );
  }

  bool equals(Result result) {
    return listEquals(
      ripetute.map((r) => r.name).toList(),
      result.ripetute.map((r) => r.name).toList(),
    );
  }

  bool get isBooking => results.values.every((r) => r == null);

  void set(final SimpleRipetuta rip, final double value) =>
      results[rip] = value;
  double operator [](final SimpleRipetuta rip) => results[rip];

  Iterable<SimpleRipetuta> get ripetute => results.keys;
  Iterable<MapEntry<SimpleRipetuta, double>> get asIterable => results.entries;

  String get uniqueIdentifier => ripetute.join(':');
}
