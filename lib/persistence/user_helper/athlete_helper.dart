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
    final DocumentReference doc = athleteCoachReference?.parent?.parent;
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
        userReference.update({'coach': null});
      else {
        accepted = snap.data()['nickname'] != null && snap.data()['group'] != null;
        coachCallAll();
      }
    });
  }

  Result getResult(Date date) => results[
      userReference.collection('results').doc(date.formattedAsIdentifier)];

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
        for (DocumentChange doc in snap.docChanges) {
          switch (doc.type) {
            case DocumentChangeType.modified:
              final ScheduledTraining st =
                  scheduledTrainings[doc.doc.reference];
              events[st.date.dateTime]?.remove(st);
              continue ca;
            ca:
            case DocumentChangeType.added:
              final ScheduledTraining st =
                  scheduledTrainings[doc.doc.reference] =
                      ScheduledTraining.parse(doc.doc);
              if (st.athletes.isEmpty ||
                  st.athletes.contains(userA.athleteCoachReference))
                (events[st.date.dateTime] ??= []).add(st);
              break;
            case DocumentChangeType.removed:
              ScheduledTraining st =
                  scheduledTrainings.remove(doc.doc.reference);
              events[st.date.dateTime]?.remove(st);
              break;
          }
        }
        resultsCallAll();
      });
      _trainingsSubscription =
          coach.collection('trainings').snapshots().listen((snap) async {
        bool ok = false;
        for (DocumentChange changed in snap.docChanges)
          ok |= await trainingSnapshot(changed.doc, changed.type);
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
    @required User user,
    @required DocumentReference userReference,
  }) : super(user: user, userReference: userReference) {
    print(userReference.path);
    _init();
  }

  void _init() async {
    userReference.snapshots().listen((snap) async {
      athleteCoachReference = snap.data()['coach'] == null
          ? null
          : firestore
              .collection('users')
              .doc(snap.data()['coach'])
              .collection('athletes')
              .doc(user.uid);
      final DocumentSnapshot athleteCoachSnapshot =
          await athleteCoachReference?.get();
      accepted = athleteCoachSnapshot?.data != null &&
          athleteCoachSnapshot.data()['nickname'] != null &&
          athleteCoachSnapshot.data()['group'] != null;
      coachCallAll();
    });

    userReference.collection('results').snapshots().listen((snap) {
      bool modified = false;
      for (DocumentChange change in snap.docChanges)
        modified |= resultSnapshot(change.doc, change.type);
      if (modified) resultsCallAll();
    });
  }

  Future<bool> requestCoach(
      {@required String uid, @required String nickname}) async {
    if (uid == null || uid == user.uid) return false;
    final DocumentReference request = firestore
        .collection('users')
        .doc(uid)
        .collection('athletes')
        .doc(user.uid);
    if (athleteCoachReference == request) return false;
    final WriteBatch batch = firestore.batch();

    if (athleteCoachReference != null) batch.delete(athleteCoachReference);
    batch.update(userReference, {'coach': uid});
    batch.set(request, {'nickname': nickname}, SetOptions(merge: true));

    await batch.commit();
    return true;
  }

  Future<void> saveResult({@required Result results}) async {
    userReference
        .collection('results')
        .doc(results.date.formattedAsIdentifier)
        .set({
      'coach': coach.id,
      'training': results.training,
      'results':
          results.asIterable.map((e) => '${e.key.name}:${e.value}').toList(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteCoachSubscription() => athleteCoachReference?.delete();
}
