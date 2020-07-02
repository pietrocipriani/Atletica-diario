import 'package:Atletica/persistence/auth.dart';
import 'package:Atletica/persistence/firestore.dart';
import 'package:Atletica/persistence/user_helper/snapshots_managers/athlete_snapshot.dart';
import 'package:Atletica/persistence/user_helper/snapshots_managers/plan_snapshot.dart';
import 'package:Atletica/persistence/user_helper/snapshots_managers/request_snapshot.dart';
import 'package:Atletica/persistence/user_helper/snapshots_managers/template_snapshot.dart';
import 'package:Atletica/persistence/user_helper/snapshots_managers/training_snapshot.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CoachHelper extends FirebaseUserHelper {
  static final List<Callback> onRequestCallbacks = [];
  static final List<Callback> onAthleteCallbacks = [];
  static final List<Callback> onTrainingCallbacks = [];
  static final List<Callback> onPlansCallbacks = [];

  final DocumentReference coachReference;

  final Map<String, BasicUser> requests = <String, BasicUser>{};

  static void callAll<T>(List<Callback<T>> callbacks, [T value]) =>
      callbacks.forEach((callback) => callback.call(value));

  static void requestsCallAll() => callAll(onRequestCallbacks);
  static void athletesCallAll() => callAll(onAthleteCallbacks);
  static void trainingsCallAll() => callAll(onTrainingCallbacks);
  static void plansCallAll() => callAll(onPlansCallbacks);

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

    firestore
        .collection('requests')
        .where('coach', isEqualTo: userReference)
        .snapshots()
        .listen((snap) async {
      if (await listener(snap, requestSnapshot)) requestsCallAll();
    });
    coachReference.collection('athletes').snapshots().listen((snap) async {
      if (await listener(snap, athleteSnapshot)) athletesCallAll();
    });
    coachReference.collection('trainings').snapshots().listen((snap) async {
      if (await listener(snap, trainingSnapshot)) trainingsCallAll();
    });
    coachReference.collection('plans').snapshots().listen((snap) async {
      if (await listener(snap, planSnapshot)) plansCallAll();
    });
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
