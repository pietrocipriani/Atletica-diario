import 'dart:async';

import 'package:Atletica/persistence/auth.dart';
import 'package:Atletica/persistence/firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AthleteHelper extends FirebaseUserHelper {
  static List<Callback> onCoachChanged = <Callback>[];
  void coachCallAll() => onCoachChanged.forEach((c) => c.call(null));

  final DocumentReference athleteReference;

  DocumentReference _athleteCoachReference;
  StreamSubscription<DocumentSnapshot> _requestSubscription;
  DocumentReference get athleteCoachReference => _athleteCoachReference;
  set athleteCoachReference(DocumentReference reference) {
    if (reference == _athleteCoachReference) return;
    _requestSubscription?.cancel();
    _athleteCoachReference = reference;
    _requestSubscription = reference?.snapshots()?.listen((snap) {
      if (snap.data == null)
        athleteReference.updateData({'coach': null});
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
  })  : athleteReference = firestore.collection('athletes').document(user.uid),
        super(user: user, userReference: userReference) {
    _init();
  }

  void _init() async {
    athleteReference.snapshots().listen((snap) async {
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
        .collection('coaches')
        .document(uid)
        .collection('athletes')
        .document(user.uid);
    if (athleteCoachReference == request) return false;
    final WriteBatch batch = firestore.batch();

    if (athleteCoachReference != null) batch.delete(athleteCoachReference);
    batch.updateData(athleteReference, {'coach': request});
    batch.setData(request, {'athlete': athleteReference}, merge: true);

    await batch.commit();
    return true;
  }

  Future<void> deleteCoachSubscription() => athleteCoachReference?.delete();
}
