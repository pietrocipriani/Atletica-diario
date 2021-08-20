import 'package:atletica/athlete/athlete.dart';
import 'package:atletica/date.dart';
import 'package:atletica/persistence/firestore.dart';
import 'package:atletica/plan/widgets/trainings_wrapper.dart';
import 'package:atletica/schedule/athletes_picker.dart';
import 'package:atletica/schedule/schedule.dart';
import 'package:atletica/training/training.dart';
import 'package:atletica/training/training_chip.dart';
import 'package:atletica/main.dart' show IterableExtension;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ScheduledTrainingDialog extends StatefulWidget {
  final Date selectedDay;

  ScheduledTrainingDialog(this.selectedDay);

  @override
  _ScheduledTrainingDialogState createState() =>
      _ScheduledTrainingDialogState();
}

class _ScheduledTrainingDialogState extends State<ScheduledTrainingDialog> {
  final List<Training> trainings = [];
  final List<ScheduledTraining> prev = [];
  final Map<Training, List<Athlete>> athletes = Map();
  Training? _selectAthletes;

  @override
  void initState() {
    ScheduledTraining.ofDate(widget.selectedDay)
        .where((a) => a.work != null)
        .forEach((a) {
      trainings.add(a.work!);
      prev.add(a);
      athletes[a.work!] = a.athletes.toList();
    });
    super.initState();
  }

  Widget _trainingChipBuilder(final Training a) => GestureDetector(
        onTap: () => setState(() {
          if (trainings.contains(a))
            trainings.remove(a);
          else {
            trainings.add(a);
            _selectAthletes = a;
          }
        }),
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
      );

  @override
  Widget build(BuildContext context) {
    final Widget title = _selectAthletes == null
        ? Text(DateFormat.yMMMMd('it').format(widget.selectedDay))
        : Text(
            _selectAthletes!.name,
            overflow: TextOverflow.ellipsis,
          );

    final Widget content = _selectAthletes == null
        ? TrainingsWrapper(
            builder: _trainingChipBuilder,
            trainings: trainings,
          )
        : AthletesPicker(
            athletes[_selectAthletes!] ??= [],
            onChanged: (a) => setState(() {}),
          );

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

                  for (Training a in trainings) {
                    final ScheduledTraining? st = prev
                        .firstWhereNullable((st) => st.workRef == a.reference);

                    final Set<DocumentReference>? difference =
                        st == null ? null : Set.from(st.athletesRefs);
                    if (difference != null)
                      athletes[a]?.map((a) => a.reference).forEach((a) {
                        if (!difference.add(a)) difference.remove(a);
                      });

                    if (st == null)
                      ScheduledTraining.create(
                        work: a,
                        date: widget.selectedDay,
                        athletes: athletes[a]?.map((a) => a.reference).toList(),
                        batch: batch,
                      );
                    else if (difference!.isNotEmpty)
                      st.update(
                        athletes: athletes[a]?.map((a) => a.reference).toList(),
                        removedAthletes: st.athletesRefs.toList(),
                        batch: batch,
                      );
                  }

                  for (ScheduledTraining st in prev)
                    if (trainings.every((a) => a.reference != st.workRef))
                      batch.delete(st.reference);

                  batch.commit();
                  Navigator.pop(context, true);
                }
              : athletes[_selectAthletes!]!.isNotEmpty
                  ? () => setState(() => _selectAthletes = null)
                  : null,
          child: Text('Seleziona'),
        )
      ],
    );
  }
}
