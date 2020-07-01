import 'package:Atletica/persistence/auth.dart';
import 'package:Atletica/persistence/user_helper/athlete_helper.dart';
import 'package:Atletica/persistence/user_helper/coach_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Firestore firestore = Firestore.instance;

DocumentReference userFromUid(final String uid) =>
    firestore.collection('users').document(uid);

Future<void> initFirestore() async {
  if (firestore != null) return;
  await firestore.settings(persistenceEnabled: true);
  final DocumentReference userDoc =
      firestore.collection('users').document(user.uid);
  final DocumentSnapshot snapshot = await userDoc.get();
  if (snapshot.data == null) {
    final WriteBatch batch = firestore.batch();
    batch.setData(
      userDoc,
      {'name': user.name, 'email': user.email},
    );
    batch.setData(
      firestore.collection('coaches').document(user.uid),
      {'user': userDoc, 'athletes': [], 'requests': []},
    );
    batch.setData(
      firestore.collection('athletes').document(user.uid),
      {'user': userDoc, 'coach': null},
    );
    await batch.commit();
  } else {
    String role = snapshot.data['role'];
    assert(role == 'coach' || role == 'athlete');
    if (role == 'coach')
      user = CoachHelper(user: user, userReference: userFromUid(user.uid));
    else if (role == 'athlete')
      user = AthleteHelper(user: user, userReference: userFromUid(user.uid));
  }
}

Future<void> setRole(String role) async {
  assert(role == 'coach' || role == 'athlete');
  if (role == 'coach')
    user = CoachHelper(user: user, userReference: userFromUid(user.uid));
  else if (role == 'athlete')
    user = AthleteHelper(user: user, userReference: userFromUid(user.uid));
  await firestore
      .collection('users')
      .document(user.uid)
      .updateData({'role': role});
}
