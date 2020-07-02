import 'package:Atletica/persistence/auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<bool> requestSnapshot(
  DocumentSnapshot snapshot,
  DocumentChangeType changeType,
) async {
  print('request change: $snapshot, $changeType');
  final DocumentReference athlete = snapshot.data['athlete'];
  if (athlete == null) {
    await snapshot.reference.delete();
    return false;
  }
  final DocumentSnapshot athleteUser = await athlete.get();
  if (athleteUser.data == null) {
    await snapshot.reference.delete();
    return false;
  }
  switch (changeType) {
    case DocumentChangeType.added:
    case DocumentChangeType.modified:
      userC.requests[snapshot.documentID] = BasicUser(
        uid: athlete.documentID,
        name: athleteUser.data['name'],
        email: athleteUser.data['email'],
      );
      break;
    case DocumentChangeType.removed:
      userC.requests.remove(snapshot.documentID);
      break;
  }
  return true;
}
