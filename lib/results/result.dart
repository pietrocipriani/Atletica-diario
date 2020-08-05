import 'package:Atletica/athlete/results/result_widget.dart';
import 'package:Atletica/results/simple_training.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Result {
  /// the `key` is the reference for the Athlete
  final Map<DocumentReference, Map<SimpleRipetuta, double>> results = {};
  final SimpleTraining training;
  final int ripetuteCount;

  Map<SimpleRipetuta, double> get _defaultResult =>
      Map<SimpleRipetuta, double>.fromIterable(
        training.ripetute,
        key: (rip) => rip,
        value: (rip) => null,
      );

  Result({this.training, Iterable<DocumentReference> athletes})
      : ripetuteCount = training.ripetute.length {
    for (DocumentReference ref in athletes) results[ref] = _defaultResult;
  }

  bool update(DocumentReference athlete, List<String> results) {
    final Map<SimpleRipetuta, double> updated =
        Map.fromIterable(training.ripetute, key: (t) => t, value: (t) => null);

    if (results.length != training.ripetute.length) return false;
    int count = 0;
    for (SimpleRipetuta rip in training.ripetute) {
      final MapEntry e = parseRawResult(results[count++]);
      if (e == null || e.key != rip.name) return false;
      updated[rip] = e.value;
    }
    this.results[athlete] = updated;
    return true;
  }
}
