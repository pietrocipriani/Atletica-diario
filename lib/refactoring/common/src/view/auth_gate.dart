import 'package:atletica/refactoring/common/common.dart';
import 'package:atletica/refactoring/common/src/control/globals.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:get/get.dart';

class AuthGate extends StatelessWidget {
  static const String routeName = '/login';

  @override
  Widget build(BuildContext context) {
    return SignInScreen(
      headerMaxExtent: 140,
      headerBuilder: (context, constraints, shrinkOffset) => _applicationIcon,
      sideBuilder: (context, constraints) => _applicationIcon,
      showAuthActionSwitch: false,
      subtitleBuilder: (context, action) => Text(
          "Il login è necessario per il backup dei dati e per la comunicazione allenatore/atleta."),
      actions: [
        AuthStateChangeAction<SignedIn>((context, state) {
          // TODO: understand when `state.user` can be `null`
          Globals.user = state.user!;
          Get.offNamed(RoleGate.routeName);
        }),
      ],
    );
  }

  Widget get _applicationIcon => Padding(
      padding: const EdgeInsets.all(20), child: Image.asset('assets/icon.png'));
}
