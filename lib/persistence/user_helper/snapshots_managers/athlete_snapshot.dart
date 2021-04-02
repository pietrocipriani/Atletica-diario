import 'package:atletica/athlete/atleta.dart';
import 'package:atletica/persistence/auth.dart';
import 'package:atletica/persistence/firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<bool> athleteSnapshot(
  DocumentSnapshot snapshot,
  DocumentChangeType changeType,
) async {
  switch (changeType) {
    case DocumentChangeType.added:
    case DocumentChangeType.modified:

      bool exists = (await firestore
              .collection('users')
              .document(snapshot.documentID)
              .get())
          .exists;
      userC.rawAthletes[snapshot.reference] = Athlete.parse(snapshot, exists);
      break;
    case DocumentChangeType.removed:
      userC.rawAthletes.remove(snapshot.reference);
      break;
  }
  return true;
}
