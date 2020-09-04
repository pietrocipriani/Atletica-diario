import 'dart:async';

import 'package:Atletica/results/result.dart';
import 'package:Atletica/date.dart';
import 'package:Atletica/persistence/auth.dart';
import 'package:Atletica/persistence/firestore.dart';
import 'package:Atletica/persistence/user_helper/snapshots_managers/result_snapshot.dart';
import 'package:Atletica/persistence/user_helper/snapshots_managers/training_snapshot.dart';
import 'package:Atletica/schedule/schedule.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AthleteHelper extends FirebaseUserHelper {
  static final List<Callback> onResultCallbacks = [];
  static final List<Callback> onCoachChanged = <Callback>[];

  final Map<DocumentReference, Result> results = {};
  final Map<DocumentReference, ScheduledTraining> scheduledTrainings = {};

  final Map<DateTime, List<dynamic>> events = {};

  void coachCallAll() => onCoachChanged.forEach((c) => c.call(null));
  void resultsCallAll() => onResultCallbacks.forEach((c) => c.call(null));

  DocumentReference _athleteCoachReference;
  StreamSubscription<DocumentSnapshot> _requestSubscription;
  DocumentReference get coach {
    final DocumentReference doc = athleteCoachReference?.parent()?.parent();
    assert(doc == null || RegExp(r'^users/[A-Za-z0-9]+$').hasMatch(doc.path));
    return doc;
  }

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

  Result getResult(Date date) => results[
      userReference.collection('results').document(date.formattedAsIdentifier)];

  StreamSubscription<QuerySnapshot> _schedulesSubscription;
  StreamSubscription<QuerySnapshot> _trainingsSubscription;

  bool _accepted = false;
  bool get accepted => _accepted;
  set accepted(bool accepted) {
    if (_accepted == accepted) return;
    _accepted = accepted;
    if (accepted) {
      _schedulesSubscription =
          coach.collection('schedules').snapshots().listen((snap) {
        for (DocumentChange doc in snap.documentChanges) {
          switch (doc.type) {
            case DocumentChangeType.modified:
              final ScheduledTraining st =
                  scheduledTrainings[doc.document.reference];
              events[st.date.dateTime]?.remove(st);
              continue ca;
            ca:
            case DocumentChangeType.added:
              final ScheduledTraining st =
                  scheduledTrainings[doc.document.reference] =
                      ScheduledTraining.parse(doc.document);
              if (st.athletes.isEmpty ||
                  st.athletes.contains(userA.athleteCoachReference))
                (events[st.date.dateTime] ??= []).add(st);
              break;
            case DocumentChangeType.removed:
              ScheduledTraining st =
                  scheduledTrainings.remove(doc.document.reference);
              events[st.date.dateTime]?.remove(st);
              break;
          }
        }
        resultsCallAll();
      });
      _trainingsSubscription =
          coach.collection('trainings').snapshots().listen((snap) async {
        bool ok = false;
        for (DocumentChange changed in snap.documentChanges)
          ok |= await trainingSnapshot(changed.document, changed.type);
        if (ok) resultsCallAll();
      });
    } else {
      _schedulesSubscription?.cancel();
      _trainingsSubscription?.cancel();
      events.clear();
      scheduledTrainings.clear();
    }
  }

  bool get hasCoach => accepted;
  bool get hasRequest => athleteCoachReference != null && !accepted;
  bool get needsRequest => athleteCoachReference == null;

  AthleteHelper({
    @required FirebaseUser user,
    @required DocumentReference userReference,
  }) : super(user: user, userReference: userReference) {
    print(userReference.path);
    _init();
  }

  void _init() async {
    userReference.snapshots().listen((snap) async {
      athleteCoachReference = snap['coach'] == null
          ? null
          : firestore
              .collection('users')
              .document(snap['coach'])
              .collection('athletes')
              .document(user.uid);
      final DocumentSnapshot athleteCoachSnapshot =
          await athleteCoachReference?.get();
      accepted = athleteCoachSnapshot?.data != null &&
          athleteCoachSnapshot['nickname'] != null &&
          athleteCoachSnapshot['group'] != null;
      coachCallAll();
    });

    userReference.collection('results').snapshots().listen((snap) {
      bool modified = false;
      for (DocumentChange change in snap.documentChanges)
        modified |= resultSnapshot(change.document, change.type);
      if (modified) resultsCallAll();
    });
  }

  Future<bool> requestCoach(
      {@required String uid, @required String nickname}) async {
    if (uid == null || uid == user.uid) return false;
    final DocumentReference request = firestore
        .collection('users')
        .document(uid)
        .collection('athletes')
        .document(user.uid);
    if (athleteCoachReference == request) return false;
    final WriteBatch batch = firestore.batch();

    if (athleteCoachReference != null) batch.delete(athleteCoachReference);
    batch.updateData(userReference, {'coach': uid});
    batch.setData(request, {'nickname': nickname}, merge: true);

    await batch.commit();
    return true;
  }

  Future<void> saveResult({@required Result results}) async {
    userReference
        .collection('results')
        .document(results.date.formattedAsIdentifier)
        .setData({
      'coach': coach.documentID,
      'training': results.training,
      'results':
          results.asIterable.map((e) => '${e.key.name}:${e.value}').toList(),
    }, merge: true);
  }

  Future<void> deleteCoachSubscription() => athleteCoachReference?.delete();
}
