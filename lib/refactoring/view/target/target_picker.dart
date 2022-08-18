import 'package:atletica/refactoring/model/target.dart';
import 'package:atletica/refactoring/model/tipologia.dart';
import 'package:atletica/refactoring/view/target/target_category_icon.dart';
import 'package:flutter/material.dart';

class TargetsPicker extends StatefulWidget {
  final Tipologia tipologia;
  final Target target;

  TargetsPicker(this.tipologia, this.target, {super.key});

  @override
  State<StatefulWidget> createState() => _TargetsPickerState();
}

class _TargetsPickerState extends State<TargetsPicker> {
  bool unified = false;

  @override
  Widget build(BuildContext context) {
    final Iterable<Widget> editors = unified
        ? [
            _TargetPicker(
              tipologia: widget.tipologia,
              category: null,
              target: widget.target,
            )
          ]
        : TargetCategory.values.map((e) => _TargetPicker(
              tipologia: widget.tipologia,
              category: e,
              target: widget.target,
            ));

    return Row(
      children: [
        IconButton(
          onPressed: () => setState(() => unified = !unified),
          icon: Icon(unified ? Icons.link : Icons.link_off),
        ),
        ...editors
      ],
    );
  }
}

class _TargetPicker extends StatelessWidget {
  final Tipologia tipologia;
  final Target target;
  final TargetCategory? category;

  _TargetPicker({required this.tipologia, required this.category, required this.target, super.key});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: TextEditingController(text: tipologia.formatTarget(target[category ?? TargetCategory.values.first])),
      decoration: InputDecoration(
        hintText: 'target',
        suffixText: tipologia.targetSuffix,
        icon: category == null ? null : TargetCategoryIcon(category!),
      ),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (value) {
        if (tipologia.validateTarget(value)) return null;
        return tipologia.targetExample;
      },
      onChanged: (value) {
        if (tipologia.validateTarget(value)) {
          final Object? result = tipologia.parseTarget(value);
          if (category == null) {
            target.setAll(result);
          } else {
            target[category!] = result;
          }
        }
      },
    );
  }
}
