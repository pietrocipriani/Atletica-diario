import 'package:Atletica/schedule/schedule.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<bool> scheduleSnapshot(
  DocumentSnapshot snapshot,
  DocumentChangeType changeType,
) async {
  switch (changeType) {
    case DocumentChangeType.added:
    case DocumentChangeType.modified:
      schedules[snapshot.reference] = snapshot['work'].parent().id == 'plans'
          ? PlanSchedule.parse(snapshot)
          : TrainingSchedule.parse(snapshot);
      break;
    case DocumentChangeType.removed:
      schedules.remove(snapshot.reference);
      break;
  }
  return true;
}
