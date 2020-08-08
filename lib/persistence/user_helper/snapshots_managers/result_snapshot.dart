import 'package:Atletica/results/result.dart';
import 'package:Atletica/persistence/auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

bool resultSnapshot(
  DocumentSnapshot snapshot,
  DocumentChangeType changeType,
) {
  switch (changeType) {
    case DocumentChangeType.added:
      userA.results[snapshot.reference] = Result(snapshot);
      break;
    case DocumentChangeType.modified:
      final Result prev = userA.results[snapshot.reference];
      assert(prev != null);
      userA.results[snapshot.reference] = Result(snapshot);
      break;
    case DocumentChangeType.removed:
      userA.results.remove(snapshot.reference);
      break;
  }
  return true;
}
