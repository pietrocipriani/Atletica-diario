import 'package:flutter/cupertino.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:atletica/refactoring/utils/iterable.dart';

/// Form wrapper to select an [E] with Buttons
class EnumSelector<E extends Enum> extends StatefulWidget {
  /// the possible values for the choice. Must be non empty
  final List<E> values;

  /// the widget to display as icon in the button of `value`
  final Widget Function(BuildContext, E value) iconBuilder;

  /// callback for when the value changes
  final void Function(E value)? onSelected;

  final Color Function(E value)? backgroundColor;

  final Widget? leading;

  const EnumSelector({
    required this.values,
    required this.iconBuilder,
    this.onSelected,
    this.backgroundColor,
    this.leading,
  });

  @override
  _EnumSelectorState<E> createState() => _EnumSelectorState();
}

/// [State] for [EnumSelector]
class _EnumSelectorState<E extends Enum> extends State<EnumSelector<E>> {
  late E _value;

  @override
  void initState() {
    _value = widget.values.first;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (widget.leading != null) Expanded(child: widget.leading!),
        ...widget.values
            .map(
              (t) => PlatformElevatedButton(
                onPressed: _value == t
                    ? () {}
                    : () {
                        setState(() => _value = t);
                        widget.onSelected?.call(t);
                      },
                child: widget.iconBuilder(context, t),
                color: _value != t
                    ? platformThemeData(
                        context,
                        material: (theme) => theme.disabledColor,
                        cupertino: (theme) => CupertinoColors.inactiveGray,
                      )
                    : widget.backgroundColor?.call(t),
                padding: EdgeInsets.zero,
              ),
            )
            .separate(() => const SizedBox(width: 4)),
      ],
    );
  }
}
