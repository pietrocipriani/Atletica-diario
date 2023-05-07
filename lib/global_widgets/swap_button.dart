import 'package:atletica/refactoring/common/src/control/globals.dart';
import 'package:flutter/material.dart';

class SwapButton extends IconButton {
  SwapButton({required final BuildContext context})
      : super(
          icon: Icon(Icons.swap_vert),
          tooltip: 'CAMBIA RUOLO',
          onPressed: Globals.switchRole,
        );
}
