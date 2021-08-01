import 'package:atletica/athlete/athlete.dart';
import 'package:atletica/athlete/group.dart';
import 'package:atletica/cache.dart';
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

List<String> itMonths = dateTimeSymbolMap()['it'].MONTHS;

class Plan {
  static final Cache<DocumentReference, Plan> _cache = Cache();

  static Iterable<Plan> get plans => _cache.values;

  static void Function() cacheReset = _cache.reset;

  static void Function(Callback c) signIn = _cache.signIn;
  static void Function(Callback c) signOut = _cache.signOut;

  final DocumentReference reference;
  String name;
  final List<Week> weeks = <Week>[];
  final Set<DocumentReference> _athletes = Set();
  List<Athlete> get athletes => Athlete.getAthletes(_athletes).toList();
  List<DocumentReference> get athletesRefs =>
      _athletes.where((a) => Athlete.exists(a)).toList();
  DateTime? start, stop;

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
    _cache.notifyAll(p);
    return p;
  }
  Plan._parse(DocumentSnapshot raw)
      : reference = raw.reference,
        name = raw['name'],
        start = raw['start']?.toDate(),
        stop = raw['stop']?.toDate() {
    raw['weeks']?.forEach((raw) => Week.parse(this, raw));
    athletes.addAll(raw['athletes']?.cast<DocumentReference>() ??
        Iterable<DocumentReference>.empty());
  }
  factory Plan.update(final DocumentSnapshot raw) {
    final Plan p = Plan.of(raw.reference);
    p.name = raw['name'];
    p.start = raw['start']?.toDate();
    p.stop = raw['stop']?.toDate();
    p.weeks.clear();
    raw['weeks']?.forEach((raw) => Week.parse(p, raw));
    p.athletes.clear();
    p.athletes.addAll(raw['athletes']?.cast<DocumentReference>() ??
        Iterable<DocumentReference>.empty());
    _cache.notifyAll(p);
    return p;
  }

  static void remove(final DocumentReference ref) {
    final Plan? p = _cache.remove(ref);
    if (p != null) _cache.notifyAll(p);
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
    DateTime? start,
    DateTime? stop,
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
    final Date now = Date.now();

    userC.scheduledTrainings.entries.forEach((final e) {
      if (e.value == null || now > e.key)
        return; // TODO: check if ignore same-day trainings
      final Date date = Date.fromDateTime(e.key);
      if (date < this.start || date > this.stop) return;
      final DocumentReference? oldScheduled = getScheduledTraining(date: date);
      if (oldScheduled == null) return; // nothing was scheduled for this day
      bool delete =
          start == null || date < start || date > stop || newWeeks.isEmpty;
      final DocumentReference? scheduled = delete
          ? null
          : getScheduledTraining(date: date, start: start, weeks: newWeeks);
      delete |= scheduled != oldScheduled;
      for (ScheduledTraining st in e.value) {
        if (st.workRef != oldScheduled) continue;
        st.update(
          athletes: delete ? null : athletes,
          removedAthletes: _athletes.toList(),
          batch: batch,
        );
      }
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
    final Date now = Date.now();

    for (Date current = start; current <= stop; current++) {
      // FIXME: stop is ignored
      if (current < now) continue;
      final DocumentReference? training =
          getScheduledTraining(date: current, start: start, weeks: weeks);
      if (training == null) continue;
      if (userC.scheduledTrainings[current]
              ?.any((st) => st.workRef == training) ??
          false) {
        final ScheduledTraining st = userC.scheduledTrainings[current]!
            .firstWhere((st) => st.workRef == training);
        st.update(athletes: athletes, batch: batch);
      } else {
        ScheduledTraining.create(
          work: training,
          date: current,
          athletes: athletes,
          plan: this,
          batch: batch,
        );
      }
    }
  }

  Future<void> update({
    String? name,
    List<Week>? weeks,
    List<DocumentReference>? athletes,
    DateTime? start,
    DateTime? stop,
    bool removingSchedules = false,
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

  Future<bool> modify({required BuildContext context}) async {
    return (await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => PlanDialog(this),
        )) ??
        false;
  }

  String get athletesAsList {
    final List<Athlete> athletes = List.from(this.athletes);
    final Iterable<Group> gs =
        Group.groups.where((group) => group.isContainedIn(athletes));
    gs.forEach((g) => g.athletes.forEach(athletes.remove));
    return gs
        .map((g) => g.name)
        .followedBy(athletes.map((a) => a.name))
        .join(', ');
  }
}
