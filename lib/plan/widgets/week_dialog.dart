import 'package:atletica/plan/week.dart';
import 'package:atletica/plan/widgets/draggable_days_week_widget.dart';
import 'package:atletica/plan/widgets/trainings_wrapper.dart';
import 'package:atletica/training/allenamento.dart';
import 'package:atletica/training/training_chip.dart';
import 'package:flutter/material.dart';

class WeekDialog extends StatelessWidget {
  final Week week;
  WeekDialog(this.week);

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DraggableDaysWeekWidget(week),
          Container(
            width: double.infinity,
            height: 1,
            color: Theme.of(context).disabledColor,
            margin: const EdgeInsets.all(8),
          ),
          TrainingsWrapper(
            builder: (value) => Draggable<Allenamento>(
              maxSimultaneousDrags: 1,
              data: value,
              feedback: TrainingChip(training: value, elevation: 6),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: TrainingChip(training: value),
              ),
              childWhenDragging: Padding(
                padding: const EdgeInsets.all(4),
                child: TrainingChip(
                  training: value,
                  enabled: false,
                ),
              ),
            ),
          ),
        ],
      );
}
