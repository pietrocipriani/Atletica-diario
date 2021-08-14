import 'package:atletica/athlete/athlete.dart';
import 'package:atletica/athlete/group.dart';
import 'package:atletica/cache.dart';
import 'package:atletica/date.dart';
import 'package:atletica/persistence/auth.dart';
import 'package:atletica/persistence/firestore.dart';
import 'package:atletica/plan/week.dart';
import 'package:atletica/plan/widgets/plan_dialog.dart';
import 'package:atletica/schedule/schedule.dart';
import 'package:atletica/training/training.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

List<String> itMonths = dateTimeSymbolMap()['it'].MONTHS;

class Plan with Notifier<Plan> {
  static final Cache<DocumentReference, Plan> _cache = Cache();

  static Iterable<Plan> get plans => _cache.values;

  static void Function() cacheReset = _cache.reset;

  static void Function(Callback c) signInGlobal = _cache.signIn;
  static void Function(Callback c) signOutGlobal = _cache.signOut;

  final DocumentReference reference;
  String name;
  final List<Week> weeks = <Week>[];
  final Set<DocumentReference> _athletes = Set();
  List<Athlete> get athletes => Athlete.getAthletes(_athletes).toList();
  List<DocumentReference> get athletesRefs =>
      _athletes.where((a) => Athlete.exists(a)).toList();
  Date? start, stop;

  factory Plan.of(final DocumentReference ref) {
    final Plan? a = _cache[ref];
    if (a == null) throw StateError('cannot find Plan of ${ref.path}');
    return a;
  }
  static Plan? tryOf(final DocumentReference? ref) {
    if (ref == null) return null;
    try {
      return Plan.of(ref);
    } on StateError {
      return null;
    }
  }

  factory Plan.parse(final DocumentSnapshot raw) {
    final Plan p = _cache[raw.reference] ??= Plan._parse(raw);
    _cache.notifyAll(p, Change.ADDED);
    return p;
  }
  Plan._parse(DocumentSnapshot raw)
      : assert((raw['start'] == null) == (raw['stop'] == null)),
        reference = raw.reference,
        name = raw['name'],
        start = raw['start'] == null ? null : Date.fromTimeStamp(raw['start']),
        stop = raw['stop'] == null ? null : Date.fromTimeStamp(raw['stop']) {
    raw['weeks']?.forEach((raw) => Week.parse(this, raw));
    _athletes.addAll(raw['athletes']?.cast<DocumentReference>() ??
        Iterable<DocumentReference>.empty());
  }
  factory Plan.update(final DocumentSnapshot raw) {
    final Plan p = Plan.of(raw.reference);
    p.name = raw['name'];
    p.start = raw['start'] == null ? null : Date.fromTimeStamp(raw['start']);
    p.stop = raw['stop'] == null ? null : Date.fromTimeStamp(raw['stop']);
    p.weeks.clear();
    raw['weeks']?.forEach((raw) => Week.parse(p, raw));
    p._athletes.clear();
    p._athletes.addAll(raw['athletes']?.cast<DocumentReference>() ??
        Iterable<DocumentReference>.empty());
    p.notifyAll(p, Change.UPDATED);
    return p;
  }

  static void remove(final DocumentReference ref) {
    final Plan? p = _cache.remove(ref);
    if (p != null) _cache.notifyAll(p, Change.DELETED);
  }

  static Future<bool> fromDialog({required BuildContext context}) async {
    return (await showDialog<bool>(
          context: context,
          builder: (context) => PlanDialog(),
        ) ??
        false);
  }

  static Future<void> create({
    required String name,
    List<Athlete>? athletes,
    Date? start,
    Date? stop,
  }) {
    return userC.userReference.collection('plans').add({
      'name': name,
      'weeks': [],
      'athletes': athletes?.map((a) => a.reference).toList(),
      'start': start,
      'stop': stop,
    });
  }

  DocumentReference? getScheduledTraining({
    required final Date date,
    List<Week>? weeks,
    dynamic start,
  }) {
    weeks ??= this.weeks;
    start ??= this.start;
    if (start == null || weeks.isEmpty) return null;
    final int week = ((date - start).inDays ~/ 7) % weeks.length;
    return weeks[week].trainings[date.weekday % 7];
  }

  void _removeScheduledTrainings({
    required final List<Week> newWeeks,
    required final List<DocumentReference>? athletes,
    required final Date? start,
    required final Date? stop,
    required final WriteBatch batch,
  }) {
    if (this.start == null || this.weeks.isEmpty)
      return; // if this wasn't a scheduled plan

    final bool defaultDelete = start == null || newWeeks.isEmpty;
    ScheduledTraining.inRange(Date.last(this.start!, Date.now()), this.stop!)
        .forEach((final st) {
      final DocumentReference? oldScheduled =
          getScheduledTraining(date: st.date);
      if (oldScheduled == null) return; // nothing was scheduled for this day
      if (st.workRef != oldScheduled) return;
      bool delete = defaultDelete || st.date < start || st.date > stop;
      delete |= getScheduledTraining(
            date: st.date,
            start: start,
            weeks: newWeeks,
          ) !=
          oldScheduled;

      st.update(
        athletes: delete ? null : athletes,
        removedAthletes: _athletes.toList(),
        batch: batch,
      );
    });
  }

  void _addScheduledTrainings({
    required final List<Week> weeks,
    required final List<DocumentReference> athletes,
    required final Date? start,
    required final Date? stop,
    required final WriteBatch batch,
  }) {
    if (start == null || weeks.isEmpty) return;
    assert(stop != null);

    for (Date current = Date.last(Date.now(), start);
        current <= stop;
        current++) {
      final DocumentReference? training =
          getScheduledTraining(date: current, start: start, weeks: weeks);
      if (training == null) continue;
      final ScheduledTraining? alreadyScheduled =
          ScheduledTraining.ofDateRef(current, training);
      if (alreadyScheduled != null) {
        alreadyScheduled.update(athletes: athletes, batch: batch);
      } else {
        ScheduledTraining.create(
          work: Training.of(training),
          date: current,
          athletes: athletes,
          plan: this,
          batch: batch,
        );
      }
    }
  }

  Future<void> update({
    final String? name,
    List<Week>? weeks,
    List<DocumentReference>? athletes,
    Date? start,
    Date? stop,
    final bool removingSchedules = false,
  }) {
    weeks ??= this.weeks;
    athletes ??= athletesRefs;
    if (!removingSchedules) start ??= this.start;
    if (!removingSchedules) stop ??= this.stop;
    final WriteBatch batch = firestore.batch();
    batch.update(reference, {
      'name': name ?? this.name,
      'weeks': weeks.map((week) => week.asMap).toList(),
      'athletes': athletes.toList(),
      'start': start,
      'stop': stop
    });
    _removeScheduledTrainings(
      newWeeks: weeks,
      start: start,
      stop: stop,
      athletes: athletes,
      batch: batch,
    );
    _addScheduledTrainings(
      weeks: weeks,
      athletes: athletes,
      start: start,
      stop: stop,
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

  Future<bool> modify({required BuildContext context}) async {
    return (await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => PlanDialog(this),
        )) ??
        false;
  }

  String get athletesAsList {
    final List<Athlete> athletes = this.athletes;
    final List<Group> gs =
        Group.groups.where((group) => group.isContainedIn(athletes)).toList();
    gs.forEach((g) => g.athletes.forEach(athletes.remove));
    return gs
        .map((g) => g.name)
        .followedBy(athletes.map((a) => a.name))
        .join(', ');
  }
}
