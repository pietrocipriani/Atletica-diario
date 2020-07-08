import 'package:Atletica/athlete/atleta.dart';
import 'package:Atletica/persistence/auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<bool> athleteSnapshot(
  DocumentSnapshot snapshot,
  DocumentChangeType changeType,
) async {
  DocumentReference userRef = snapshot['athlete'];
  DocumentSnapshot userSnap = await userRef.get();
  userRef = userSnap['user'];
  userSnap = await userRef.get();
  switch (changeType) {
    case DocumentChangeType.added:
    case DocumentChangeType.modified:
      userC.rawAthletes[snapshot.reference] =
          Athlete.parse(raw: snapshot, user: userSnap);
      break;
    case DocumentChangeType.removed:
      userC.rawAthletes.remove(snapshot.reference);
      break;
  }
  return true;
}
