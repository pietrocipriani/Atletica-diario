import 'package:atletica/persistence/auth.dart';
import 'package:atletica/refactoring/common/src/control/firebase/user_helper/athlete_helper.dart';
import 'package:atletica/refactoring/common/src/control/globals.dart';
import 'package:atletica/refactoring/common/src/model/role.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SwapButton extends IconButton {
  SwapButton({required final BuildContext context})
      : super(
          icon: Icon(Icons.swap_vert),
          tooltip: 'CAMBIA RUOLO',
          onPressed: () async {
            // TODO: better switching
            await Globals.userHelper.userReference.update({'role': Globals.userHelper is AthleteHelper ? Role.coach.name : Role.athlete.name});
            // TODO: nullify coach and athlete
            Get.offAllNamed('/role-picker');
          },
        );
}
