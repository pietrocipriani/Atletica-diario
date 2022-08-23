import 'package:atletica/refactoring/coach/src/view/ripetuta/dialog/ripetuta_dialog.dart';
import 'package:atletica/ripetuta/ripetuta.dart';
import 'package:flutter/material.dart';

/// show a dialog to create a new [Ripetuta]
Future<Ripetuta?> createRipetuta(final BuildContext context) {
  return showDialog<Ripetuta>(
    context: context,
    builder: (context) => RipetutaDialog(null),
  );
}

/// show a dialog to modify an existing [Ripetuta]
Future<Ripetuta?> editRipetuta(final BuildContext context, final Ripetuta ripetuta) {
  return showDialog<Ripetuta>(
    context: context,
    barrierDismissible: false,
    // TODO: remove focus from edittext?
    builder: (context) => RipetutaDialog(ripetuta),
  );
}
