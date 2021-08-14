/*import 'package:atletica/schedule/schedule.dart';
import 'package:atletica/schedule/schedule_widgets/schedule_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mdi/mdi.dart';

class PlanScheduleWidget extends ScheduleWidget<PlanSchedule> {
  PlanScheduleWidget({required PlanSchedule schedule})
      : super(
          schedule: schedule,
          leading: Icon(Mdi.table, color: Colors.black),
        );

  @override
  Widget subtitle(BuildContext context) {
    TextStyle base =
        TextStyle(color: Colors.black, fontWeight: FontWeight.normal);
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(text: 'dal ', style: base),
          TextSpan(text: DateFormat.MMMMd('it').format(schedule.date)),
          if (schedule.to != null) TextSpan(text: ' al ', style: base),
          if (schedule.to != null)
            TextSpan(
              text: DateFormat.MMMMd('it').format(schedule.to),
            )
        ],
        style: Theme.of(context).textTheme.overline!.copyWith(
              color: Theme.of(context).primaryColorDark,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}*/
