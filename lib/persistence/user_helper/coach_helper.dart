import 'package:AtleticaCoach/athlete/atleta.dart';
import 'package:AtleticaCoach/persistence/auth.dart';
import 'package:AtleticaCoach/persistence/firestore.dart';
import 'package:AtleticaCoach/persistence/user_helper/snapshots_managers/athlete_snapshot.dart';
import 'package:AtleticaCoach/persistence/user_helper/snapshots_managers/plan_snapshot.dart';
import 'package:AtleticaCoach/persistence/user_helper/snapshots_managers/schedule_snapshot.dart';
import 'package:AtleticaCoach/persistence/user_helper/snapshots_managers/template_snapshot.dart';
import 'package:AtleticaCoach/persistence/user_helper/snapshots_managers/training_snapshot.dart';
import 'package:AtleticaCoach/results/simple_training.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CoachHelper extends FirebaseUserHelper {
  static final List<Callback> onRequestCallbacks = [];
  static final List<Callback> onAthleteCallbacks = [];
  static final List<Callback> onTrainingCallbacks = [];
  static final List<Callback> onPlansCallbacks = [];
  static final List<Callback> onSchedulesCallbacks = [];

  Map<DocumentReference, Athlete> rawAthletes = {};
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
  }) : super(user: user, userReference: userReference) {
    firestore
        .collection('global')
        .document('templates')
        .get()
        .then((snapshot) => addGlobalTemplates(snapshot));
    userReference
        .collection('templates')
        .snapshots()
        .listen((snap) => listener(snap, templateSnapshot));

    userReference.collection('athletes').snapshots().listen((snap) async {
      if (await listener(snap, athleteSnapshot)) {
        final List<Athlete> athletes = rawAthletes.values.toList();
        athletes.sort((a, b) {
          int compare = 0;
          if (a.group != null) compare += a.group.compareTo(b.group ?? '') * 4;
          if (a.name != null) compare += a.name.compareTo(b.name ?? '') * 2;
          return compare;
        });
        rawAthletes = Map.fromIterable(athletes,
            key: (a) => a.reference, value: (a) => a);
        requestsCallAll();
        athletesCallAll();
      }
    });
    userReference.collection('trainings').snapshots().listen((snap) async {
      if (await listener(snap, trainingSnapshot)) trainingsCallAll();
    });
    userReference.collection('plans').snapshots().listen((snap) async {
      if (await listener(snap, planSnapshot)) plansCallAll();
    });
    userReference.collection('schedules').snapshots().listen((snap) async {
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
    return userReference
        .collection('athletes')
        .document(athlete?.documentID)
        .setData({'nickname': nickname, 'group': group});
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
    @required String training,
  }) async {
    rawAthletes[athlete]
        .resultsDoc
        .collection('results')
        .document(dateIdentifier)
        .setData({
      'coach': uid,
      'training': training,
      'results':
          results.entries.map((e) => '${e.key.name}:${e.value}').toList(),
    }, merge: true);
  }

  Stream resultSnapshots({
    @required Athlete athlete,
    String dateIdentifier,
  }) async* {
    final DocumentReference ref = athlete.resultsDoc;
    if (dateIdentifier == null)
      yield* ref
          .collection('results')
          .where('coach', isEqualTo: uid)
          .snapshots();
    yield* ref.collection('results').document(dateIdentifier).snapshots();
  }
}
