import 'package:Atletica/athlete/atleta.dart';
import 'package:Atletica/persistence/auth.dart';
import 'package:Atletica/persistence/firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CoachHelper extends FirebaseUserHelper {
  static final List<Callback> onRequestCallbacks = [];
  static final List<Callback> onAthleteCallbacks = [];

  final DocumentReference coachReference;

  final Map<String, BasicUser> requests = <String, BasicUser>{};
  final List<BasicUser> athletes = [];

  static void requestsCallAll() =>
      onRequestCallbacks.forEach((callback) => callback.call(null));

  static void athletesCallAll() =>
      onAthleteCallbacks.forEach((callback) => callback.call(null));

  CoachHelper({
    @required FirebaseUser user,
    @required DocumentReference userReference,
  })  : coachReference = firestore.collection('coaches').document(user.uid),
        super(user: user, userReference: userReference) {
    firestore
        .collection('requests')
        .where('coach', isEqualTo: userReference)
        .snapshots()
        .listen((snap) async {
      bool modified = false;
      for (DocumentChange docChange in snap.documentChanges) {
        bool ok = await _onNewRequest(docChange.document, docChange.type);
        modified |= ok;
      }

      if (modified) requestsCallAll();
    });
    coachReference.collection('athletes').snapshots().listen((snap) async {
      bool modified = false;
      for (DocumentChange docChange in snap.documentChanges) {
        bool ok = await _onAthlete(docChange.document, docChange.type);
        modified |= ok;
      }

      if (modified) athletesCallAll();
    });
  }

  /// manages a new request (modified, deleted or added) and returns if there are changes
  Future<bool> _onNewRequest(
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
        requests[snapshot.documentID] = BasicUser(
          uid: athlete.documentID,
          name: athleteUser.data['name'],
          email: athleteUser.data['email'],
        );
        break;
      case DocumentChangeType.removed:
        requests.remove(snapshot.documentID);
        break;
    }
    return true;
  }

  Future<bool> _onAthlete(
    DocumentSnapshot snapshot,
    DocumentChangeType changeType,
  ) async {
    print('athletes change: $snapshot, $changeType');
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
        athletes.remove(Atleta.find(snapshot.documentID));
        break;
    }
    return true;
  }

  /// `athleteUser` is the reference to [users/uid]
  /// `name` is the nickname displayed
  Future<void> addAthlete(
    DocumentReference athleteUser,
    String nickname,
    String group,
  ) {
    return coachReference
        .collection('athletes')
        .document(athleteUser.documentID)
        .setData({'user': athleteUser, 'nickname': nickname, 'group': group});
  }

  Future<void> acceptRequest(
    DocumentReference request,
    String nickname,
    String group,
  ) async {
    final DocumentReference athlete = (await request.get()).data['athlete'];
    refuseRequest(request);
    await addAthlete(athlete, nickname, group);
  }

  Future<void> refuseRequest(DocumentReference request) async {
    requests.remove(request.documentID);
    await request.delete();
  }
}
