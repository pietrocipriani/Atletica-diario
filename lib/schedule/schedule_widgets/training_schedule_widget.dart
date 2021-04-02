/*import 'package:atletica/schedule/schedule.dart';
import 'package:atletica/schedule/schedule_widgets/schedule_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TrainingScheduleWidget extends ScheduleWidget<TrainingSchedule> {
  TrainingScheduleWidget({@required TrainingSchedule schedule})
      : super(
          schedule: schedule,
          leading: Icon(Icons.fitness_center, color: Colors.black),
        );

  @override
  Widget subtitle(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(text: DateFormat.MMMMd('it').format(schedule.date))
        ],
        style: Theme.of(context).textTheme.overline.copyWith(
              color: Theme.of(context).primaryColorDark,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}*/
