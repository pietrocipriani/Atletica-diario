import 'package:atletica/athlete/athlete.dart';
import 'package:atletica/persistence/firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<bool> athleteSnapshot(
  DocumentSnapshot snapshot,
  DocumentChangeType changeType,
) async {
  switch (changeType) {
    case DocumentChangeType.added:
      bool exists =
          (await firestore.collection('users').doc(snapshot.id).get()).exists;
      Athlete.parse(snapshot, exists);
      break;
    case DocumentChangeType.modified:
      Athlete.update(snapshot);
      break;
    case DocumentChangeType.removed:
      Athlete.remove(snapshot.reference);
      break;
  }
  return true;
}
