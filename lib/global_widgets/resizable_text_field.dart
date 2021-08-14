import 'package:flutter/material.dart';

class ResizableTextField extends StatefulWidget {
  final void Function(String) onChanged;
  final TextEditingController _controller;
  final String? hint;

  ResizableTextField({required this.onChanged, initialText = '', this.hint})
      : _controller = TextEditingController(text: initialText);

  @override
  _ResizableTextFieldState createState() => _ResizableTextFieldState();
}

class _ResizableTextFieldState extends State<ResizableTextField> {
  bool collapsed = true;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: Duration(milliseconds: 200),
        height: collapsed ? kToolbarHeight : 200,
        child: Row(
          children: <Widget>[
            IconButton(
              icon: Icon(
                collapsed ? Icons.expand_more : Icons.expand_less,
                color: Theme.of(context).primaryColorDark,
              ),
              onPressed: () => setState(
                () => collapsed = !collapsed,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: widget._controller,
                  maxLines: 1000,
                  autofocus: false,
                  decoration: InputDecoration(hintText: widget.hint),
                  onChanged: widget.onChanged,
                ),
              ),
            ),
          ],
        ),
      );
}
