import 'package:Atletica/persistence/auth.dart';
import 'package:Atletica/persistence/user_helper/athlete_helper.dart';
import 'package:Atletica/persistence/user_helper/coach_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Firestore firestore = Firestore.instance;

DocumentReference userFromUid(final String uid) =>
    firestore.collection('users').document(uid);

Future<void> initFirestore() async {
  await firestore.settings(persistenceEnabled: true);
  final DocumentReference userDoc =
      firestore.collection('users').document(rawUser.uid);
  final DocumentSnapshot snapshot = await userDoc.get();
  if (snapshot.data == null) {
    final WriteBatch batch = firestore.batch();
    batch.setData(userDoc, {'name': rawUser.displayName});
    batch.setData(
      firestore.collection('coaches').document(rawUser.uid),
      {'user': userDoc},
    );
    batch.setData(
      firestore.collection('athletes').document(rawUser.uid),
      {'user': userDoc, 'coach': null},
    );
    await batch.commit();
  } else {
    String role = snapshot.data['role'];
    assert(role == 'coach' || role == 'athlete');
    if (role == 'coach')
      user =
          CoachHelper(user: rawUser, userReference: userFromUid(rawUser.uid));
    else if (role == 'athlete')
      user =
          AthleteHelper(user: rawUser, userReference: userFromUid(rawUser.uid));
  }
}

Future<void> setRole(String role) async {
  if (hasRole) return;
  assert(role == 'coach' || role == 'athlete');
  if (role == 'coach')
    user = CoachHelper(user: rawUser, userReference: userFromUid(rawUser.uid));
  else if (role == 'athlete')
    user =
        AthleteHelper(user: rawUser, userReference: userFromUid(rawUser.uid));
  await firestore
      .collection('users')
      .document(user.uid)
      .updateData({'role': role});
}
