import 'package:atletica/persistence/firestore.dart';
import 'package:atletica/persistence/user_helper/athlete_helper.dart';
import 'package:atletica/global_widgets/splash_screen.dart';
import 'package:atletica/persistence/auth.dart';
import 'package:flutter/material.dart';

class SwapButton extends IconButton {
  SwapButton({@required final BuildContext context})
      : super(
          icon: Icon(Icons.swap_vert),
          onPressed: () async {
            await user.userReference.updateData(
                {'role': user is AthleteHelper ? COACH_ROLE : ATHLETE_ROLE});
            user = user.user;
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => SplashScreen()),
              (_) => false,
            );
          },
        );
}
