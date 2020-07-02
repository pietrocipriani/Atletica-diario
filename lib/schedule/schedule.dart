import 'package:Atletica/athlete/group.dart';
import 'package:Atletica/schedule/schedule_dialogs/plan_schedule_dialog_content.dart';
import 'package:Atletica/schedule/schedule_dialogs/training_schedule_dialog_content.dart';
import 'package:Atletica/schedule/schedule_widgets/plan_schedule_widget.dart';
import 'package:Atletica/schedule/schedule_widgets/schedule_widget.dart';
import 'package:Atletica/schedule/schedule_widgets/training_schedule_widget.dart';
import 'package:Atletica/training/allenamento.dart';
import 'package:Atletica/athlete/atleta.dart';
import 'package:Atletica/plan/tabella.dart';
import 'package:flutter/material.dart';

List<Schedule> schedules = <Schedule>[];

DateTime bareDT([DateTime dt]) {
  dt ??= DateTime.now();
  dt = dt.toUtc();
  return DateTime.utc(dt.year, dt.month, dt.day);
}

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

  Allenamento get todayTraining;

  bool get isOk => work != null && date != null && athletes.isNotEmpty;

  Widget content({
    @required BuildContext context,
    @required void Function() onChanged,
  });

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

  @override
  Widget content({BuildContext context, void Function() onChanged}) {
    return PlanScheduleDialogContent(onChanged: onChanged, schedule: this);
  }

  @override
  Allenamento get todayTraining {
    if (work.weeks.isEmpty) return null;
    final DateTime bareStart = bareDT(date), bareToday = bareDT();
    int week = bareToday.difference(bareStart).inDays;
    if (week < 0) return null;
    week = (week ~/ 7) % work.weeks.length;
    return allenamenti[work.weeks[week].trainings[bareToday.weekday]];
  }
}

class TrainingSchedule extends Schedule<Allenamento> {
  TrainingSchedule(Allenamento training, {DateTime date, List<Atleta> athletes})
      : super(training, date: date, athletes: athletes ?? <Atleta>[]) {
    widget = TrainingScheduleWidget(schedule: this);
  }

  @override
  Widget content({BuildContext context, void Function() onChanged}) {
    return TrainingScheduleDialogContent(onChanged: onChanged, schedule: this);
  }

  @override
  bool get isOk => super.isOk && !bareDT().isAfter(bareDT(date));

  @override
  Allenamento get todayTraining => bareDT(date) == bareDT() ? work : null;
}
