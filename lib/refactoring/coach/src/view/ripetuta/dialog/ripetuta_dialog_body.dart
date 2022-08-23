part of 'ripetuta_dialog.dart';

/// the body for [RipetutaDialog]
class _RipetutaDialogBody extends StatelessWidget {
  _RipetutaDialogBody(this.template, this.target, {super.key});

  /// the modifiable template
  ///
  /// modification are reversible (this is a copy)
  final Rx<SimpleTemplate?> template;

  /// the modifiable target
  ///
  /// modifications are reversible (this is a copy)
  final Target target;

  @override
  Widget build(final BuildContext context) {
    final TemplateAutoCompleteTextView _autoCompleteTV = TemplateAutoCompleteTextView(
      initialText: template.value?.name,
      onSelected: (value) {
        template.value = value;
        target.copy(template.value?.lastTarget);
      },
    );

    return Column(
      children: <Widget>[
        _autoCompleteTV,
        Obx(() {
          if (template.value != null) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (template.value is! Template) TipologiaSelector(template: template.value!),
                TargetsPicker(template.value!.tipologia, target),
              ],
            );
          }
          return Container();
        }),
      ],
    );
  }
}
