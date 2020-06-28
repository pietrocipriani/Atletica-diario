import 'package:Atletica/schedule/schedule.dart';
import 'package:flutter/material.dart';

abstract class ScheduleWidget<T extends Schedule> extends StatelessWidget {
  final T schedule;
  final Icon leading;
  ScheduleWidget({Key key, @required this.schedule, @required this.leading}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(schedule),
      child: ListTile(
        title: Text(schedule.work.name),
        subtitle: subtitle(context),
        leading: leading,
      ),
      onDismissed: (d) => schedules.remove(schedule),
    );
  }

  Widget subtitle (BuildContext context);


}
