import 'package:atletica/results/result.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

bool resultSnapshot(
  DocumentSnapshot snapshot,
  DocumentChangeType changeType,
) {
  switch (changeType) {
    case DocumentChangeType.added:
      Result.parse(snapshot);
      break;
    case DocumentChangeType.modified:
      Result.update(snapshot);
      break;
    case DocumentChangeType.removed:
      Result.remove(snapshot.reference);
      break;
  }
  return true;
}
