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

  void _removeScheduledTrainings({
    @required final List<Week> newWeeks,
    @required final List<Athlete> athletes,
    @required final Date start,
    @required final Date stop,
    @required final WriteBatch batch,
  }) {
    final Date now = Date.now();
    for (MapEntry<DateTime, List<ScheduledTraining>> e
        in userC.scheduledTrainings.entries) {
      if (e.value == null || now > e.key) continue;
      final Date date = Date.fromDateTime(e.key);
      final bool defaultDelete =
          start == null || date < start || date > stop || newWeeks.isEmpty;
      final int week =
          defaultDelete ? null : ((date - start).inDays ~/ 7) % newWeeks.length;
      final DocumentReference scheduled =
          defaultDelete ? null : newWeeks[week].trainings[date.weekday];
      for (ScheduledTraining st in e.value) {
        if (st.plan != reference) continue;
        bool delete = defaultDelete;
        delete |= st.workRef != scheduled;
        if (delete)
          batch.delete(st.reference);
        else
          st.update(
            athletes: athletes,
            batch: batch,
          ); //TODO: non vengono più eliminati gli atleti vecchi
      }
    }
  }

  void _addScheduledTrainings({
    @required final List<Week> weeks,
    @required final List<Athlete> athletes,
    @required final Date start,
    @required final Date stop,
    @required final WriteBatch batch,
  }) {
    if (start == null || weeks.isEmpty) return;
    final Date now = Date.now();

    for (Date current = start; current <= stop; current++) {
      final int week = ((current - start).inDays ~/ 7) % weeks.length;
      final DocumentReference training = weeks[week].trainings[current.weekday];
      if (current < now || training == null) continue;
      if (userC.scheduledTrainings[current.dateTime]
              ?.any((st) => st.workRef == training) ??
          false) {
        final ScheduledTraining st = userC.scheduledTrainings[current.dateTime]
            .firstWhere((st) => st.workRef == training);
        st.update(athletes: athletes, batch: batch);
      } else {
        // TODO: if already exists, check for `plan`
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
    List<Athlete> athletes,
    DateTime start,
    DateTime stop,
  }) {
    weeks ??= this.weeks;
    athletes ??= this
        .athletes
        .map((a) => userC.rawAthletes[a])
        .where((a) => a != null)
        .toList();
    start ??= this.start;
    stop ??= this.stop;
    final WriteBatch batch = firestore.batch();
    batch.updateData(reference, {
      'name': name ?? this.name,
      'weeks': weeks.map((week) => week.asMap).toList(),
      'athletes': athletes?.map((a) => a.reference)?.toList(),
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
