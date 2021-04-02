import 'package:atletica/persistence/auth.dart';
import 'package:atletica/schedule/schedule.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void _remove(final DocumentReference ref) {
  userC.scheduledTrainings.values.any((l) {
    if (l == null) return false;
    final ScheduledTraining st = l.firstWhere(
      (st) => st.reference == ref,
      orElse: () => null,
    );
    return st == null ? false : l.remove(st);
  });
}

Future<bool> scheduleSnapshot(
  DocumentSnapshot snapshot,
  DocumentChangeType changeType,
) async {
  switch (changeType) {
    case DocumentChangeType.modified:
      _remove(snapshot.reference);
      continue ca;
    ca:
    case DocumentChangeType.added:
      ScheduledTraining training = ScheduledTraining.parse(snapshot);
      (userC.scheduledTrainings[training.date.dateTime] ??= []).add(training);
      break;
    case DocumentChangeType.removed:
      _remove(snapshot.reference);
      break;
  }
  return true;
}
