import 'package:flutter/material.dart';

class TimesWidget extends StatelessWidget {
  final void Function(int newCount) onChanged;
  final int value;
  final int max;
  TimesWidget({
    required this.onChanged,
    required this.value,
    required this.max,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(value % max + 1),
      onLongPress: () => onChanged(1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Text(
            'x',
            style: Theme.of(context).textTheme.overline,
          ),
          Text(
            value.toString(),
            style: Theme.of(context).textTheme.headline5!.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Color.lerp(
                    Theme.of(context).primaryColorDark,
                    Colors.redAccent[700],
                    value / max,
                  ),
                ),
          ),
        ],
      ),
    );
  }
}
