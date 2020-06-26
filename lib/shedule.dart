import 'package:Atletica/allenamento.dart';
import 'package:Atletica/atleta.dart';
import 'package:Atletica/tabella.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

List<Schedule> schedules = <Schedule>[
  PlanSchedule(plans.first,
      date: DateTime.now(),
      to: DateTime.now().add(Duration(days: 30)),
      athletes: groups.first.atleti),
  TrainingSchedule(allenamenti.first,
      date: DateTime.now(),
      athletes: groups.last.atleti
          .followedBy(groups.first.atleti.getRange(0, 2))
          .toList())
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
        children: schedules.map((schedule) => schedule.build(context)).toList(),
      ),
    );
  }
}

abstract class Schedule<T extends dynamic> {
  final T work;
  DateTime date;
  List<Atleta> athletes = <Atleta>[];

  Schedule(this.work, {this.date, this.athletes});

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

  Widget build(BuildContext context) {
    return ListTile(
      title: Text(work.name),
      subtitle: Text('$formattedDate\n$joinAthletes'),
    );
  }

  String get formattedDate => DateFormat.MMMMd('it').format(date).toString();
}

class PlanSchedule extends Schedule<Tabella> {
  DateTime to;

  PlanSchedule(Tabella plan, {DateTime date, this.to, List<Atleta> athletes})
      : super(plan, date: date, athletes: athletes);

  @override
  String get formattedDate =>
      'dal ${super.formattedDate} al ${DateFormat.yMMMMd('it').format(to)}';
}

class TrainingSchedule extends Schedule<Allenamento> {
  TrainingSchedule(Allenamento training, {DateTime date, List<Atleta> athletes})
      : super(training, date: date, athletes: athletes);
}
