import 'dart:async';

import 'package:atletica/persistence/firestore.dart';
import 'package:atletica/refactoring/common/common.dart';
import 'package:atletica/refactoring/common/src/control/globals.dart';
import 'package:atletica/refactoring/utils/theme_mode.dart';
import 'package:atletica/persistence/auth.dart';
import 'package:atletica/refactoring/utils/cast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

abstract class UserHelper {
  final User user;
  final bool admin;
  String? runas;
  String get uid => userReference.id;
  String? get name => user.displayName;
  String? get email => user.email;
  TargetCategory category;
  final DocumentReference<Map<String, Object?>> userReference;
  final DocumentReference<Map<String, Object?>> realUser;

  /*static Future<UserHelper> of(final User user, [String? runas]) async {
    runas ??= user.uid;

    final UserHelperDocument doc = firestore.users.doc(runas);
    final UserHelperSnapshot userHelperSnapshot = await doc.get();
    if (!userHelperSnapshot.exists) {
      final UserHelper helper = UserHelper.base(user);
      await doc.set(helper);
      return helper;
    }
    final UserHelper helper = userHelperSnapshot.data()!;
    if (helper.runas != null) return await UserHelper.of(user, helper.runas);
    return helper;
  }*/

  @protected
  UserHelper.parse(final DocumentSnapshot<Map<String, Object?>> raw)
      : this(
          user: Globals.user,
          userReference: raw.reference,
          initialThemeMode: parseThemeMode(
            cast<String?>(raw.getNullable('themeMode'), null),
          ),
          admin: cast<bool>(raw.getNullable('admin'), false),
          category: raw.getNullable('sesso') == 'F'
              ? TargetCategory.females
              : TargetCategory.males,
          runas: cast<String?>(raw.getNullable('runas'), null),
        );

  static Future<HelpersReturnType> generateHelpers(
    final User user, [
    String? runas,
  ]) async {
    runas ??= user.uid;
    final doc = firestore.collection('users').doc(runas);
    final snap = await doc.get();

    if (!snap.exists) {
      await doc.set({
        'themeMode': ThemeMode.system.toString(),
        'sesso': TargetCategory.males,
        'name': user.displayName,
      });
      // could be a bit slimmer, but so we don't need another parsing method
      // TODO: convert parsing functions from Snapshot to Map. No checks are performed anyways
      return await generateHelpers(user, runas);
    }
    final Object? runas2 = snap.getNullable('runas');

    // TODO: infinite loop if the runas graph is cyclic (two users are running as each other)
    if (runas2 is String && runas2 != runas) {
      return generateHelpers(user, runas2);
    }
    final coach = CoachHelper.parse(snap);
    final athlete = await AthleteHelper.parse(snap);
    return HelpersReturnType(coach, athlete);
  }

  @deprecated
  TargetCategory sesso(final String? sex) {
    if (sex == 'F') return TargetCategory.females;
    if (sex == 'M') return TargetCategory.males;
    return TargetCategory.males;
    // TODO: is it possible to extract data from the user?
  }

  UserHelper({
    required this.user,
    required this.userReference,
    required final ThemeMode initialThemeMode,
    this.runas,
    this.category = TargetCategory.males,
    this.admin = false,
  }) : this.realUser = firestore.collection('users').doc(user.uid);

  Map<String, Object?> get asMap => {
        'themeMode': ThemeMode.system.toString(),
        'sesso': category.code,
        'name': name,
      };

  void logout();
}

class HelpersReturnType {
  final CoachHelper coach;
  final AthleteHelper athlete;

  HelpersReturnType(this.coach, this.athlete);
}
