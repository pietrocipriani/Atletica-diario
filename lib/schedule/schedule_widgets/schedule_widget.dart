import 'package:Atletica/global_widgets/custom_dismissible.dart';
import 'package:Atletica/global_widgets/delete_confirm_dialog.dart';
import 'package:Atletica/running_training/running_training.dart';
import 'package:Atletica/schedule/schedule.dart';
import 'package:flutter/material.dart';

abstract class ScheduleWidget<T extends Schedule> extends StatelessWidget {
  final T schedule;
  final Icon leading;
  ScheduleWidget({Key key, @required this.schedule, @required this.leading})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomDismissible(
      key: ValueKey(schedule),
      child: ListTile(
        title: Text(schedule.work.name),
        subtitle: subtitle(context),
        leading: leading,
      ),
      onDismissed: (d) {
        schedules.remove(schedule);
        updateFromSchedules();
      },
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) return false;
        return await showDeleteConfirmDialog(
            context: context, name: '${schedule.work.name} per ${schedule.joinAthletes}');
      },
    );
  }

  Widget subtitle(BuildContext context);
}
