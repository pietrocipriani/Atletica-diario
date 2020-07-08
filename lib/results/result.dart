import 'package:Atletica/results/simple_training.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Result {
  /// the `key` is the reference for the Athlete
  final Map<DocumentReference, Map<SimpleRipetuta, double>> results = {};
  final SimpleTraining training;
  final int ripetuteCount;

  Result({this.training, Iterable<DocumentReference> athletes})
      : ripetuteCount = training.ripetute.length {
    for (DocumentReference ref in athletes)
      results[ref] = Map<SimpleRipetuta, double>.fromIterable(training.ripetute,
          key: (rip) => rip, value: (rip) => null);
  }
}
