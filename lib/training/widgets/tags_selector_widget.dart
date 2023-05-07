import 'package:atletica/global_widgets/auto_complete_text_view.dart';
import 'package:atletica/training/training.dart';
import 'package:flutter/material.dart';

// TODO: chiedere se è preferibile un path più flessibile
class TagsSelectorWidget extends StatefulWidget {
  final Training? training;
  final String? tag1, tag2;
  final Function(String? tag1, String? tag2)? onChanged;
  final bool dense;
  TagsSelectorWidget({
    this.training,
    this.onChanged,
    this.tag1,
    this.tag2,
    this.dense = true,
  });

  @override
  _TagsSelectorWidgetState createState() => _TagsSelectorWidgetState();
}

class _TagsSelectorWidgetState extends State<TagsSelectorWidget> {
  String? tag1, tag2;

  @override
  void initState() {
    tag1 = widget.tag1;
    tag2 = widget.tag2;
    super.initState();
  }

  @override
  void didUpdateWidget(final TagsSelectorWidget oldWidget) {
    if (oldWidget.tag1 != widget.tag1) tag1 = widget.tag1 ?? tag1;
    if (oldWidget.tag2 != widget.tag2) tag2 = widget.tag2 ?? tag2;
    super.didUpdateWidget(oldWidget);
  }

  final GlobalKey _tag2Key = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: _TagTextField(
              initialText: widget.training?.tag1 ?? tag1,
              training: widget.training,
              index: 1,
              dense: widget.dense,
              onChanged: (tag) {
                if (widget.training != null)
                  widget.training!.tag1 = tag;
                else
                  tag1 = tag;
                widget.onChanged?.call(tag, widget.training?.tag2 ?? tag2);
                _tag2Key.currentState?.setState(() {});
              },
            ),
          ),
        ),
        Text('/'),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: _TagTextField(
              initialText: widget.training?.tag2 ?? tag2,
              training: widget.training,
              index: 2,
              dense: widget.dense,
              onChanged: (tag) {
                if (widget.training != null)
                  widget.training!.tag2 = tag;
                else
                  tag2 = tag;
                widget.onChanged?.call(widget.training?.tag1 ?? tag1, tag);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _TagTextField extends StatefulWidget {
  final String? initialText;
  final Training? training;
  final int index;
  final bool dense;
  final void Function(String tag) onChanged;

  _TagTextField({
    final Key? key,
    this.initialText,
    this.training,
    required this.index,
    required this.onChanged,
    this.dense = false,
  }) : super(key: key);

  @override
  _TagTextFieldState createState() => _TagTextFieldState();
}

class _TagTextFieldState extends State<_TagTextField> {
  @override
  Widget build(final BuildContext context) {
    return AutoCompleteTextView<String>(
      initialText: widget.initialText,
      onSelected: widget.onChanged,
      onSubmitted: widget.onChanged,
      submitOnChange: true,
      dense: widget.dense,
      optionsBuilder: (v) {
        final List<String> ts = (widget.index == 1
                ? Training.fromPath().cast<String>()
                : Training.tag2s(widget.training?.tag1))
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
