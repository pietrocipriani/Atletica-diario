import 'package:Atletica/plan/tabella.dart';
import 'package:Atletica/schedule/schedule.dart';
import 'package:Atletica/training/allenamento.dart';
import 'package:flutter/material.dart';

Widget _typeBtn({
  @required BuildContext context,
  @required String text,
  @required Schedule type,
  @required Schedule value,
  void Function(Schedule value) onChanged,
}) {
  return Expanded(
    child: GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        child: Text(text, textAlign: TextAlign.center, maxLines: 1),
        padding: const EdgeInsets.all(8),
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: value == type ? Theme.of(context).primaryColor : null,
          border: Border.all(
            color: value == type
                ? Theme.of(context).primaryColor
                : Colors.grey[300],
          ),
        ),
      ),
    ),
  );
}

Future<bool> showScheduleDialog({@required BuildContext context}) {
  final List<Schedule> schedulesList = <Schedule>[
    PlanSchedule(
      plans.isEmpty ? null : plans.first,
      date: DateTime.now().add(
        Duration(days: 7 - (DateTime.now().weekday - DateTime.monday) % 7),
      ),
    ),
    TrainingSchedule(
      allenamenti.isEmpty ? null : allenamenti.values.first,
      date: DateTime.now(),
    )
  ];
  Schedule schedule = schedules.isEmpty || schedules.first is PlanSchedule
      ? schedulesList.first
      : schedulesList.last;
  return showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Aggiungi'),
        scrollable: true,
        content: Column(children: <Widget>[
          Row(children: <Widget>[
            _typeBtn(
              context: context,
              text: 'Piano',
              type: schedule,
              value: schedulesList.first,
              onChanged: (s) => setState(() => schedule = s),
            ),
            _typeBtn(
              context: context,
              text: 'Allenamento',
              type: schedule,
              value: schedulesList.last,
              onChanged: (s) => setState(() => schedule = s),
            ),
          ]),
          schedule.content(context: context, onChanged: () => setState(() {})),
        ]),
        actions: <Widget>[
          FlatButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annulla'),
          ),
          FlatButton(
            onPressed: schedule.isOk
                ? () {
                    schedules.add(schedule);
                    Navigator.pop(context, true);
                  }
                : null,
            child: Text('Aggiungi'),
          )
        ],
      ),
    ),
  );
}
