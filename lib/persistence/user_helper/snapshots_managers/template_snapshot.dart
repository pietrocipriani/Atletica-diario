import 'package:Atletica/ripetuta/template.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<bool> templateSnapshot(
  DocumentSnapshot snapshot,
  DocumentChangeType changeType,
) async {
  switch (changeType) {
    case DocumentChangeType.added:
    case DocumentChangeType.modified:
      Template.parse(snapshot);
      break;
    case DocumentChangeType.removed:
      templates.remove(snapshot.id);
      break;
  }
  return true;
}

void addGlobalTemplates(DocumentSnapshot snapshot) {
  for (String name in snapshot.data()['templates'])
    templates[name] ??= Template(name: name);
}
