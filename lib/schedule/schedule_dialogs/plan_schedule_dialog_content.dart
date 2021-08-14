/*import 'package:atletica/plan/tabella.dart';
import 'package:atletica/schedule/schedule.dart';
import 'package:flutter/material.dart';

class PlanScheduleDialogContent extends StatelessWidget {
  final void Function() onChanged;
  final PlanSchedule schedule;

  PlanScheduleDialogContent(
      {required this.schedule, required this.onChanged});

  String _format(DateTime d) => d == null
      ? 'seleziona'
      : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year % 100}';

  @override
  Widget build(BuildContext context) {
    if (plans.isEmpty)
      return Row(
        children: <Widget>[
          Expanded(
            child: Text(
              'nessun piano selezionabile, devi prima crearne uno',
              style: Theme.of(context).textTheme.overline,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).primaryColor),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.add),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PlansRoute()),
                );
                onChanged();
              },
            ),
          ),
        ],
      );

    return Column(
      children: <Widget>[
        DropdownButton<Plan>(
          value: schedule.work,
          isExpanded: true,
          items: plans.values
              .map((plan) => DropdownMenuItem<Plan>(
                    value: plan,
                    child: Text(plan.name),
                  ))
              .toList(),
          onChanged: (plan) {
            schedule.workRef = plan.reference;
            onChanged();
          },
        ),
        Row(
          children: <Widget>[
            Text('dal'),
            Expanded(
              child: FlatButton(
                onPressed: () async {
                  schedule.date = await showDatePicker(
                        context: context,
                        initialDate: schedule.date,
                        firstDate: bareDT(DateTime.now().subtract(
                          Duration(
                            days:
                                (DateTime.now().weekday - DateTime.monday) % 7,
                          ),
                        )),
                        helpText: "seleziona la data di inizio",
                        selectableDayPredicate: (day) =>
                            day.weekday == DateTime.monday,
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      ) ??
                      schedule.date;
                  if (schedule.to != null && schedule.date.isAfter(schedule.to))
                    schedule.to = schedule.date;
                  onChanged();
                },
                child: Text(_format(schedule.date)),
              ),
            ),
            Text('al'),
            Expanded(
              child: FlatButton(
                onPressed: () async {
                  schedule.to = await showDatePicker(
                        context: context,
                        initialDate:
                            schedule.to ?? schedule.date.add(Duration(days: 6)),
                        firstDate: schedule.date,
                        helpText:
                            "seleziona la data di fine. Premi a lungo sulla data della schermata precendente per eliminare la scadenza.",
                        selectableDayPredicate: (day) =>
                            day.weekday == DateTime.sunday,
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      ) ??
                      schedule.to;
                  onChanged();
                },
                onLongPress: () {
                  schedule.to = null;
                  onChanged();
                },
                child: Text(_format(schedule.to)),
              ),
            )
          ],
        ),
      ],
    );
  }
}
*/
