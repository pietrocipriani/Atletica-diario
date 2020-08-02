import 'package:Atletica/athlete_role/result.dart';
import 'package:Atletica/persistence/auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

bool resultSnapshot(
  DocumentSnapshot snapshot,
  DocumentChangeType changeType,
) {
  switch (changeType) {
    case DocumentChangeType.added:
      final Result res = Result(snapshot);
      userA.results[snapshot.reference] = res;
      (userA.events[res.date] ??= []).add(res);
      break;
    case DocumentChangeType.modified:
      final Result prev = userA.results[snapshot.reference];
      assert(prev != null);
      final Result res = Result(snapshot);
      userA.results[snapshot.reference] = Result(snapshot);
      userA.events[prev.date].remove(prev);
      (userA.events[res.date] ??= []).add(res);
      break;
    case DocumentChangeType.removed:
      final Result res = userA.results.remove(snapshot.reference);
      userA.events[res.date].remove(res);
      break;
  }
  return true;
}
