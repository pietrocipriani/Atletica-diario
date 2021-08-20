import 'package:atletica/preferences.dart';
import 'package:flutter/material.dart';

class PreferencesButton extends IconButton {
  PreferencesButton({required final BuildContext context})
      : super(
          icon: Icon(Icons.settings),
          tooltip: 'IMPOSTAZIONI',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PreferencesRoute()),
          ),
        );
}
