import 'package:Atletica/athlete/group.dart';
import 'package:Atletica/persistence/auth.dart';
import 'package:Atletica/schedule/schedule_dialogs/plan_schedule_dialog_content.dart';
import 'package:Atletica/schedule/schedule_dialogs/training_schedule_dialog_content.dart';
import 'package:Atletica/schedule/schedule_widgets/plan_schedule_widget.dart';
import 'package:Atletica/schedule/schedule_widgets/schedule_widget.dart';
import 'package:Atletica/schedule/schedule_widgets/training_schedule_widget.dart';
import 'package:Atletica/training/allenamento.dart';
import 'package:Atletica/athlete/atleta.dart';
import 'package:Atletica/plan/tabella.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

Map<DocumentReference, Schedule> schedules = <DocumentReference, Schedule>{};
Iterable<Schedule> get avaiableSchedules =>
    schedules.values.where((s) => s.athletes.isNotEmpty && s.isValid);
Iterable<Schedule> get todayTrainings =>
    avaiableSchedules.where((s) => s.todayTraining != null);

DateTime bareDT([DateTime dt]) {
  dt ??= DateTime.now();
  dt = dt.toUtc();
  return DateTime.utc(dt.year, dt.month, dt.day);
}

DateTime nextStartOfWeek([DateTime dt]) {
  dt ??= DateTime.now();
  dt = bareDT(dt);
  if (dt.weekday == DateTime.monday) return dt;
  final int shift = 7 - (dt.weekday - DateTime.monday) % 7;
  return dt.add(Duration(days: shift));
}

abstract class Schedule<T extends dynamic> {
  final DocumentReference reference;
  DocumentReference workRef;
  DateTime date;
  List<DocumentReference> athletesRefs;
  Iterable<Athlete> get athletes => athletesRefs
      .map((r) => userC.rawAthletes[r])
      .where((a) => a != null)
      .toList();
  set athletes(List<Athlete> athletes) =>
      athletesRefs = athletes.map((a) => a.reference).toList();

  Schedule.parse(DocumentSnapshot snap)
      : reference = snap.reference,
        workRef = snap['work'],
        date = snap['date'].toDate(),
        athletesRefs = snap['athletes'].cast<DocumentReference>();

  Schedule._(
    this.reference,
    this.workRef, {
    this.date,
    List<Athlete> athletes = const <Athlete>[],
  }) : athletesRefs = athletes.map((a) => a.reference).toList();

  T get work;

  static Future<void> _create({
    @required DocumentReference work,
    @required DateTime date,
    @required List<DocumentReference> athletes,
  }) {
    return userC.userReference
        .collection('schedules')
        .add({'work': work, 'date': date, 'athletes': athletes});
  }

  bool get isValid;

  ScheduleWidget<Schedule<T>> get widget;

  Future<void> create();

  Allenamento get todayTraining;

  bool get isOk => workRef != null && date != null && athletes.isNotEmpty;

  Widget content({
    @required BuildContext context,
    @required void Function() onChanged,
  });

  String get joinAthletes {
    if (athletes == null) return '';
    Iterable<Group> gs = Group.groups.where(
      (group) => group.athletes.every(
        (atleta) => athletes.contains(atleta),
      ),
    );
    Iterable<Athlete> atls = athletes.where(
      (atleta) => gs.every((group) => !group.athletes.contains(atleta)),
    );
    return gs.map((g) => g.name).followedBy(atls.map((a) => a.name)).join(', ');
  }
}

class PlanSchedule extends Schedule<Tabella> {
  DateTime to;

  PlanSchedule.parse(DocumentSnapshot snap)
      : assert(snap['work'].parent().id == 'plans'),
        to = snap['to']?.toDate(),
        super.parse(snap);

  PlanSchedule({
    DocumentReference work,
    DateTime date,
    this.to,
    List<Athlete> athletes = const <Athlete>[],
  }) : super._(
          null,
          work ?? (plans.isEmpty ? null : plans.values.first.reference),
          date: date ?? nextStartOfWeek(),
          athletes: athletes,
        );

  @override
  Tabella get work => plans[workRef];

  @override
  Widget content({BuildContext context, void Function() onChanged}) {
    return PlanScheduleDialogContent(onChanged: onChanged, schedule: this);
  }

  @override
  bool get isValid => !bareDT(to).isBefore(bareDT());

  @override
  Future<void> create() {
    assert(reference == null);
    return userC.userReference.collection('schedules').add({
      'work': workRef,
      'date': date,
      'to': to,
      'athletes': athletesRefs,
    });
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

  @override
  ScheduleWidget<Schedule<Tabella>> get widget =>
      PlanScheduleWidget(schedule: this);
}

class TrainingSchedule extends Schedule<Allenamento> {
  TrainingSchedule.parse(DocumentSnapshot snap) : super.parse(snap);

  TrainingSchedule({
    DocumentReference work,
    DateTime date,
    List<Athlete> athletes = const <Athlete>[],
  }) : super._(
          null,
          work ??
              (allenamenti.isEmpty ? null : allenamenti.values.first.reference),
          date: date ?? bareDT(),
          athletes: athletes,
        );

  @override
  Allenamento get work => allenamenti[workRef];

  @override
  Widget content({BuildContext context, void Function() onChanged}) {
    return TrainingScheduleDialogContent(onChanged: onChanged, schedule: this);
  }

  @override
  bool get isValid => !bareDT(date).isBefore(bareDT());

  @override
  Future<void> create() =>
      Schedule._create(work: workRef, date: date, athletes: athletesRefs);

  @override
  bool get isOk {
    return super.isOk && !bareDT().isAfter(bareDT(date));
  }

  @override
  Allenamento get todayTraining => bareDT(date) == bareDT() ? work : null;

  @override
  ScheduleWidget<Schedule<Allenamento>> get widget =>
      TrainingScheduleWidget(schedule: this);
}
