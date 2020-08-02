import 'package:Atletica/results/simple_training.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Result {
  /// the `key` is the reference for the Athlete
  final Map<DocumentReference, Map<SimpleRipetuta, double>> results = {};
  final SimpleTraining training;
  final int ripetuteCount;

  Result({this.training, Iterable<DocumentReference> athletes})
      : ripetuteCount = training.ripetute.length {{}
    for (DocumentReference ref in athletes)
      results[ref] = Map<SimpleRipetuta, double>.fromIterable(training.ripetute,
          key: (rip) => rip, value: (rip) => null);
  }

  bool update (DocumentReference athlete, List<String> results) {
    final Map<SimpleRipetuta, double> updated =
      Map.fromIterable(training.ripetute, key: (t) => t, value: (t) => null);

    if (results.length != training.ripetute.length) return false;
    int count = 0;
    for (SimpleRipetuta rip in training.ripetute) {
      final String raw = results[count++];
      final double value = double.tryParse(raw.substring(raw.indexOf(':')+1));
      if (!raw.startsWith('${rip.name}:') || value == null) return false;
      updated[rip] = value;
    }
    this.results[athlete] = updated;
    return true;
  }
}
