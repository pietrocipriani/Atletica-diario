import 'package:Atletica/athlete/atleta.dart';
import 'package:Atletica/persistence/auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<bool> athleteSnapshot(
  DocumentSnapshot snapshot,
  DocumentChangeType changeType,
) async {
  final String athleteUid = snapshot['athlete'].documentID;
  switch (changeType) {
    case DocumentChangeType.added:
      if (snapshot['nickname'] == null || snapshot['group'] == null) {
        DocumentReference doc = snapshot['athlete'];
        DocumentSnapshot snap = await doc.get();
        doc = snap['user'];
        snap = await doc.get();
        userC.requests[snapshot.reference] = Request(
          reference: snapshot.reference,
          uid: athleteUid,
          name: snap['name'],
        );
      } else
        Atleta.parse(snapshot);
      break;
    case DocumentChangeType.modified:
      final Request request = userC.requests[snapshot.reference];
      final Atleta atleta = Atleta.find(athleteUid);
      assert((request == null) != (atleta == null));
      if (request != null && snapshot['nickname'] != null) {
        userC.requests.remove(snapshot.reference);
        Atleta.parse(snapshot);
      } else if (request == null) {
        if (snapshot['nickname'] == null || snapshot['group'] == null)
          throw UnsupportedError('cannot change an athlete to a request');
        else
          atleta
            ..name = snapshot['nickname']
            ..localMigration(snapshot['group']);
      } else
        return false;
      break;
    case DocumentChangeType.removed:
      final Request request = userC.requests[snapshot.reference];
      final Atleta atleta = Atleta.find(athleteUid);
      assert((request == null) != (atleta == null));
      if (request != null)
        userC.requests.remove(snapshot.reference);
      else
        atleta.localMigration(null);
      break;
  }
  return true;
}
