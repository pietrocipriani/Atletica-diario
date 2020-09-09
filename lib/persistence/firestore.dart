import 'package:Atletica/persistence/auth.dart';
import 'package:Atletica/persistence/user_helper/athlete_helper.dart';
import 'package:Atletica/persistence/user_helper/coach_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const String COACH_ROLE = 'coach', ATHLETE_ROLE = 'athlete';

FirebaseFirestore firestore = FirebaseFirestore.instance;

DocumentReference userFromUid(final String uid) =>
    firestore.collection('users').doc(uid);

Future<void> initFirestore([final String runas]) async {
  firestore.settings = Settings(persistenceEnabled: true);
  final DocumentReference userDoc = userFromUid(runas ?? rawUser.uid);
  final DocumentSnapshot snapshot = await userDoc.get();
  if (!snapshot.exists)
    await userDoc.set({'name': rawUser.displayName});
  else if (snapshot.data()['runas'] != null && snapshot.data()['runas'].isNotEmpty)
    return initFirestore(snapshot.data()['runas']);
  else if (snapshot.data()['role'] != null) {
    print(snapshot.data()['role']);
    if (snapshot.data()['role'] == COACH_ROLE)
      user = CoachHelper(
        user: rawUser,
        userReference: userFromUid(runas ?? rawUser.uid),
      );
    else if (snapshot.data()['role'] == ATHLETE_ROLE)
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
  return userReference.update({'role': role});
}
