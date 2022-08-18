import 'package:atletica/refactoring/model/tipologia.dart';
import 'package:flutter/material.dart';

abstract class TipologiaIcon extends StatelessWidget {
  final Color? color;

  factory TipologiaIcon.from({final Key? key, required final Tipologia tipologia, final Color? color}) {
    switch (tipologia) {
      case Tipologia.corsaDist:
        return _CorsaDistTipologiaIcon(key: key, color: color);
      case Tipologia.corsaTime:
        return _CorsaTimeTipologiaIcon(key: key, color: color);
    }
  }

  const TipologiaIcon({super.key, this.color});
}

class _CorsaDistTipologiaIcon extends TipologiaIcon {
  const _CorsaDistTipologiaIcon({super.key, super.color});

  @override
  Widget build(final BuildContext context) {
    return Icon(
      Icons.directions_run,
      color: color,
    );
  }
}

class _CorsaTimeTipologiaIcon extends TipologiaIcon {
  const _CorsaTimeTipologiaIcon({super.key, super.color});

  @override
  Widget build(final BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: <Widget>[
        Icon(
          Icons.directions_run,
          color: color,
        ),
        Positioned(
          right: -3,
          bottom: -3,
          child: Icon(
            Icons.timer,
            size: 10,
            color: color,
          ),
        ),
      ],
    );
  }
}
