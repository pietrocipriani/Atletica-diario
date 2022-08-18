import 'package:atletica/refactoring/model/tipologia.dart';
import 'package:atletica/refactoring/view/tipologia/tipologia_icon.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TipologiaSelector extends StatefulWidget {
  final Tipologia? initialTipologia;

  TipologiaSelector({this.initialTipologia});

  @override
  State<StatefulWidget> createState() => _TipologiaSelectorState();
}

class _TipologiaSelectorState extends State<TipologiaSelector> {
  late Tipologia? _tipologia;

  @override
  void initState() {
    _tipologia = widget.initialTipologia;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: Tipologia.values
          .map((t) => IconButton(
                onPressed: () => setState(() => _tipologia = t),
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
