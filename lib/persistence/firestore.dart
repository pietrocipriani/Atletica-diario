import 'package:atletica/persistence/auth.dart';
import 'package:atletica/refactoring/common/src/control/firebase/user_helper/coach_helper.dart';
import 'package:atletica/refactoring/common/src/control/firebase/user_helper/user_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

FirebaseFirestore firestore = FirebaseFirestore.instance;

/* Future<void> setRole(final String role) {
  assert((rawUser == null || !(rawUser is UserHelper)) && (role == COACH_ROLE || role == ATHLETE_ROLE));
  final DocumentReference userReference = userFromUid(rawUser.uid);
  if (role == COACH_ROLE)
    user = CoachHelper(
      user: rawUser,
      userReference: userReference,
      initialThemeMode: ThemeMode.system,
      showVariants: false,
      fictionalAthletes: true,
      showAsAthlete: false,
    );
  else if (role == ATHLETE_ROLE)
    user = CoachHelper(
      user: rawUser,
      userReference: userReference,
      initialThemeMode: ThemeMode.system,
    );
  return userReference.update({'role': role});
} */
