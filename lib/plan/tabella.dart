import 'package:atletica/athlete/atleta.dart';
import 'package:atletica/athlete/group.dart';
import 'package:atletica/date.dart';
import 'package:atletica/persistence/auth.dart';
import 'package:atletica/persistence/firestore.dart';
import 'package:atletica/plan/week.dart';
import 'package:atletica/plan/widgets/plan_dialog.dart';
import 'package:atletica/schedule/schedule.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

final Map<DocumentReference, Tabella> plans = <DocumentReference, Tabella>{};

List<String> itMonths = dateTimeSymbolMap()['it'].MONTHS;

class Tabella {
  final DocumentReference reference;
  String name;
  List<Week> weeks = <Week>[];
  final List<DocumentReference> athletes;
  DateTime start, stop;

  Tabella.parse(DocumentSnapshot raw)
      : reference = raw.reference,
        name = raw['name'],
        weeks = raw['weeks'].map<Week>((raw) => Week.parse(raw)).toList(),
        athletes =
            raw['athletes']?.cast<DocumentReference>() ?? <DocumentReference>[],
        start = raw['start']?.toDate(),
        stop = raw['stop']?.toDate() {
    plans[reference] = this;
  }

  static Future<bool> fromDialog({@required BuildContext context}) {
    return showDialog<bool>(
      context: context,
      builder: (context) => PlanDialog(),
    );
  }

  static Future<void> create({
    @required String name,
    List<Athlete> athletes,
    DateTime start,
    DateTime stop,
  }) {
    return userC.userReference.collection('plans').add({
      'name': name,
      'weeks': [],
      'athletes': athletes?.map((a) => a.reference)?.toList(),
      'start': start,
      'stop': stop,
    });
  }

  DocumentReference getScheduledTraining({
    @required final Date date,
    List<Week> weeks,
    dynamic start,
  }) {
    weeks ??= this.weeks;
    start ??= this.start;
    if (date == null || start == null || (weeks?.isEmpty ?? true)) return null;
    final int week = ((date - start).inDays ~/ 7) % weeks.length;
    return weeks[week].trainings[date.weekday % 7];
  }

  void _removeScheduledTrainings({
    @required final List<Week> newWeeks,
    @required final List<DocumentReference> athletes,
    @required final Date start,
    @required final Date stop,
    @required final WriteBatch batch,
  }) {
    if (this.start == null || this.weeks.isEmpty)
      return; // if this wasn't a scheduled plan
    final Date now = Date.now();

    userC.scheduledTrainings.entries.forEach((final e) {
      if (e.value == null || now > e.key)
        return; // TODO: check if ignore same-day trainings
      final Date date = Date.fromDateTime(e.key);
      if (date < this.start || date > this.stop) return;
      final DocumentReference oldScheduled = getScheduledTraining(date: date);
      if (oldScheduled == null) return; // nothing was scheduled for this day
      bool delete =
          start == null || date < start || date > stop || newWeeks.isEmpty;
      final DocumentReference scheduled = delete
          ? null
          : getScheduledTraining(date: date, start: start, weeks: newWeeks);
      delete |= scheduled != oldScheduled;
      for (ScheduledTraining st in e.value) {
        if (st.workRef != oldScheduled) continue;
        st.update(
          athletes: delete ? null : athletes,
          removedAthletes: this.athletes,
          batch: batch,
        );
      }
    });
  }

  void _addScheduledTrainings({
    @required final List<Week> weeks,
    @required final List<DocumentReference> athletes,
    @required final Date start,
    @required final Date stop,
    @required final WriteBatch batch,
  }) {
    if (start == null || weeks.isEmpty) return;
    final Date now = Date.now();

    for (Date current = start; current <= stop; current++) {
      // FIXME: stop is ignored
      if (current < now) continue;
      final DocumentReference training =
          getScheduledTraining(date: current, start: start, weeks: weeks);
      if (training == null) continue;
      if (userC.scheduledTrainings[current.dateTime]
              ?.any((st) => st.workRef == training) ??
          false) {
        final ScheduledTraining st = userC.scheduledTrainings[current.dateTime]
            .firstWhere((st) => st.workRef == training);
        st.update(athletes: athletes, batch: batch);
      } else {
        ScheduledTraining.create(
          work: training,
          date: current.dateTime,
          athletes: athletes,
          plan: this,
          batch: batch,
        );
      }
    }
  }

  Future<void> update({
    String name,
    List<Week> weeks,
    List<DocumentReference> athletes,
    DateTime start,
    DateTime stop,
    bool removingSchedules = false,
  }) {
    weeks ??= this.weeks;
    athletes ??=
        this.athletes.where((a) => userC.rawAthletes.containsKey(a)).toList();
    if (!removingSchedules) start ??= this.start;
    if (!removingSchedules) stop ??= this.stop;
    final WriteBatch batch = firestore.batch();
    batch.updateData(reference, {
      'name': name ?? this.name,
      'weeks': weeks.map((week) => week.asMap).toList(),
      'athletes': athletes?.toList(),
      'start': start,
      'stop': stop
    });
    _removeScheduledTrainings(
      newWeeks: weeks,
      start: start == null ? null : Date.fromDateTime(start),
      stop: stop == null ? null : Date.fromDateTime(stop),
      athletes: athletes,
      batch: batch,
    );
    _addScheduledTrainings(
      weeks: weeks,
      athletes: athletes,
      start: start == null ? null : Date.fromDateTime(start),
      stop: stop == null ? null : Date.fromDateTime(stop),
      batch: batch,
    );

    return batch.commit();
  }

  Future<void> delete() {
    final WriteBatch batch = firestore.batch();
    _removeScheduledTrainings(
      newWeeks: <Week>[],
      athletes: null,
      start: null,
      stop: null,
      batch: batch,
    );
    batch.delete(reference);
    return batch.commit();
  }

  Future<bool> modify({@required BuildContext context}) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PlanDialog(this),
    );
  }

  String get athletesAsList {
    if (athletes == null) return '';
    Iterable<Group> gs = Group.groups.where(
      (group) => group.athletes.every(
        (atleta) => athletes.contains(atleta.reference),
      ),
    );
    Iterable<Athlete> atls = athletes.map((a) => userC.rawAthletes[a]).where(
          (atleta) =>
              atleta != null &&
              atleta.isAthlete &&
              gs.every((group) => !group.athletes.contains(atleta)),
        );
    return gs.map((g) => g.name).followedBy(atls.map((a) => a.name)).join(', ');
  }
}
