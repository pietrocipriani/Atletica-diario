import 'package:atletica/global_widgets/delete_confirm_dialog.dart';
import 'package:atletica/global_widgets/leading_info_widget.dart';
import 'package:atletica/training/variant.dart';
import 'package:flutter/material.dart';

class VariantSelectionWidget extends StatefulWidget {
  final List<Variant> variants;
  final Variant active;
  final void Function(Variant) onVariantChanged;
  VariantSelectionWidget({
    @required this.variants,
    this.active,
    this.onVariantChanged,
  });

  @override
  _VariantSelectionWidgetState createState() => _VariantSelectionWidgetState();
}

class _VariantSelectionWidgetState extends State<VariantSelectionWidget> {
  Variant active;

  @override
  void initState() {
    active = widget.active ?? widget.variants.first;
    super.initState();
  }

  Widget addButton(final int insertIndex) {
    return IconButton(
      icon: Icon(Icons.add_circle),
      onPressed: widget.variants.length < 6
          ? () => setState(
              () => widget.variants.insert(insertIndex, Variant.from(active)))
          : null,
      color: IconTheme.of(context).color,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    int difficulty = 0;
    Iterable<Widget> children = widget.variants
        .map((v) => GestureDetector(
              onTap: () {
                setState(() => active = v);
                widget.onVariantChanged.call(v);
              },
              onLongPress: widget.variants.length > 1
                  ? () async {
                      if (await showDeleteConfirmDialog(
                              context: context, name: 'questa variante') ??
                          false) {
                        setState(() {
                          widget.variants.remove(v);
                          if (active == v) {
                            widget.onVariantChanged
                                ?.call(widget.variants.first);
                            active = widget.variants.first;
                          }
                        });
                      }
                    }
                  : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color:
                        v == active ? theme.primaryColor : theme.disabledColor,
                    width: 2,
                  ),
                ),
                child: LeadingInfoWidget(info: '${++difficulty}'),
              ),
            ))
        .toList();
    int insertIndex = 0;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: children
            .expand((w) => [
                  if (w == children.first) addButton(insertIndex++),
                  w,
                  addButton(insertIndex++)
                ])
            .toList(),
      ),
    );
  }
}
