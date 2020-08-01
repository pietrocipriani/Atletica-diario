import 'dart:async';

import 'package:AtleticaCoach/persistence/auth.dart';
import 'package:AtleticaCoach/persistence/firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AthleteHelper extends FirebaseUserHelper {
  static List<Callback> onCoachChanged = <Callback>[];
  void coachCallAll() => onCoachChanged.forEach((c) => c.call(null));

  DocumentReference _athleteCoachReference;
  StreamSubscription<DocumentSnapshot> _requestSubscription;
  DocumentReference get athleteCoachReference => _athleteCoachReference;
  set athleteCoachReference(DocumentReference reference) {
    if (reference == _athleteCoachReference) return;
    _requestSubscription?.cancel();
    _athleteCoachReference = reference;
    _requestSubscription = reference?.snapshots()?.listen((snap) {
      if (snap.data == null)
        userReference.updateData({'coach': null});
      else {
        accepted = snap['nickname'] != null && snap['group'] != null;
        coachCallAll();
      }
    });
  }

  DocumentReference get coach => _athleteCoachReference?.parent()?.parent();

  bool accepted = false;

  bool get hasCoach => accepted;
  bool get hasRequest => coach != null && !accepted;
  bool get needsRequest => coach == null;

  AthleteHelper({
    @required FirebaseUser user,
    @required DocumentReference userReference,
  })  : super(user: user, userReference: userReference) {
    _init();
  }

  void _init() async {
    userReference.snapshots().listen((snap) async {
      athleteCoachReference = snap['coach'];
      final DocumentSnapshot athleteCoachSnapshot =
          await athleteCoachReference?.get();
      accepted = athleteCoachSnapshot?.data != null &&
          athleteCoachSnapshot['nickname'] != null &&
          athleteCoachSnapshot['group'] != null;
      coachCallAll();
    });
  }

  Future<bool> requestCoach({@required String uid}) async {
    if (uid == null || uid == user.uid) return false;
    final DocumentReference request = firestore
        .collection('users')
        .document(uid)
        .collection('athletes')
        .document(user.uid);
    if (athleteCoachReference == request) return false;
    final WriteBatch batch = firestore.batch();

    if (athleteCoachReference != null) batch.delete(athleteCoachReference);
    batch.updateData(userReference, {'coach': request});
    batch.setData(request, {'athlete': userReference}, merge: true);

    await batch.commit();
    return true;
  }

  Future<void> deleteCoachSubscription() => athleteCoachReference?.delete();
}
