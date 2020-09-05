import 'package:Atletica/persistence/auth.dart';
import 'package:Atletica/persistence/user_helper/athlete_helper.dart';
import 'package:Atletica/persistence/user_helper/coach_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const String COACH_ROLE = 'coach', ATHLETE_ROLE = 'athlete';

Firestore firestore = Firestore.instance;

DocumentReference userFromUid(final String uid) =>
    firestore.collection('users').document(uid);

Future<void> initFirestore([final String runas]) async {
  await firestore.settings(persistenceEnabled: true);
  final DocumentReference userDoc = userFromUid(runas ?? rawUser.uid);
  final DocumentSnapshot snapshot = await userDoc.get();
  if (!snapshot.exists)
    await userDoc.setData({'name': rawUser.displayName});
  else if (snapshot['runas'] != null && snapshot['runas'].isNotEmpty)
    return initFirestore(snapshot['runas']);
  else if (snapshot['role'] != null) {
    print(snapshot['role']);
    if (snapshot['role'] == COACH_ROLE)
      user = CoachHelper(
        user: rawUser,
        userReference: userFromUid(runas ?? rawUser.uid),
      );
    else if (snapshot['role'] == ATHLETE_ROLE)
      user = AthleteHelper(
        user: rawUser,
        userReference: userFromUid(runas ?? rawUser.uid),
      );
  }
}

Future<void> setRole(String role) {
  assert(user == null && (role == COACH_ROLE || role == ATHLETE_ROLE));
  final DocumentReference userReference = userFromUid(rawUser.uid);
  if (role == COACH_ROLE)
    user = CoachHelper(user: rawUser, userReference: userReference);
  else if (role == ATHLETE_ROLE)
    user = AthleteHelper(user: rawUser, userReference: userReference);
  return userReference.updateData({'role': role});
}
