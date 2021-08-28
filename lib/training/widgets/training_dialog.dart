import 'package:atletica/ripetuta/ripetuta.dart';
import 'package:atletica/training/serie.dart';
import 'package:atletica/training/training.dart';
import 'package:atletica/training/training_description.dart';
import 'package:atletica/training/widgets/tags_selector_widget.dart';
import 'package:flutter/material.dart';

class TrainingDialog extends StatefulWidget {
  final String? tag1, tag2;
  TrainingDialog({this.tag1, this.tag2});

  @override
  _TrainingDialogState createState() => _TrainingDialogState();
}

class _TrainingDialogState extends State<TrainingDialog> {
  final TextEditingController _controller = () {
    int index = Training.trainingsCount() + 1;
    while (Training.isNameInUse('training #$index')) index++;
    return TextEditingController(text: 'training #$index');
  }();
  final FocusNode _titleFocus = FocusNode();
  String? tag1, tag2;
  bool _parseName = true;
  List<Serie>? serie;

  @override
  void initState() {
    tag1 = widget.tag1;
    tag2 = widget.tag2;
    super.initState();
  }

  @override
  void didUpdateWidget(final TrainingDialog oldWidget) {
    if (widget.tag1 != oldWidget.tag1) tag1 = widget.tag1 ?? tag1;
    if (widget.tag2 != oldWidget.tag2) tag2 = widget.tag2 ?? tag2;
    super.didUpdateWidget(oldWidget);
  }

  String? _titleValidator(final String? v) => v == null || v.isEmpty
      ? 'inserire il titolo'
      : Training.isNameInUse(v)
          ? 'nome già in uso'
          : null;

  @override
  Widget build(BuildContext context) {
    final bool parsableName = Training.isParsableName(_controller.text);
    if (parsableName) serie = Training.parseName(_controller.text);
    return AlertDialog(
      title: Text('CREA ALLENAMENTO'),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            //focusNode: _titleFocus,
            controller: _controller,
            decoration: const InputDecoration(hintText: 'nome allenamento'),
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: _titleValidator,
            onChanged: (v) => setState(() {}),
            onFieldSubmitted: (v) =>
                FocusScope.of(context).requestFocus(FocusNode()),
          ),
          TagsSelectorWidget(
            onChanged: (tag1, tag2) {
              this.tag1 = tag1;
              this.tag2 = tag2;
            },
            dense: true,
            tag1: tag1,
            tag2: tag2,
          ),
          Row(
            children: [
              Expanded(child: Text('analizza titolo')),
              Switch(
                value: _parseName && parsableName,
                onChanged:
                    parsableName ? (v) => setState(() => _parseName = v) : null,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
          if (_parseName && serie != null)
            Column(
              children: TrainingDescription.fromSerie(
                serie!,
                !parsableName,
              ).toList(),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text('Annulla'),
        ),
        TextButton(
          onPressed: _titleValidator(_controller.text) != null
              ? null
              : () async {
                  await Training.create(
                    name: _controller.text,
                    tag1: tag1,
                    tag2: tag2,
                    serie: _parseName && parsableName ? serie : null,
                  );

                  Navigator.pop(
                    context,
                    Pair<String, String>(
                      tag1 ?? Training.defaultTag,
                      tag2 ?? Training.defaultTag,
                    ),
                  );
                },
          child: Text('Conferma'),
        ),
      ],
    );
  }
}
