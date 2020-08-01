import 'package:AtleticaCoach/schedule/athletes_picker.dart';
import 'package:AtleticaCoach/schedule/schedule.dart';
import 'package:AtleticaCoach/training/allenamento.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TrainingScheduleDialogContent extends StatelessWidget {
  final void Function() onChanged;
  final TrainingSchedule schedule;
  TrainingScheduleDialogContent(
      {@required this.onChanged, @required this.schedule});

  @override
  Widget build(BuildContext context) {
    if (allenamenti.isEmpty)
      return Row(
        children: <Widget>[
          Expanded(
            child: Text(
              'nessun allenamento selezionabile, devi prima crearne uno',
              style: Theme.of(context).textTheme.overline,
            ),
          ),
          Container(
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Theme.of(context).primaryColor)),
            child: IconButton(
              icon: Icon(Icons.add),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TrainingRoute()),
                );
                onChanged();
              },
            ),
          ),
        ],
      );

    return Column(
      children: <Widget>[
        DropdownButton<Allenamento>(
          value: schedule.work,
          isExpanded: true,
          items: allenamenti.values
              .map(
                (allenamento) => DropdownMenuItem<Allenamento>(
                  value: allenamento,
                  child: Text(allenamento.name),
                ),
              )
              .toList(),
          onChanged: (training) {
            schedule.workRef = training.reference;
            onChanged();
          },
        ),
        Row(
          children: <Widget>[
            Text('in data: '),
            Expanded(
              child: FlatButton(
                onPressed: () async {
                  schedule.date = await showDatePicker(
                        context: context,
                        initialDate: schedule.date,
                        helpText:
                            "seleziona la data in cui posizionare l'allenamento",
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      ) ??
                      schedule.date;
                  onChanged();
                },
                child: Text(DateFormat.yMMMMd('it').format(schedule.date)),
              ),
            ),
          ],
        ),
        AthletesPicker(
          schedule.athletes,
          onChanged: (athletes) {
            schedule.athletes = athletes;
            onChanged();
          },
        )
      ],
    );
  }
}
