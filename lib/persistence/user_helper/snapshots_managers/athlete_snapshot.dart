import 'package:Atletica/athlete/atleta.dart';
import 'package:Atletica/athlete/group.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<bool> athleteSnapshot(
  DocumentSnapshot snapshot,
  DocumentChangeType changeType,
) async {
  switch (changeType) {
    case DocumentChangeType.added:
      Atleta.parse(snapshot);
      break;
    case DocumentChangeType.modified:
      Atleta.find(snapshot.documentID)
        ..name = snapshot.data['nickname']
        ..localMigration(snapshot.data['group']);
      break;
    case DocumentChangeType.removed:
      Atleta.find(snapshot.documentID).localMigration(null);
      break;
  }
  return true;
}
