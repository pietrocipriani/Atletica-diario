import 'package:flutter/material.dart';

class AutoCompleteTextView<T extends Object> extends StatefulWidget {
  final void Function(T)? onSelected;
  final void Function(String)? onSubmitted;
  final bool submitOnChange;
  final String Function(T)? displayStringForOption;
  final Iterable<T> Function(TextEditingValue) optionsBuilder;
  final String? initialText;
  final bool dense;

  AutoCompleteTextView({
    final GlobalKey? key,
    required this.optionsBuilder,
    this.onSelected,
    this.onSubmitted,
    this.submitOnChange = false,
    this.displayStringForOption,
    this.initialText,
    this.dense = false,
  }) : super(key: key ?? GlobalKey());

  @override
  State<StatefulWidget> createState() => _AutoCompleteTextViewState<T>();
}

class _AutoCompleteTextViewState<T extends Object>
    extends State<AutoCompleteTextView<T>> {
  TextEditingController? _controller;
  double? _width;

  set controller(final TextEditingController c) {
    if (_controller != null && c == _controller) return;
    if (_controller == null)
      c.text = _controller?.text ?? widget.initialText ?? '';
    else
      WidgetsBinding.instance!.addPostFrameCallback((_) {
        c.text = _controller?.text ?? widget.initialText ?? '';
      });
    _controller = c;
  }

  TextEditingController get controller {
    return _controller!;
  }

  double? get _formWidth {
    try {
      return (widget.key as GlobalKey).currentContext?.size?.width;
    } on AssertionError catch (e) {
      print(e);
      return null;
    }
  }

  @override
  void initState() {
    WidgetsBinding.instance?.addPostFrameCallback((_) => _width = _formWidth);
    super.initState();
  }

  @override
  void didUpdateWidget(AutoCompleteTextView<T> oldWidget) {
    WidgetsBinding.instance?.addPostFrameCallback((_) => _width = _formWidth);
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return Autocomplete<T>(
      onSelected: widget.onSelected,
      fieldViewBuilder: (context, controller, focus, onSubmit) {
        return TextFormField(
          focusNode: focus,
          controller: this.controller = controller,
          style: widget.dense
              ? Theme.of(context)
                  .textTheme
                  .overline!
                  .copyWith(fontWeight: FontWeight.normal)
              : null,
          decoration: InputDecoration(
            isDense: widget.dense,
            hintText: 'ricerca allenamento',
          ),
          onTap: () {
            if (focus.hasFocus)
              FocusScope.of(context).requestFocus(FocusNode());
          },
          onFieldSubmitted: (s) {
            widget.onSubmitted?.call(s);
            onSubmit();
          },
          onChanged: widget.submitOnChange ? widget.onSubmitted : null,
        );
      },
      optionsViewBuilder: (context, onSelected, options) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 4,
          child: ConstrainedBox(
            constraints: BoxConstraints.loose(
              _width == null ? const Size.fromHeight(200) : Size(_width!, 200),
            ),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(0),
              children: options.map(
                (suggestion) {
                  final String name =
                      widget.displayStringForOption?.call(suggestion) ??
                          suggestion.toString();
                  return InkWell(
                    onTap: () => onSelected(suggestion),
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      child: RichText(
                        text: TextSpan(
                          style: widget.dense
                              ? Theme.of(context)
                                  .textTheme
                                  .overline!
                                  .copyWith(fontWeight: FontWeight.normal)
                              : null,
                          text:
                              name.substring(0, name.indexOf(controller.text)),
                          children: [
                            TextSpan(
                              text: controller.text,
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                            TextSpan(
                              text: name.substring(
                                  name.indexOf(controller.text) +
                                      controller.text.length),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ).toList(),
            ),
          ),
        ),
      ),
      optionsBuilder: widget.optionsBuilder,
    );
  }
}
