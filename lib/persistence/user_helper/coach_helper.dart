import 'dart:async';

import 'package:atletica/athlete/athlete.dart';
import 'package:atletica/persistence/auth.dart';
import 'package:atletica/persistence/firestore.dart';
import 'package:atletica/persistence/user_helper/snapshots_managers/athlete_snapshot.dart';
import 'package:atletica/persistence/user_helper/snapshots_managers/plan_snapshot.dart';
import 'package:atletica/persistence/user_helper/snapshots_managers/schedule_snapshot.dart';
import 'package:atletica/persistence/user_helper/snapshots_managers/template_snapshot.dart';
import 'package:atletica/persistence/user_helper/snapshots_managers/training_snapshot.dart';
import 'package:atletica/results/result.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CoachHelper extends FirebaseUserHelper {
  Future<bool> listener(
    QuerySnapshot snap,
    Future<bool> Function(DocumentSnapshot docSnap, DocumentChangeType type)
        parse,
  ) async {
    bool modified = false;
    for (DocumentChange doc in snap.docChanges)
      if (await parse(doc.doc, doc.type)) modified = true;
    return modified;
  }

  CoachHelper({
    required User user,
    required DocumentReference userReference,
    bool admin = false,
  }) : super(user: user, userReference: userReference, admin: admin) {
    firestore
        .collection('global')
        .doc('templates')
        .get()
        .then((snapshot) => addGlobalTemplates(snapshot));
    userReference
        .collection('templates')
        .snapshots()
        .listen((snap) => listener(snap, templateSnapshot));
    userReference
        .collection('athletes')
        .snapshots()
        .listen((snap) => listener(snap, athleteSnapshot));
    userReference
        .collection('trainings')
        .snapshots()
        .listen((snap) => listener(snap, trainingSnapshot));
    userReference
        .collection('plans')
        .snapshots()
        .listen((snap) => listener(snap, planSnapshot));
    userReference
        .collection('schedules')
        .snapshots()
        .listen((snap) => listener(snap, scheduleSnapshot));
  }

  /// `athleteUser` is the reference to [users/uid]
  /// `name` is the nickname displayed
  Future<void> addAthlete(
    DocumentReference? athlete,
    String nickname,
    String group,
  ) {
    return userReference
        .collection('athletes')
        .doc(athlete?.id)
        .set({'nickname': nickname, 'group': group});
  }

  Future<void> acceptRequest(
    DocumentReference request,
    String nickname,
    String group,
  ) async {
    await refuseRequest(request);
    await request.update({'nickname': nickname, 'group': group});
  }

  Future<void> refuseRequest(DocumentReference request) => request.delete();

  /// `athlete` is the reference to /coaches/$coach/athletes/$athlete
  Future<void> saveResult({
    required Athlete athlete,
    required Result results,
  }) {
    return athlete.resultsDoc
        .collection('results')
        .doc(results.reference?.id)
        .set({
      'date': Timestamp.fromDate(results.date),
      'coach': uid,
      'training': results.training,
      'results':
          results.asIterable.map((e) => '${e.key.name}:${e.value}').toList(),
      'fatigue': results.fatigue,
      'info': results.info,
    }, SetOptions(merge: true));
  }
}
