import 'package:atletica/training/training.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<bool> trainingSnapshot(
  DocumentSnapshot snapshot,
  DocumentChangeType changeType,
) async {
  switch (changeType) {
    case DocumentChangeType.added:
      Training.parse(snapshot);
      break;
    case DocumentChangeType.modified:
      Training.update(snapshot);
      break;
    case DocumentChangeType.removed:
      Training.remove(snapshot.reference);
      break;
  }
  return true;
}
