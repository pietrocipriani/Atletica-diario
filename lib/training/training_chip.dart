import 'package:Atletica/training/allenamento.dart';
import 'package:flutter/material.dart';

/// return a [Chip] relative to a given [Allenamento]
class TrainingChip extends StatelessWidget {
  /// the given `training`
  final Allenamento training;

  /// for more info see [Chip.elevation]
  final double elevation;

  /// if `!enabled` the chip is greyed out
  final bool enabled;

  /// called when [Chip.onDeleted] is triggered
  final void Function() onDelete;

  TrainingChip({
    @required this.training,
    this.elevation = 0,
    this.enabled = true,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Chip(
        elevation: elevation,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: Theme.of(context).dialogBackgroundColor,
        shape: StadiumBorder(
          side: BorderSide(
            color: enabled ? Theme.of(context).primaryColor : Colors.grey[300],
          ),
        ),
        label: Text(
          training.name,
          style: Theme.of(context).textTheme.overline.copyWith(
              color: enabled ? null : Colors.grey[300],
              fontWeight: FontWeight.bold),
        ),
        onDeleted: onDelete,
      ),
    );
  }
}
