import 'package:atletica/athlete/athlete.dart';
import 'package:atletica/athlete/results/result_widget.dart';
import 'package:atletica/date.dart';
import 'package:atletica/results/result.dart';
import 'package:atletica/results/simple_training.dart';
import 'package:atletica/training/training.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Results {
  /// the `key` is the reference for the Athlete
  final Map<Athlete, Result> results = {};
  final Date date;
  final Training training;
  final int ripetuteCount;

  Results(
      {required this.training, required this.date, Iterable<Athlete>? athletes})
      : ripetuteCount = training.ripetute.length {
    if (athletes == null || athletes.isEmpty)
      athletes = Athlete.athletes.toList();
    for (final Athlete a in athletes) results[a] = Result.empty(training, date);
  }

  bool update({
    required final DocumentReference reference,
    required final Athlete athlete,
    required final List<String> results,
    final int? fatigue,
    final String? info,
  }) {
    final Result updated = Result.empty(training, date);
    updated.reference = reference;

    if (results.length != training.ripetute.length) return false;
    updated.fatigue = fatigue;
    updated.info = info;
    int count = 0;
    for (SimpleRipetuta rip in updated.ripetute) {
      final MapEntry? e = parseRawResult(results[count++]);
      if (e == null || e.key != rip.name) return false;
      updated.set(rip, e.value);
    }
    this.results[athlete] = updated;
    return true;
  }
}
