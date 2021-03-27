import 'package:Atletica/recupero/recupero.dart';
import 'package:Atletica/recupero/recupero_dialog.dart';
import 'package:flutter/material.dart';

class RecuperoWidget extends StatefulWidget {
  final Recupero recupero;
  RecuperoWidget({@required this.recupero});

  @override
  State<RecuperoWidget> createState() => _RecuperoWidgetExtendedState();
}

class _RecuperoWidgetExtendedState extends State<RecuperoWidget> {
  @override
  Widget build(BuildContext context) => Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 1,
            color: Theme.of(context).primaryColor,
          ),
          GestureDetector(
            onTap: () async {
              await showRecoverDialog(context, widget.recupero);
              setState(() {});
            },
            child: Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColorLight,
                borderRadius: BorderRadius.circular(12.0 + 4),
              ),
              child: Row(
                children: <Widget>[
                  Icon(Icons.timer),
                  Text(
                    widget.recupero.toString(),
                    style: Theme.of(context).textTheme.overline,
                  )
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              color: Theme.of(context).primaryColor,
            ),
          )
        ],
      );
}
