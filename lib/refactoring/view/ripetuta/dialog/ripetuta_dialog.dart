import 'package:atletica/ripetuta/ripetuta.dart';
import 'package:flutter/material.dart';
import 'package:atletica/refactoring/model/target.dart';
import 'package:atletica/refactoring/view/target/target_picker.dart';
import 'package:atletica/refactoring/view/template/template_text_view.dart';
import 'package:atletica/refactoring/view/tipologia/tipologia_selector.dart';
import 'package:atletica/ripetuta/template.dart';
import 'package:get/get.dart';

part 'ripetuta_dialog_body.dart';

class RipetutaDialog extends StatelessWidget {
  RipetutaDialog(this.ripetuta, {super.key})
      : template = (ripetuta?.resolveTemplate).obs,
        target = ripetuta == null ? Target.empty() : Target.from(ripetuta.target);

  final Ripetuta? ripetuta;
  final Rx<SimpleTemplate?> template;
  final Target target;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Text('RIPETUTA'),
      content: _RipetutaDialogBody(template, target),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Annulla')),
        Obx(
          () => TextButton(
            onPressed: template.value == null ? null : () => save(context),
            child: Text('Conferma'),
          ),
        )
      ],
    );
  }

  Future<void> save(final BuildContext context) async {
    final SimpleTemplate template = this.template.value!;
    template.lastTarget.copyWhereNonNull(target);

    if (template is Template) {
      await template.update();
    } else {
      await template.create();
    }

    final Ripetuta ripetuta;

    if (this.ripetuta == null) {
      ripetuta = Ripetuta(template: template.name, target: target);
    } else {
      ripetuta = this.ripetuta!;
      ripetuta.template = template.name;
      ripetuta.target.copyWhereNonNull(target);
    }

    Navigator.pop(context, ripetuta);
  }
}
