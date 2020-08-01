import 'package:AtleticaCoach/training/allenamento.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<bool> trainingSnapshot(
  DocumentSnapshot snapshot,
  DocumentChangeType changeType,
) async {
  switch (changeType) {
    case DocumentChangeType.added:
    case DocumentChangeType.modified:
      Allenamento.parse(snapshot);
      break;
    case DocumentChangeType.removed:
      allenamenti.remove(snapshot.reference);
      break;
  }
  return true;
}
