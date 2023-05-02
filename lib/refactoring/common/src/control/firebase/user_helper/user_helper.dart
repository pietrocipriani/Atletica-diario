import 'dart:async';

import 'package:atletica/persistence/firestore.dart';
import 'package:atletica/refactoring/common/common.dart';
import 'package:atletica/refactoring/common/src/control/globals.dart';
import 'package:atletica/refactoring/common/src/model/role.dart';
import 'package:atletica/refactoring/utils/theme_mode.dart';
import 'package:atletica/persistence/auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UserHelper {
  final User user;
  final bool admin;
  final Rx<ThemeMode> _themeMode;
  String? runas;
  String get uid => userReference.id;
  String? get name => user.displayName;
  String? get email => user.email;
  TargetCategory category;
  final DocumentReference userReference;
  final DocumentReference realUser;

  bool get isCoach => this is CoachHelper;
  bool get isAthlete => this is AthleteHelper;

  static Future<UserHelper> of(final User user, [String? runas]) async {
    runas ??= user.uid;

    final DocumentReference<UserHelper> doc = firestore.users.doc(runas);
    final DocumentSnapshot<UserHelper> userHelperSnapshot = await doc.get();
    if (!userHelperSnapshot.exists) {
      final UserHelper helper = UserHelper.base(user);
      await doc.set(helper);
      return helper;
    }
    final UserHelper helper = userHelperSnapshot.data()!;
    if (helper.runas != null) return await UserHelper.of(user, helper.runas);
    return helper;
  }

  factory UserHelper.parse(final DocumentSnapshot<Map<String, Object?>> raw) {
    final Role? role = Role.parse(raw.getNullable('role') as String?);
    switch (role) {
      case Role.coach:
        return CoachHelper.parse(raw);
      case Role.athlete:
        return AthleteHelper.parse(raw);
      case null:
        // TODO: on application forking returns directly [CoachHelper] / [AthleteHelper]
        return UserHelper.parseGenerative(raw);
    }
  }

  @protected
  UserHelper.parseGenerative(final DocumentSnapshot<Map<String, Object?>> raw)
      : this(
          user: Globals.user,
          userReference: raw.reference,
          initialThemeMode: parseThemeMode(raw.getNullable('themeMode') as String?),
          admin: raw.getNullable('admin') as bool? ?? false,
          category: raw.getNullable('sesso') == 'F' ? TargetCategory.females : TargetCategory.males,
          runas: raw.getNullable('runas') as String?,
        ); /*  {
    // TODO: await checkAndInstallNewRelease();
  } */

  TargetCategory sesso(final String? sex) {
    if (sex == 'F') return TargetCategory.females;
    if (sex == 'M') return TargetCategory.males;
    return TargetCategory.males; // TODO: is it possible to extract data from the user?
  }

  UserHelper.base(final User user)
      : this(
          user: user,
          userReference: firestore.users.doc(user.uid),
          initialThemeMode: ThemeMode.system,
        );

  UserHelper({
    required this.user,
    required this.userReference,
    required final ThemeMode initialThemeMode,
    this.runas,
    this.category = TargetCategory.males,
    this.admin = false,
  })  : this.realUser = firestore.users.doc(user.uid),
        _themeMode = initialThemeMode.obs;

  void switchThemeMode() {
    switch (_themeMode.value) {
      case ThemeMode.dark:
        _themeMode.value = ThemeMode.light;
        break;
      case ThemeMode.system:
      case ThemeMode.light:
        _themeMode.value = ThemeMode.dark;
        break;
    }
    userReference.update({'themeMode': _themeMode.toString()});
  }

  ThemeMode get themeMode => _themeMode.value;

  Future<H> setRole<H extends UserHelper>(final Role<H> role) async {
    await userReference.update({'role': role.name});
    switch (role as Role<UserHelper>) {
      case Role.coach:
        return CoachHelper(
          user: Globals.user,
          userReference: userReference,
          initialThemeMode: ThemeMode.system,
          showVariants: false,
          fictionalAthletes: true,
          showAsAthlete: false,
        ) as H;
      case Role.athlete:
        return AthleteHelper(
          user: Globals.user,
          userReference: userReference,
          initialThemeMode: ThemeMode.system,
        ) as H;
    }
  }

  Map<String, Object?> get toMap => {
        'themeMode': themeMode.toString(),
        'sesso': category.code,
        'name': name,
      };
}
