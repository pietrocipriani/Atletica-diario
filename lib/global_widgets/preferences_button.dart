import 'package:atletica/preferences.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:get/get.dart';

class PreferencesButton extends PlatformIconButton {
  PreferencesButton({required final BuildContext context})
      : super(
          materialIcon: Icon(Icons.settings),
          cupertinoIcon: Icon(CupertinoIcons.settings),
          onPressed: () => Get.toNamed('/preferences'),
        );
}
