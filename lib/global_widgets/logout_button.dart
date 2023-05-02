import 'package:atletica/persistence/auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LogoutButton extends IconButton {
  LogoutButton({required final BuildContext context})
      : super(
          icon: Icon(Icons.logout),
          tooltip: 'LOGOUT',
          onPressed: () async {
            await logout();
            Get.offAllNamed('/login');
          },
        );
}
