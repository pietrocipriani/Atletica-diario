import 'package:Atletica/athlete/results/result_widget.dart';
import 'package:Atletica/date.dart';
import 'package:Atletica/persistence/auth.dart';
import 'package:Atletica/results/result.dart';
import 'package:Atletica/results/simple_training.dart';
import 'package:Atletica/training/allenamento.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Results {
  /// the `key` is the reference for the Athlete
  final Map<DocumentReference, Result> results = {};
  final Date date;
  final Allenamento training;
  final int ripetuteCount;

  Results(
      {@required this.training,
      @required this.date,
      List<DocumentReference> athletes})
      : ripetuteCount = training.ripetute.length {
    if (athletes == null || athletes.isEmpty)
      athletes = userC.athletes.map((a) => a.reference).where((a) => a != null).toList();
    for (DocumentReference ref in athletes)
      results[ref] = Result.empty(training, date);
  }

  bool update(DocumentReference athlete, List<String> results, [final int fatigue, final String info]) {
    final Result updated = Result.empty(training, date);

    if (results.length != training.ripetute.length) return false;
    updated.fatigue = fatigue;
    updated.info = info;
    int count = 0;
    for (SimpleRipetuta rip in updated.ripetute) {
      final MapEntry e = parseRawResult(results[count++]);
      if (e == null || e.key != rip.name) return false;
      updated.set(rip, e.value);
    }
    this.results[athlete] = updated;
    return true;
  }
}
