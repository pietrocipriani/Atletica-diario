import 'package:atletica/refactoring/coach/src/view/tipologia/tipologia_icon.dart';
import 'package:atletica/refactoring/common/common.dart';
import 'package:atletica/refactoring/common/src/view/enum_selector.dart';
import 'package:atletica/ripetuta/template.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Form wrapper to select a [Tipologia] with [TipologiaIcon]Buttons
class TipologiaSelector extends StatelessWidget {
  /// the [SimpleTemplate] where to store the [Tipologia]
  final SimpleTemplate template;

  TipologiaSelector({required this.template});

  @override
  Widget build(BuildContext context) {
    return EnumSelector<Tipologia>(
      values: Tipologia.values,
      iconBuilder: (_, t) => TipologiaIcon.from(tipologia: t),
    );
    /* return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: Tipologia.values
          .map((t) => IconButton(
                onPressed: () {
                  widget.template.tipologia = t;
                  setState(() => _tipologia = t);
                },
                icon: TipologiaIcon.from(
                  tipologia: t,
                  // TODO: check if the color is applied correctly
                  color: _tipologia == t ? Get.theme.primaryColor : Get.theme.disabledColor,
                ),
              ))
          .toList(),
    ); */
  }
}
