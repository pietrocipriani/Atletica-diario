import 'package:atletica/athlete/athlete.dart';
import 'package:atletica/main.dart';
import 'package:atletica/persistence/auth.dart';
import 'package:atletica/persistence/user_helper/athlete_helper.dart';
import 'package:atletica/persistence/user_helper/coach_helper.dart';
import 'package:atletica/plan/plan.dart';
import 'package:atletica/results/result.dart';
import 'package:atletica/schedule/schedule.dart';
import 'package:atletica/training/training.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

const String COACH_ROLE = 'coach', ATHLETE_ROLE = 'athlete';

FirebaseFirestore firestore = FirebaseFirestore.instance;

DocumentReference userFromUid(final String uid) =>
    firestore.collection('users').doc(uid);

Future<void> initFirestore([
  final String? runas,
  final bool? admin,
]) async {
  Training.cacheReset();
  Plan.cacheReset();
  ScheduledTraining.cacheReset();
  Result.cacheReset();
  Athlete.cacheReset();
  firestore.settings = Settings(persistenceEnabled: true);
  final DocumentReference userDoc = userFromUid(runas ?? rawUser.uid);
  DocumentSnapshot snapshot;
  snapshot = await userDoc.get();

  if (!snapshot.exists)
    await userDoc.set({'name': rawUser.displayName});
  else if (snapshot.getNullable('runas') != null &&
      snapshot['runas'].isNotEmpty)
    return await initFirestore(
        snapshot['runas'], snapshot.getNullable('admin') ?? false);
  else {
    if (snapshot.getNullable('role') != null) {
      if (snapshot['role'] == COACH_ROLE)
        user = CoachHelper(
          user:
              rawUser is User ? rawUser : (rawUser as FirebaseUserHelper).user,
          userReference: userFromUid(runas ?? rawUser.uid),
          admin: admin ?? snapshot.getNullable('admin') ?? false,
        );
      else if (snapshot['role'] == ATHLETE_ROLE)
        user = AthleteHelper(
          user:
              rawUser is User ? rawUser : (rawUser as FirebaseUserHelper).user,
          userReference: userFromUid(runas ?? rawUser.uid),
          admin: admin ?? snapshot.getNullable('admin') ?? false,
        );
    }
    if (snapshot.getNullable('themeMode') != null) {
      final String tmRaw = snapshot['themeMode'];
      themeMode = tmRaw == 'ThemeMode.dark'
          ? ThemeMode.dark
          : tmRaw == 'ThemeMode.light'
              ? ThemeMode.light
              : ThemeMode.system;
    }
  }
}

Future<void> setRole(String role) {
  assert(rawUser == null && (role == COACH_ROLE || role == ATHLETE_ROLE));
  final DocumentReference userReference = userFromUid(rawUser.uid);
  if (role == COACH_ROLE)
    user = CoachHelper(user: rawUser, userReference: userReference);
  else if (role == ATHLETE_ROLE)
    user = AthleteHelper(user: rawUser, userReference: userReference);
  return userReference.update({'role': role});
}
