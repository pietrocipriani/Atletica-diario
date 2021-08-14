import 'package:atletica/persistence/auth.dart';
import 'package:atletica/global_widgets/splash_screen.dart';
import 'package:flutter/material.dart';

class LogoutButton extends IconButton {
  LogoutButton({required final BuildContext context})
      : super(
          icon: Icon(Icons.logout),
          tooltip: 'LOGOUT',
          onPressed: () async {
            await logout();
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => SplashScreen()),
              (_) => false,
            );
          },
        );
}
