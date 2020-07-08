import 'package:Atletica/athlete/atleta.dart';
import 'package:Atletica/persistence/auth.dart';
import 'package:Atletica/persistence/firestore.dart';
import 'package:Atletica/persistence/user_helper/snapshots_managers/athlete_snapshot.dart';
import 'package:Atletica/persistence/user_helper/snapshots_managers/plan_snapshot.dart';
import 'package:Atletica/persistence/user_helper/snapshots_managers/schedule_snapshot.dart';
import 'package:Atletica/persistence/user_helper/snapshots_managers/template_snapshot.dart';
import 'package:Atletica/persistence/user_helper/snapshots_managers/training_snapshot.dart';
import 'package:Atletica/results/simple_training.dart';
import 'package:Atletica/schedule/schedule.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CoachHelper extends FirebaseUserHelper {
  static final List<Callback> onRequestCallbacks = [];
  static final List<Callback> onAthleteCallbacks = [];
  static final List<Callback> onTrainingCallbacks = [];
  static final List<Callback> onPlansCallbacks = [];
  static final List<Callback> onSchedulesCallbacks = [];

  final DocumentReference coachReference;

  final Map<DocumentReference, Athlete> rawAthletes = {};
  List<Athlete> get requests =>
      List.unmodifiable(rawAthletes.values.where((a) => a.isRequest));
  List<Athlete> get athletes =>
      List.unmodifiable(rawAthletes.values.where((a) => a.isAthlete));

  static void callAll<T>(List<Callback<T>> callbacks, [T value]) =>
      callbacks.forEach((callback) => callback.call(value));

  static void requestsCallAll() => callAll(onRequestCallbacks);
  static void athletesCallAll() => callAll(onAthleteCallbacks);
  static void trainingsCallAll() => callAll(onTrainingCallbacks);
  static void plansCallAll() => callAll(onPlansCallbacks);
  static void schedulesCallAll() => callAll(onSchedulesCallbacks);

  Future<bool> listener(
    QuerySnapshot snap,
    Future<bool> Function(DocumentSnapshot docSnap, DocumentChangeType type)
        parse,
  ) async {
    bool modified = false;
    for (DocumentChange doc in snap.documentChanges)
      if (await parse(doc.document, doc.type)) modified = true;
    return modified;
  }

  CoachHelper({
    @required FirebaseUser user,
    @required DocumentReference userReference,
  })  : coachReference = firestore.collection('coaches').document(user.uid),
        super(user: user, userReference: userReference) {
    firestore
        .collection('global')
        .document('templates')
        .get()
        .then((snapshot) => addGlobalTemplates(snapshot));
    coachReference
        .collection('templates')
        .snapshots()
        .listen((snap) => listener(snap, templateSnapshot));

    coachReference.collection('athletes').snapshots().listen((snap) async {
      if (await listener(snap, athleteSnapshot)) {
        requestsCallAll();
        athletesCallAll();
      }
    });
    coachReference.collection('trainings').snapshots().listen((snap) async {
      if (await listener(snap, trainingSnapshot)) trainingsCallAll();
    });
    coachReference.collection('plans').snapshots().listen((snap) async {
      if (await listener(snap, planSnapshot)) plansCallAll();
    });
    coachReference.collection('schedules').snapshots().listen((snap) async {
      if (await listener(snap, scheduleSnapshot)) schedulesCallAll();
    });
  }

  /// `athleteUser` is the reference to [users/uid]
  /// `name` is the nickname displayed
  Future<void> addAthlete(
    DocumentReference athlete,
    String nickname,
    String group,
  ) {
    return coachReference
        .collection('athletes')
        .document(athlete.documentID)
        .setData({'user': athlete, 'nickname': nickname, 'group': group});
  }

  Future<void> acceptRequest(
    DocumentReference request,
    String nickname,
    String group,
  ) async {
    await refuseRequest(request);
    await request.updateData({'nickname': nickname, 'group': group});
  }

  Future<void> refuseRequest(DocumentReference request) => request.delete();

  /// `athlete` is the reference to /coaches/$coach/athletes/$athlete
  ///
  /// `dateIdentifier` is in the form 'yyyymmdd' (example 20200708)
  /// required '0's left padding!
  /// `results` is the map for the results, also `null` values are required
  Future<void> saveResult({
    @required DocumentReference athlete,
    @required String dateIdentifier,
    @required Map<SimpleRipetuta, double> results,
  }) async {
    athlete = (await athlete.get())['athlete'] ?? athlete;
    athlete.collection('results').document(dateIdentifier).setData(
          results.entries
              .toList()
              .asMap()
              .map((index, entry) => MapEntry(
                    index.toString().padLeft(3, '0') + entry.key.name,
                    entry.value,
                  ))
                ..removeWhere((index, value) => value == null),
          merge: true,
        );
  }

  Stream<DocumentSnapshot> resultSnapshots({
    @required DocumentReference athlete,
    @required String dateIdentifier,
  }) async* {
    athlete = (await athlete.get())['athlete'] ?? athlete;
    yield* athlete.collection('results').document(dateIdentifier).snapshots();
  }
}
