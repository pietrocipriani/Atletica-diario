import 'package:Atletica/athlete/results/result_widget.dart';
import 'package:Atletica/date.dart';
import 'package:Atletica/persistence/auth.dart';
import 'package:Atletica/results/result.dart';
import 'package:Atletica/results/simple_training.dart';
import 'package:Atletica/training/allenamento.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Results {
  /// the `key` is the reference for the Athlete
  final Map<DocumentReference, Result> results = {};
  final Date date;
  final Allenamento training;
  final int ripetuteCount;

  Results({this.training, this.date})
      : ripetuteCount = training.ripetute.length {
    for (DocumentReference ref in userC.athletes.map((a) => a.reference))
      results[ref] = Result.empty(training, date);
  }

  bool update(DocumentReference athlete, List<String> results) {
    final Result updated = Result.empty(training, date);

    if (results.length != training.ripetute.length) return false;
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
