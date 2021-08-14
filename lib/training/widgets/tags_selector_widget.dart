import 'package:atletica/global_widgets/auto_complete_text_view.dart';
import 'package:atletica/training/training.dart';
import 'package:flutter/material.dart';

class TagsSelectorWidget extends StatefulWidget {
  final Training training;
  TagsSelectorWidget(this.training);

  @override
  _TagsSelectorWidgetState createState() => _TagsSelectorWidgetState();
}

class _TagsSelectorWidgetState extends State<TagsSelectorWidget> {
  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: _TagTextField(
                widget.training.tag1,
                widget.training,
                1,
                setState,
              ),
            ),
          ),
          Text('/'),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: _TagTextField(
                widget.training.tag2,
                widget.training,
                2,
                setState,
              ),
            ),
          ),
        ],
      );
}

class _TagTextField extends StatelessWidget {
  final String? _initialText;
  final Training training;
  final int index;
  final void Function(void Function()) setState;

  _TagTextField(this._initialText, this.training, this.index, this.setState);

  @override
  Widget build(final BuildContext context) {
    return AutoCompleteTextView<String>(
      initialText: _initialText,
      onSelected: (tag) => setState(
          () => (index == 1 ? training.tag1 = tag : training.tag2 = tag)),
      onSubmitted: (tag) =>
          index == 1 ? training.tag1 = tag : training.tag2 = tag,
      submitOnChange: true,
      optionsBuilder: (v) {
        final List<String> ts = (index == 1
                ? Training.fromPath().cast<String>()
                : Training.tag2s(training.tag1))
            .where((t) => t.contains(v.text))
            .toList();
        ts.sort((a, b) {
          if (a.startsWith(v.text) == b.startsWith(v.text))
            return a.compareTo(b);
          if (a.startsWith(v.text)) return -1;
          return 1;
        });
        return ts;
      },
    );
  }
}
