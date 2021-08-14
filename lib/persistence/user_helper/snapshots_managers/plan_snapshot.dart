import 'package:atletica/plan/plan.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<bool> planSnapshot(
  DocumentSnapshot snapshot,
  DocumentChangeType changeType,
) async {
  switch (changeType) {
    case DocumentChangeType.added:
      Plan.parse(snapshot);
      break;
    case DocumentChangeType.modified:
      Plan.update(snapshot);
      break;
    case DocumentChangeType.removed:
      Plan.remove(snapshot.reference);
      break;
  }
  return true;
}
