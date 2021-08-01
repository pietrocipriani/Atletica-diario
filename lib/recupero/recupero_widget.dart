import 'package:atletica/recupero/recupero.dart';
import 'package:atletica/recupero/recupero_dialog.dart';
import 'package:flutter/material.dart';

class RecuperoWidget extends StatefulWidget {
  final Recupero recupero;
  RecuperoWidget({required this.recupero});

  @override
  State<RecuperoWidget> createState() => _RecuperoWidgetExtendedState();
}

class _RecuperoWidgetExtendedState extends State<RecuperoWidget> {
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      children: <Widget>[
        Container(width: 40, height: 1, color: theme.primaryColor),
        GestureDetector(
          onTap: () async {
            await showRecoverDialog(context, widget.recupero);
            setState(() {});
          },
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: theme.primaryColor,
              borderRadius: BorderRadius.circular(12.0 + 4),
            ),
            child: Row(
              children: <Widget>[
                Icon(Icons.timer, color: theme.colorScheme.onPrimary),
                Text(
                  widget.recupero.toString(),
                  style: theme.textTheme.overline!
                      .copyWith(color: theme.colorScheme.onPrimary),
                )
              ],
            ),
          ),
        ),
        Expanded(child: Container(height: 1, color: theme.primaryColor))
      ],
    );
  }
}
