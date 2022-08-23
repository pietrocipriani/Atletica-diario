import 'package:atletica/refactoring/coach/src/view/target/target_category_icon.dart';
import 'package:atletica/refactoring/common/common.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// The form for picking [Target]s
class TargetsPicker extends StatefulWidget {
  /// The formatting [Tipologia]
  final Tipologia tipologia;

  /// The initial [Target] to be modified
  final Target target;

  TargetsPicker(this.tipologia, this.target, {super.key});

  @override
  State<StatefulWidget> createState() => _TargetsPickerState();
}

/// [State] for [TargetsPicker]
class _TargetsPickerState extends State<TargetsPicker> {
  /// flag to show and modify every category target distinctly or as a single value
  bool unified = false;

  @override
  void initState() {
    unified = widget.target.isUnified;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final Iterable<Widget> editors; // the editable text view [_TargetPicker]s
    if (unified) {
      editors = [
        Expanded(
          child: _TargetPicker(
            tipologia: widget.tipologia,
            category: null,
            target: widget.target,
          ),
        )
      ];
    } else {
      editors = TargetCategory.values.map((e) => Expanded(
            child: _TargetPicker(
              tipologia: widget.tipologia,
              category: e,
              target: widget.target,
            ),
          ));
    }

    return Row(
      children: [
        // the icon button to switch the `unified` flag
        IconButton(
          onPressed: () => setState(() => unified = !unified),
          icon: Icon(unified ? Icons.link : Icons.link_off),
        ),
        ...editors,
        /* Expanded(
          child: Column(
            children: editors.toList(),
            mainAxisSize: MainAxisSize.min,
          ),
        ), */
      ],
    );
  }
}

/// the text field for changing the [Target]
class _TargetPicker extends StatelessWidget {
  /// the formatting [Tipologia]
  final Tipologia tipologia;

  /// the current [Target]
  final Target target;

  /// the [TargetCategory] regarding this [_TargetPicker]
  ///
  /// `null` in `unified` mode
  final TargetCategory? category;

  _TargetPicker({required this.tipologia, required this.category, required this.target, super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoTextFormFieldRow(
      controller: TextEditingController(text: tipologia.formatTarget(target[category ?? TargetCategory.values.first])),
      textAlign: TextAlign.end,
      placeholder: 'target',
      padding: EdgeInsets.zero,
      prefix: category == null ? null : TargetCategoryIcon(category!),
      style: Get.textTheme.overline,
      decoration: BoxDecoration(
        color: Get.theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(20),
        /* suffixText: tipologia.targetSuffix, */
      ),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (value) {
        if (tipologia.validateTarget(value)) return null;
        return tipologia.targetExample;
      },
      onChanged: (value) {
        if (tipologia.validateTarget(value)) {
          final ResultValue? result = tipologia.parseTarget(value);
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
