import 'package:atletica/global_widgets/auto_complete_text_view.dart';
import 'package:atletica/global_widgets/duration_picker.dart';
import 'package:atletica/recupero/recupero.dart';
import 'package:atletica/ripetuta/template.dart';
import 'package:flutter/material.dart';
import 'package:mdi/mdi.dart';

Future<void> showRecoverDialog(
  final BuildContext context,
  final Recupero recupero,
) async {
  final dynamic initialValue = recupero.recupero;
  await showDialog<Duration>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('SELEZIONA IL RECUPERO'),
      content: RecuperoDialog(recupero: recupero),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            recupero.recupero = initialValue;
            Navigator.pop(context);
          },
          child: Text('Annulla'),
        ),
        TextButton(
          onPressed: () {
            if (recupero.recupero is String && recupero.recupero == '')
              recupero.recupero = initialValue;
            Navigator.pop(context);
          },
          child: Text('Modifica'),
        )
      ],
    ),
  );
}

class RecuperoDialog extends StatefulWidget {
  final Recupero recupero;
  RecuperoDialog({required this.recupero});

  @override
  _RecuperoDialogState createState() => _RecuperoDialogState();
}

class _RecuperoDialogState extends State<RecuperoDialog> {
  String _text = '';

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            Expanded(
              child: Text(
                "Scegli la modalità di recupero:",
                style: Theme.of(context).textTheme.overline,
              ),
            ),
            IconButton(
              icon: Icon(
                widget.recupero.recupero is int ? Icons.timer : Mdi.tapeMeasure,
              ),
              onPressed: () =>
                  setState(() => widget.recupero.switchType(_text)),
            ),
          ]),
          widget.recupero.recupero is int
              ? DurationPicker(widget.recupero.recupero,
                  (duration) => widget.recupero.recupero = duration.inSeconds)
              : AutoCompleteTextView<SimpleTemplate>(
                  initialText: widget.recupero.recupero,
                  onSelected: (value) =>
                      setState(() => widget.recupero.recupero = value.name),
                  onSubmitted: (value) => widget.recupero.recupero = value,
                  displayStringForOption: (t) => t.name,
                  optionsBuilder: (v) {
                    _text = v.text;
                    final List<SimpleTemplate> ts = templates.values
                        .where((t) => t.name.contains(v.text))
                        .toList();
                    ts.sort((a, b) {
                      if (a.name.startsWith(v.text) ==
                          b.name.startsWith(v.text))
                        return a.name.compareTo(b.name);
                      if (a.name.startsWith(v.text)) return -1;
                      return 1;
                    });
                    return ts;
                  },
                ),
        ],
      );
}
