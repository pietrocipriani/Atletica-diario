part of 'ripetuta_dialog.dart';

class _RipetutaDialogBody extends StatelessWidget {
  _RipetutaDialogBody(this.template, this.target, {super.key});

  final Rx<SimpleTemplate?> template;
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
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TipologiaSelector(),
                TargetsPicker(template.value!.tipologia, target),
              ],
            );
          }
          return Container();
        })
        /*Positioned(
          left: 20,
          right: 20,
          top: -Theme.of(context).textTheme.overline!.fontSize / 2,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              color: Theme.of(context).dialogBackgroundColor,
              child: Text(
                templates.contains(template)
                    ? 'modifica tutti i ${template.name}'
                    : 'definisci ${template.name}',
                style:
                    Theme.of(context).textTheme.overline!.copyWith(
                          fontWeight: FontWeight.bold,
                          color: templates.contains(template)
                              ? Colors.red
                              : Theme.of(context).accentColor,
                        ),
              ),
            ),
          ),
        ),*/
      ],
    );
  }
}
