import 'package:atletica/athlete/atleta.dart';
import 'package:atletica/persistence/auth.dart';
import 'package:atletica/persistence/firestore.dart';
import 'package:atletica/plan/widgets/trainings_wrapper.dart';
import 'package:atletica/schedule/athletes_picker.dart';
import 'package:atletica/schedule/schedule.dart';
import 'package:atletica/training/allenamento.dart';
import 'package:atletica/training/training_chip.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
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
  final List<Allenamento> trainings = [];
  final List<ScheduledTraining> prev = [];
  final Map<Allenamento, List<Athlete>> athletes = Map();
  Allenamento _selectAthletes;

  @override
  void initState() {
    userC.scheduledTrainings[widget.selectedDay]?.forEach((a) {
      trainings.add(a.work);
      prev.add(a);
      athletes[a.work] = a.athletes
          .map((a) => userC.rawAthletes[a])
          .where((a) => a != null)
          .toList();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final Widget title = _selectAthletes == null
        ? Text(DateFormat.yMMMMd('it').format(widget.selectedDay))
        : Row(
            children: [
              GestureDetector(
                child: Icon(Icons.arrow_back),
                onTap: () => setState(() => _selectAthletes = null),
              ),
              SizedBox(width: 8),
              Text('SCEGLI'),
            ],
          );

    final Widget content = _selectAthletes == null
        ? TrainingsWrapper(
            builder: (a) => GestureDetector(
              onTap: () => setState(() => trainings.contains(a)
                  ? trainings.remove(a)
                  : trainings.add(a)),
              onLongPress: trainings.contains(a)
                  ? () => setState(() => _selectAthletes = a)
                  : null,
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: TrainingChip(
                  training: a,
                  enabled: trainings.contains(a),
                ),
              ),
            ),
          )
        : AthletesPicker(athletes[_selectAthletes] ??= [],
            onChanged: (a) => setState(() {}));

    return AlertDialog(
      title: title,
      content: content,
      scrollable: true,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Annulla'),
        ),
        TextButton(
          onPressed: _selectAthletes == null
              ? () {
                  final WriteBatch batch = firestore.batch();

                  for (Allenamento a in trainings) {
                    final ScheduledTraining st = prev.firstWhere(
                      (st) => st.workRef == a.reference,
                      orElse: () => null,
                    );

                    if (st == null)
                      ScheduledTraining.create(
                        work: a.reference,
                        date: widget.selectedDay,
                        athletes:
                            athletes[a]?.map((a) => a.reference)?.toList(),
                        batch: batch,
                      );
                    else if (!listEquals<DocumentReference>(
                      athletes[a]?.map((a) => a.reference)?.toList(),
                      st.athletes,
                    ))
                      st.update(
                        athletes: athletes[a]?.map((a) => a.reference)?.toList(),
                        batch: batch,
                      );
                  }

                  for (ScheduledTraining st in prev)
                    if (trainings.every((a) => a.reference != st.workRef))
                      batch.delete(st.reference);

                  batch.commit();
                  Navigator.pop(context, true);
                }
              : () => setState(() => _selectAthletes = null),
          child: Text('Seleziona'),
        )
      ],
    );
  }
}
