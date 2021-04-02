import 'package:atletica/global_widgets/duration_picker.dart';
import 'package:atletica/recupero/recupero.dart';
import 'package:atletica/ripetuta/template.dart';
import 'package:autocomplete_textfield/autocomplete_textfield.dart';
import 'package:flutter/material.dart';
import 'package:mdi/mdi.dart';

Future<Duration> showRecoverDialog(
  final BuildContext context,
  final Recupero recupero,
) async {
  final dynamic initialValue = recupero.recupero;
  return await showDialog<Duration>(
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
  RecuperoDialog({@required this.recupero});

  @override
  _RecuperoDialogState createState() => _RecuperoDialogState();
}

class _RecuperoDialogState extends State<RecuperoDialog> {
  final TextEditingController _lengthController = TextEditingController();

  @override
  void initState() {
    if (widget.recupero.recupero is String)
      _lengthController.text = widget.recupero.recupero;
    super.initState();
  }

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
              onPressed: () => setState(
                  () => widget.recupero.switchType(_lengthController.text)),
            ),
          ]),
          widget.recupero.recupero is int
              ? DurationPicker(widget.recupero.recupero,
                  (duration) => widget.recupero.recupero = duration.inSeconds)
              : AutoCompleteTextField<Template>(
                  itemSubmitted: (value) =>
                      setState(() => widget.recupero.recupero = value.name),
                  controller: _lengthController,
                  clearOnSubmit: false,
                  key: GlobalKey(),
                  textSubmitted: (value) => widget.recupero.recupero = value,
                  suggestions: templates.values
                      .where((template) => template != null)
                      .toList(),
                  itemBuilder: (context, suggestion) => Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: RichText(
                      text: TextSpan(
                        text: suggestion.name.substring(
                            0, suggestion.name.indexOf(_lengthController.text)),
                        style: Theme.of(context).textTheme.subtitle2,
                        children: [
                          TextSpan(
                            text: _lengthController.text,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: suggestion.name.substring(suggestion.name
                                    .indexOf(_lengthController.text) +
                                _lengthController.text.length),
                          ),
                        ],
                      ),
                    ),
                  ),
                  itemSorter: (a, b) {
                    if (a.name.startsWith(_lengthController.text) ==
                        b.name.startsWith(_lengthController.text))
                      return a.name.compareTo(b.name);
                    if (a.name.startsWith(_lengthController.text)) return -1;
                    return 1;
                  },
                  itemFilter: (suggestion, query) =>
                      suggestion.name.contains(query),
                ),
        ],
      );
}
