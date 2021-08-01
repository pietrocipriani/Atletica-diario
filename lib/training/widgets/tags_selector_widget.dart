import 'package:atletica/training/training.dart';
import 'package:autocomplete_textfield/autocomplete_textfield.dart';
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
                TextEditingController(text: widget.training.tag1),
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
                  TextEditingController(text: widget.training.tag2),
                  widget.training,
                  2,
                  setState),
            ),
          ),
        ],
      );
}

class _TagTextField extends AutoCompleteTextField<String> {
  _TagTextField(
      final TextEditingController _controller,
      final Training training,
      final int index,
      void Function(void Function()) setState)
      : super(
          key: GlobalKey(),
          controller: _controller,
          itemSubmitted: (tag) => setState(() => _controller.text =
              (index == 1 ? training.tag1 = tag : training.tag2 = tag)),
          textSubmitted: (tag) =>
              index == 1 ? training.tag1 = tag : training.tag2 = tag,
          textChanged: (tag) =>
              index == 1 ? training.tag1 = tag : training.tag2 = tag,
          clearOnSubmit: false,
          suggestions: index == 1
              ? Training.fromPath().cast<String>().toList()
              : Training.tag2s(training.tag1).toList(),
          itemBuilder: (context, suggestion) => Padding(
            padding: const EdgeInsets.all(8.0),
            child: RichText(
              text: TextSpan(
                text: suggestion.substring(
                    0, suggestion.indexOf(_controller.text)),
                style: TextStyle(color: Colors.black),
                children: [
                  TextSpan(
                    text: _controller.text,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: suggestion.substring(
                      suggestion.indexOf(_controller.text) +
                          _controller.text.length,
                    ),
                  ),
                ],
              ),
            ),
          ),
          itemSorter: (a, b) {
            if (a.startsWith(_controller.text) ==
                b.startsWith(_controller.text)) return a.compareTo(b);
            if (a.startsWith(_controller.text)) return -1;
            return 1;
          },
          itemFilter: (suggestion, query) => suggestion.contains(query),
        );
}
