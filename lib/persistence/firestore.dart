import 'package:atletica/athlete/athlete.dart';
import 'package:atletica/main.dart';
import 'package:atletica/persistence/auth.dart';
import 'package:atletica/persistence/release.dart';
import 'package:atletica/persistence/user_helper/athlete_helper.dart';
import 'package:atletica/persistence/user_helper/coach_helper.dart';
import 'package:atletica/plan/plan.dart';
import 'package:atletica/results/result.dart';
import 'package:atletica/schedule/schedule.dart';
import 'package:atletica/training/training.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

const String COACH_ROLE = 'coach', ATHLETE_ROLE = 'athlete';

FirebaseFirestore firestore = FirebaseFirestore.instance;

DocumentReference userFromUid(final String uid) => firestore.collection('users').doc(uid);

Future<void> initFirestore([
  final String? runas,
  final bool? admin,
]) async {
  Training.cacheReset();
  Plan.cacheReset();
  ScheduledTraining.cacheReset();
  Result.cacheReset();
  Athlete.cacheReset();
  if (!kIsWeb) firestore.settings = Settings(persistenceEnabled: true);
  final DocumentReference userDoc = userFromUid(runas ?? rawUser.uid);
  DocumentSnapshot snapshot = await userDoc.get();

  if (!snapshot.exists)
    await userDoc.set({'name': rawUser.displayName});
  else if (snapshot.getNullable('runas') != null && snapshot['runas'].isNotEmpty)
    return await initFirestore(snapshot['runas'], snapshot.getNullable('admin') as bool? ?? false);
  else {
    if (snapshot.getNullable('role') != null) {
      if (snapshot['role'] == COACH_ROLE)
        user = CoachHelper(
          user: rawUser is User ? rawUser : (rawUser as FirebaseUserHelper).user,
          userReference: userFromUid(runas ?? rawUser.uid),
          admin: admin ?? snapshot.getNullable('admin') as bool? ?? false,
          showAsAthlete: snapshot.getNullable('showAsAthlete') as bool? ?? false,
          showVariants: snapshot.getNullable('showVariants') as bool? ?? false,
          fictionalAthletes: snapshot.getNullable('fictionalAthletes') as bool? ?? true,
        );
      else if (snapshot['role'] == ATHLETE_ROLE)
        user = AthleteHelper(
          user: rawUser is User ? rawUser : (rawUser as FirebaseUserHelper).user,
          userReference: userFromUid(runas ?? rawUser.uid),
          admin: admin ?? snapshot.getNullable('admin') as bool? ?? false,
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

  await checkAndInstallNewRelease();
}

Future<void> setRole(final String role) {
  assert((rawUser == null || !(rawUser is FirebaseUserHelper)) && (role == COACH_ROLE || role == ATHLETE_ROLE));
  final DocumentReference userReference = userFromUid(rawUser.uid);
  if (role == COACH_ROLE)
    user = CoachHelper(
      user: rawUser,
      userReference: userReference,
      showVariants: false,
      fictionalAthletes: true,
      showAsAthlete: false,
    );
  else if (role == ATHLETE_ROLE) user = AthleteHelper(user: rawUser, userReference: userReference);
  return userReference.update({'role': role});
}
