/*import 'package:Atletica/schedule/schedule.dart';
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
  final Map<String, Schedule> schedulesList = <String, Schedule>{
    'Piano': PlanSchedule(),
    'Allenamento': TrainingSchedule(),
  };
  Schedule schedule = schedules.isEmpty || schedules.values.last is PlanSchedule
      ? schedulesList['Piano']
      : schedulesList['Allenamento'];
  return showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Aggiungi'),
        scrollable: true,
        content: Column(children: <Widget>[
          Row(
            children: schedulesList.entries.map(
              (entry) => _typeBtn(
                  context: context,
                  text: entry.key,
                  type: schedule,
                  value: entry.value,
                  onChanged: (s) => setState(() => schedule = s)),
            ).toList(),
          ),
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
                    schedule.create();
                    Navigator.pop(context, true);
                  }
                : null,
            child: Text('Aggiungi'),
          )
        ],
      ),
    ),
  );
}*/
