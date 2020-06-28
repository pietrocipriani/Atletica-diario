import 'package:Atletica/athlete/group.dart';
import 'package:Atletica/schedule/athletes_picker.dart';
import 'package:Atletica/schedule/schedule_widgets/plan_schedule_widget.dart';
import 'package:Atletica/schedule/schedule_widgets/schedule_widget.dart';
import 'package:Atletica/schedule/schedule_widgets/training_schedule_widget.dart';
import 'package:Atletica/training/allenamento.dart';
import 'package:Atletica/athlete/atleta.dart';
import 'package:Atletica/plan/tabella.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

List<Schedule> schedules = <Schedule>[];

abstract class Schedule<T extends dynamic> {
  ScheduleWidget<Schedule<T>> widget;
  T work;
  DateTime date;
  List<Atleta> athletes;

  Schedule(
    this.work, {
    this.date,
    this.athletes = const <Atleta>[],
  });

  static Future<bool> fromDialog(BuildContext context) {
    PlanSchedule plan =
        PlanSchedule(plans.isEmpty ? null : plans.first, date: DateTime.now());
    TrainingSchedule training = TrainingSchedule(
        allenamenti.isEmpty ? null : allenamenti.first,
        date: DateTime.now());
    bool type = false;
    Widget Function(BuildContext context, bool value, String text,
            void Function(void Function()) setState) typeBtn =
        (context, value, text, setState) {
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => type = value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            child: Text(
              text,
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: value == type ? Theme.of(context).primaryColor : null,
              border: Border.all(
                color: value == type ? Colors.transparent : Colors.grey[300],
              ),
            ),
          ),
        ),
      );
    };
    return showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text('Aggiungi'),
          scrollable: true,
          content: Column(children: <Widget>[
            Row(
              children: <Widget>[
                typeBtn(context, false, 'Allenamento', setState),
                typeBtn(context, true, 'Piano', setState)
              ],
            ),
            type ? plan.dialogContent(context) : training.dialogContent(context)
          ]),
          actions: <Widget>[
            FlatButton(
                onPressed: () {
                  Navigator.pop(context, false);
                },
                child: Text('Annulla')),
            FlatButton(
              onPressed: () {
                schedules.add(type ? plan : training);
                Navigator.pop(context, true);
              },
              child: Text('Aggiungi'),
            )
          ],
        ),
      ),
    );
  }

  String get joinAthletes {
    if (athletes == null) return '';
    Iterable<Group> gs = groups.where(
      (group) => group.atleti.every(
        (atleta) => athletes.contains(atleta),
      ),
    );
    Iterable<Atleta> atls = athletes
        .where((atleta) => gs.every((group) => !group.atleti.contains(atleta)));
    return gs.map((g) => g.name).followedBy(atls.map((a) => a.name)).join(', ');
  }
}

class PlanSchedule extends Schedule<Tabella> {
  DateTime to;

  PlanSchedule(Tabella plan, {DateTime date, this.to, List<Atleta> athletes})
      : super(plan, date: date, athletes: athletes ?? <Atleta>[]) {
    widget = PlanScheduleWidget(schedule: this);
  }

  Widget dialogContent(BuildContext context) {
    if (plans.isEmpty)
      return Text('nessun piano selezionabile, devi prima crearne uno');
    final String Function(DateTime) format =
        (d) => d == null ? 'seleziona' : '${d.day}/${d.month}/${d.year % 100}';

    return StatefulBuilder(builder: (context, setState) {
      return Column(
        children: <Widget>[
          DropdownButton<Tabella>(
            value: work,
            isExpanded: true,
            items: plans
                .map(
                  (plan) => DropdownMenuItem<Tabella>(
                    value: plan,
                    child: Text(plan.name),
                  ),
                )
                .toList(),
            onChanged: (plan) => setState(() => work = plan),
          ),
          Row(
            children: <Widget>[
              Text('dal'),
              Expanded(
                child: FlatButton(
                  onPressed: () async {
                    date = await showDatePicker(
                          context: context,
                          initialDate: date,
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        ) ??
                        date;
                    if (to != null && date.isAfter(to)) to = date;
                    setState(() {});
                  },
                  child: Text(format(date)),
                ),
              ),
              Text('al'),
              Expanded(
                child: FlatButton(
                  onPressed: () async {
                    to = await showDatePicker(
                          context: context,
                          initialDate: to ?? date,
                          firstDate: date,
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        ) ??
                        to;
                    setState(() {});
                  },
                  child: Text(
                    format(to),
                  ),
                ),
              )
            ],
          ),
          AthletesPicker(athletes,
              onChanged: (atls) => setState(() => athletes = atls))
        ],
      );
    });
  }
}

class TrainingSchedule extends Schedule<Allenamento> {
  TrainingSchedule(Allenamento training, {DateTime date, List<Atleta> athletes})
      : super(training, date: date, athletes: athletes ?? <Atleta>[]) {
    widget = TrainingScheduleWidget(schedule: this);
  }

  Widget dialogContent(BuildContext context) {
    if (allenamenti.isEmpty)
      return Text('nessun allenamento selezionabile, devi prima crearne uno');

    return StatefulBuilder(builder: (context, setState) {
      return Column(
        children: <Widget>[
          DropdownButton<Allenamento>(
            value: work,
            isExpanded: true,
            items: allenamenti
                .map(
                  (allenamento) => DropdownMenuItem<Allenamento>(
                    value: allenamento,
                    child: Text(allenamento.name),
                  ),
                )
                .toList(),
            onChanged: (training) => setState(() => work = training),
          ),
          Row(
            children: <Widget>[
              Text('in data: '),
              Expanded(
                child: FlatButton(
                  onPressed: () async {
                    date = await showDatePicker(
                          context: context,
                          initialDate: date,
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        ) ??
                        date;
                    setState(() {});
                  },
                  child: Text(DateFormat.yMMMMd('it').format(date)),
                ),
              ),
            ],
          ),
          AthletesPicker(
            athletes,
            onChanged: (atls) => setState(() => athletes = atls),
          )
        ],
      );
    });
  }
}
