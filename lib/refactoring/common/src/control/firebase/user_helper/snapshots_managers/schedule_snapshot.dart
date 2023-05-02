import 'package:atletica/schedule/schedule.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<bool> scheduleSnapshot(
  DocumentSnapshot snapshot,
  DocumentChangeType changeType,
) async {
  switch (changeType) {
    case DocumentChangeType.modified:
      ScheduledTraining.update(snapshot);
      break;
    case DocumentChangeType.added:
      ScheduledTraining.parse(snapshot);
      break;
    case DocumentChangeType.removed:
      ScheduledTraining.remove(snapshot.reference);
      break;
  }
  return true;
}
