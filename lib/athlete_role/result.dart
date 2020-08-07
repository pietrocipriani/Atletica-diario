import 'package:Atletica/athlete/results/result_widget.dart';
import 'package:Atletica/results/simple_training.dart';
import 'package:Atletica/schedule/schedule.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class Result {
  final DateTime date;
  final String training;
  final Map<SimpleRipetuta, double> results;

  Result(DocumentSnapshot raw)
      : date = DateTime.parse(raw.documentID),
        training = raw['training'],
        results = Map.fromEntries(
          raw['results']
              .map((r) => parseRawResult(r))
              .map<MapEntry<SimpleRipetuta, double>>(
                (e) => MapEntry<SimpleRipetuta, double>(
                    SimpleRipetuta(e.key), e.value),
              ),
        );

  bool isCompatible(ScheduledTraining training) {
    return listEquals(
      results.keys.map((sr) => sr.name).toList(),
      training.work.ripetute.map((rip) => rip.template).toList(),
    );
  }
}
