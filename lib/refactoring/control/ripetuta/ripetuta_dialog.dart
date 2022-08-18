import 'package:atletica/refactoring/view/ripetuta/dialog/ripetuta_dialog.dart';
import 'package:atletica/ripetuta/ripetuta.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Future<Ripetuta?> createRipetuta(final BuildContext context) {
  return showDialog<Ripetuta>(
    context: context,
    builder: (context) => RipetutaDialog(null),
  );
}

Future<Ripetuta?> editRipetuta(final BuildContext context, final Ripetuta ripetuta) {
  return showDialog<Ripetuta>(
    context: context,
    barrierDismissible: false,
    // TODO: remove focus from edittext?
    builder: (context) => RipetutaDialog(ripetuta),
  );
}
