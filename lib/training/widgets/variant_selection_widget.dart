import 'dart:math';

import 'package:atletica/global_widgets/delete_confirm_dialog.dart';
import 'package:atletica/global_widgets/leading_info_widget.dart';
import 'package:atletica/training/variant.dart';
import 'package:flutter/material.dart';

class VariantSelectionWidget extends StatefulWidget {
  final List<Variant> variants;
  final Variant? active;
  final void Function(Variant) onVariantChanged;
  VariantSelectionWidget({
    required this.variants,
    this.active,
    required this.onVariantChanged,
  });

  @override
  _VariantSelectionWidgetState createState() => _VariantSelectionWidgetState();
}

class _VariantSelectionWidgetState extends State<VariantSelectionWidget> {
  late Variant active = widget.active ?? widget.variants.first;

  Widget addButton(final int insertIndex) {
    return IconButton(
      icon: Icon(Icons.add_circle),
      onPressed: widget.variants.length < 6
          ? () => setState(() => widget.variants.insert(
                insertIndex,
                Variant.from(widget
                    .variants[min(insertIndex, widget.variants.length - 1)]),
              ))
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
                          context: context, name: 'questa variante')) {
                        setState(() {
                          final int index = min(widget.variants.indexOf(v),
                              widget.variants.length - 2);
                          widget.variants.remove(v);
                          if (active == v) {
                            widget.onVariantChanged
                                .call(active = widget.variants[index]);
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
