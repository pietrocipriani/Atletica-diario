import 'package:atletica/refactoring/common/common.dart';
import 'package:flutter/material.dart';

/// [Widget] showing an icon representation of a given [Tipologia]
abstract class TipologiaIcon extends StatelessWidget {
  /// the color of the Icon
  final Color? color;

  factory TipologiaIcon.from({final Key? key, required final Tipologia tipologia, final Color? color}) {
    switch (tipologia) {
      case Tipologia.corsaDist:
        return _CorsaDistTipologiaIcon(key: key, color: color);
      case Tipologia.corsaTime:
        return _CorsaTimeTipologiaIcon(key: key, color: color);
    }
  }

  /// Constructor for derived classes
  const TipologiaIcon._({super.key, this.color});
}

/// The [TipologiaIcon] for [Tipologia.corsaDist]
class _CorsaDistTipologiaIcon extends TipologiaIcon {
  const _CorsaDistTipologiaIcon({super.key, super.color}) : super._();

  @override
  Widget build(final BuildContext context) {
    return Icon(
      Icons.directions_run,
      color: color,
    );
  }
}

/// The [TipologiaIcon] for [Tipologia.corsaTime]
class _CorsaTimeTipologiaIcon extends TipologiaIcon {
  const _CorsaTimeTipologiaIcon({super.key, super.color}) : super._();

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
