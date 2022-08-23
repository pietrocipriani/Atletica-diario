import 'package:atletica/refactoring/coach/src/view/tipologia/tipologia_icon.dart';
import 'package:atletica/refactoring/common/common.dart';
import 'package:atletica/ripetuta/template.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Form wrapper to select a [Tipologia] with [TipologiaIcon]Buttons
class TipologiaSelector extends StatefulWidget {
  /// the [SimpleTemplate] where to store the [Tipologia]
  final SimpleTemplate template;

  TipologiaSelector({required this.template});

  @override
  State<StatefulWidget> createState() => _TipologiaSelectorState();
}

/// [State] for [TipologiaSelector]
class _TipologiaSelectorState extends State<TipologiaSelector> {
  Tipologia get _tipologia => widget.template.tipologia;
  set _tipologia(final Tipologia tipologia) => widget.template.tipologia;

  @override
  Widget build(BuildContext context) {
    return Row(
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
    );
  }
}
