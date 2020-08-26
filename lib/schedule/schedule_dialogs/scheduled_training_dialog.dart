import 'package:Atletica/persistence/auth.dart';
import 'package:Atletica/schedule/schedule.dart';
import 'package:Atletica/training/allenamento.dart';
import 'package:Atletica/training/training_chip.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ScheduledTrainingDialog extends StatefulWidget {
  final DateTime selectedDay;

  ScheduledTrainingDialog(this.selectedDay);

  @override
  _ScheduledTrainingDialogState createState() =>
      _ScheduledTrainingDialogState();
}

class _ScheduledTrainingDialogState extends State<ScheduledTrainingDialog> {
  final List<Allenamento> trainings = List();
  final List<ScheduledTraining> prev = List();

  @override
  void initState() {
    userC.scheduledTrainings[widget.selectedDay]?.forEach((a) {
      trainings.add(a.work);
      prev.add(a);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(DateFormat.yMMMMd('it').format(widget.selectedDay)),
        content: Wrap(
          children: allenamenti.values
              .map(
                (a) => GestureDetector(
                  onTap: () => setState(() => trainings.contains(a)
                      ? trainings.remove(a)
                      : trainings.add(a)),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: TrainingChip(
                      training: a,
                      enabled: trainings.contains(a),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        actions: [
          FlatButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annulla'),
          ),
          FlatButton(
            onPressed: () {
              for (Allenamento a in trainings)
                if (prev.every((st) => st.workRef != a.reference))
                  ScheduledTraining.create(
                    work: a.reference,
                    date: widget.selectedDay,
                  );

              for (ScheduledTraining st in prev)
                if (trainings.every((a) => a.reference != st.workRef))
                  st.reference.delete();
              Navigator.pop(context, true);
            },
            child: Text('Seleziona'),
          )
        ],
      );
}
