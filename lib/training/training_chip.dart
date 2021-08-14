import 'package:atletica/training/training.dart';
import 'package:flutter/material.dart';

/// return a [Chip] relative to a given [Training]
class TrainingChip extends StatelessWidget {
  /// the given `training`
  final Training training;

  /// for more info see [Chip.elevation]
  final double elevation;

  /// if `!enabled` the chip is greyed out
  final bool enabled;

  /// called when [Chip.onDeleted] is triggered
  final void Function()? onDelete;

  TrainingChip({
    required this.training,
    this.elevation = 0,
    this.enabled = true,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: Chip(
        elevation: elevation,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: theme.dialogBackgroundColor,
        shape: StadiumBorder(
          side: BorderSide(
            color: enabled ? theme.primaryColor : theme.disabledColor,
          ),
        ),
        label: Text(
          training.name,
          style: theme.textTheme.overline!.copyWith(
            color: enabled ? null : theme.disabledColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        onDeleted: onDelete,
      ),
    );
  }
}
