import 'package:Atletica/athlete/atleta.dart';
import 'package:Atletica/plan/tabella.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<bool> planSnapshot(
  DocumentSnapshot snapshot,
  DocumentChangeType changeType,
) async {
  switch (changeType) {
    case DocumentChangeType.added:
    case DocumentChangeType.modified: // TODO: only update, do not recreate
      Tabella.parse(snapshot);
      break;
    case DocumentChangeType.removed:
      plans.remove(snapshot.reference);
      break;
  }
  return true;
}
