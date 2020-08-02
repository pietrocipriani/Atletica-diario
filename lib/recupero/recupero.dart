import 'dart:async';

import 'package:Atletica/global_widgets/duration_picker.dart';
import 'package:flutter/material.dart';

class Recupero {
  int _recupero;

  Recupero([this._recupero = 3*60]) : assert(_recupero >= 0);
  int get recupero => _recupero;
  set recupero(int recupero) {
    if (recupero < 0)
      throw ArgumentError('Il recupero non può essere negativo');
    _recupero = recupero;
  }

  @override
  String toString () => '${_recupero ~/ 60}:${(_recupero % 60).toString().padLeft(2, '0')}';

  Widget widget(BuildContext context, void Function(void Function()) setState,
          {FutureOr<void> Function() onChanged}) =>
      Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 1,
            color: Theme.of(context).primaryColor,
          ),
          GestureDetector(
            onTap: () async {
              recupero = (await showDurationDialog(
                          context, Duration(seconds: recupero)))
                      .inSeconds ??
                  recupero;
              onChanged?.call();
              setState(() {});
            },
            child: Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColorLight,
                borderRadius: BorderRadius.circular(
                  12.0 + 4,
                ),
              ),
              child: Row(
                children: <Widget>[
                  Icon(Icons.timer),
                  Text(
                    '${recupero ~/ 60}:${(recupero % 60).toString().padLeft(2, '0')}',
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
