import 'package:Atletica/allenamento.dart';
import 'package:Atletica/atleta.dart';
import 'package:Atletica/tabella.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mdi/mdi.dart';

List<Schedule> schedules = <Schedule>[
  /*PlanSchedule(plans.first,
      date: DateTime.now(),
      to: DateTime.now().add(Duration(days: 30)),
      athletes: groups.first.atleti),
  TrainingSchedule(allenamenti.first,
      date: DateTime.now(),
      athletes: groups.last.atleti
          .followedBy(groups.first.atleti.getRange(0, 2))
          .toList())*/
];

class ScheduleRoute extends StatefulWidget {
  @override
  _ScheduleRouteState createState() => _ScheduleRouteState();
}

class _ScheduleRouteState extends State<ScheduleRoute> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PROGRAMMI'),
      ),
      body: Column(
        children: schedules
            .map(
              (schedule) => Dismissible(
                key: ValueKey(schedule),
                child: schedule.build(context),
                onDismissed: (d) => schedules.remove(schedule),
              ),
            )
            .toList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (await Schedule.fromDialog(context)) setState(() {});
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

abstract class Schedule<T extends dynamic> {
  T work;
  DateTime date;
  List<Atleta> athletes;

  Schedule(this.work, {this.date, this.athletes = const <Atleta>[]});

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

  Widget get leading;

  Widget subtitle(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: formattedDate,
        children: [
          TextSpan(
            text: ' per ',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.normal,
            ),
          ),
          TextSpan(text: joinAthletes)
        ],
        style: Theme.of(context).textTheme.overline.copyWith(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget build(BuildContext context) {
    return ListTile(
      title: Text(work.name),
      subtitle: subtitle(context),
      leading: leading,
    );
  }

  String get formattedDate => DateFormat.MMMMd('it').format(date).toString();
}

class PlanSchedule extends Schedule<Tabella> {
  DateTime to;

  PlanSchedule(Tabella plan, {DateTime date, this.to, List<Atleta> athletes})
      : super(plan, date: date, athletes: athletes ?? <Atleta>[]);

  @override
  String get formattedDate =>
      'dal ${super.formattedDate} al ${DateFormat.yMMMMd('it').format(to)}';

  @override
  Widget subtitle(BuildContext context) {
    TextStyle base =
        TextStyle(color: Colors.black, fontWeight: FontWeight.normal);
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(text: 'dal ', style: base),
          TextSpan(text: DateFormat.MMMMd('it').format(date)),
          if (to != null) TextSpan(text: ' al ', style: base),
          if (to != null) TextSpan(text: DateFormat.MMMMd('it').format(to)),
          TextSpan(text: ' per ', style: base),
          TextSpan(text: joinAthletes)
        ],
        style: Theme.of(context).textTheme.overline.copyWith(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (date.isAfter(DateTime.now())) return super.build(context);
    return Column(
      children: <Widget>[
        super.build(context),
        Container(
          height: 1,
          child: LinearProgressIndicator(
            backgroundColor: Colors.transparent,
            value: to == null
                ? 0
                : DateTime.now().difference(date).inDays /
                    to.difference(date).inDays,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
          ),
        )
      ],
    );
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

  @override
  Widget get leading => Icon(Mdi.table, color: Colors.black);
}

class TrainingSchedule extends Schedule<Allenamento> {
  TrainingSchedule(Allenamento training, {DateTime date, List<Atleta> athletes})
      : super(training, date: date, athletes: athletes ?? <Atleta>[]);

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
          AthletesPicker(athletes,
              onChanged: (atls) => setState(() => athletes = atls))
        ],
      );
    });
  }

  @override
  Widget get leading => Icon(Icons.fitness_center, color: Colors.black);
}

class AthletesPicker extends StatelessWidget {
  final List<Atleta> athletes;
  final void Function(List<Atleta> athletes) onChanged;

  AthletesPicker(this.athletes, {@required this.onChanged});

  @override
  Widget build(BuildContext context) {
    List<Widget> children = () sync* {
      for (Group g in groups) {
        yield Row(
          children: <Widget>[
            Checkbox(
                value: g.atleti.every((a) => athletes.contains(a)),
                onChanged: (v) {
                  if (v)
                    g.atleti
                        .where((a) => !athletes.contains(a))
                        .forEach((a) => athletes.add(a));
                  else
                    g.atleti.forEach((a) => athletes.remove(a));
                  onChanged(athletes);
                }),
            Text(g.name)
          ],
        );
        for (Atleta a in g.atleti) {
          yield Row(
            children: <Widget>[
              SizedBox(width: 40),
              Checkbox(
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  value: athletes.contains(a),
                  onChanged: (v) {
                    if (v)
                      athletes.add(a);
                    else
                      athletes.remove(a);
                    onChanged(athletes);
                  }),
              Text(a.name),
            ],
          );
        }
      }
    }()
        .toList();

    return Column(children: children);
  }
}
