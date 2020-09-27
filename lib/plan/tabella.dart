import 'package:Atletica/athlete/atleta.dart';
import 'package:Atletica/athlete/group.dart';
import 'package:Atletica/date.dart';
import 'package:Atletica/global_widgets/custom_dismissible.dart';
import 'package:Atletica/global_widgets/delete_confirm_dialog.dart';
import 'package:Atletica/persistence/auth.dart';
import 'package:Atletica/persistence/firestore.dart';
import 'package:Atletica/persistence/user_helper/coach_helper.dart';
import 'package:Atletica/schedule/athletes_picker.dart';
import 'package:Atletica/schedule/schedule.dart';
import 'package:Atletica/training/allenamento.dart';
import 'package:Atletica/global_widgets/custom_expansion_tile.dart';
import 'package:Atletica/training/training_chip.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

final Map<DocumentReference, Tabella> plans = <DocumentReference, Tabella>{};

List<String> itMonths = dateTimeSymbolMap()['it'].MONTHS;

// TODO: add athletes selection
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
      builder: (context) => _dialog(context),
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
          st.update(athletes: athletes, batch: batch);
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
          false) continue;

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
      builder: (context) => _dialog(context, this),
    );
  }

  static Widget _dialog(final BuildContext context, [Tabella plan]) {
    final bool isNew = plan == null;
    String name = plan?.name;
    DateTime start = plan?.start;
    DateTime stop = plan?.stop;
    final List<Athlete> athletes = plan?.athletes
            ?.map((a) => userC.rawAthletes[a])
            ?.where((a) => a != null)
            ?.toList() ??
        <Athlete>[];

    DateTime firstAvaiableStartDay = Date.now().dateTime;
    firstAvaiableStartDay = firstAvaiableStartDay.subtract(
      Duration(days: (firstAvaiableStartDay.weekday - DateTime.monday) % 7),
    );

    String validator([s]) {
      s ??= name ?? '';
      if (s.isEmpty) return 'inserire il nome';
      if (plans.values.any((p) => p != plan && p.name == s))
        return 'nome già in uso';
      return null;
    }

    String _format(DateTime d) => d == null
        ? 'seleziona'
        : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year % 100}';

    return StatefulBuilder(
      builder: (context, ss) => AlertDialog(
        title: Text(isNew ? 'AGGIUNGI' : 'MODIFICA'),
        scrollable: true,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextFormField(
              initialValue: name,
              autofocus: false,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: InputDecoration(labelText: 'nome'),
              validator: validator,
              onChanged: (value) {
                ss(() => name = value);
              },
            ),
            Row(
              children: <Widget>[
                Text('dal'),
                Expanded(
                  child: FlatButton(
                    onPressed: () async {
                      start = await showDatePicker(
                            context: context,
                            initialDate: start ?? firstAvaiableStartDay,
                            firstDate: firstAvaiableStartDay,
                            helpText: "seleziona la data di inizio",
                            selectableDayPredicate: (day) =>
                                day.weekday == DateTime.monday,
                            lastDate:
                                DateTime.now().add(const Duration(days: 365)),
                          ) ??
                          start;
                      if (stop != null && start.isAfter(stop)) stop = start;
                      ss(() {});
                    },
                    onLongPress: start == null
                        ? null
                        : () => ss(() => start = stop = null),
                    child: Text(_format(start)),
                  ),
                ),
                Text('al'),
                Expanded(
                  child: FlatButton(
                    onPressed: stop == null && start == null
                        ? null
                        : () async {
                            stop = await showDatePicker(
                                  context: context,
                                  initialDate:
                                      stop ?? start.add(Duration(days: 6)),
                                  firstDate: start,
                                  helpText:
                                      "seleziona la data di fine. Premi a lungo sulla data della schermata precendente per eliminare la scadenza.",
                                  selectableDayPredicate: (day) =>
                                      day.weekday == DateTime.sunday,
                                  lastDate: DateTime.now()
                                      .add(const Duration(days: 365)),
                                ) ??
                                stop;
                            ss(() {});
                          },
                    onLongPress:
                        stop == null ? null : () => ss(() => stop = null),
                    child: Text(_format(stop)),
                  ),
                )
              ],
            ),
            AthletesPicker(athletes, onChanged: (a) => ss(() {})),
          ],
        ),
        actions: <Widget>[
          FlatButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Annulla',
            ),
          ),
          FlatButton(
            onPressed: validator() != null || (start == null) != (stop == null)
                ? null
                : () async {
                    if (isNew)
                      Tabella.create(
                        name: name,
                        athletes: athletes,
                        start: start,
                        stop: stop,
                      );
                    else
                      plan.update(
                        name: name,
                        athletes: athletes,
                        start: start,
                        stop: stop,
                      );
                    Navigator.pop(context, true);
                  },
            child: Text(
              isNew ? 'Aggiungi' : 'Modifica',
            ),
          ),
        ],
      ),
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

class Week {
  Map<int, DocumentReference> trainings;

  Week({this.trainings}) {
    trainings ??= <int, DocumentReference>{};
  }
  Week.parse(Map raw) {
    trainings = raw.map((key, value) => MapEntry(int.tryParse(key), value));
  }
  Week.copy(Week week) : this.trainings = Map.from(week.trainings);

  Map<String, dynamic> get asMap =>
      trainings.map((key, value) => MapEntry(key.toString(), value));

  static Iterable<Widget> days(
      {@required BuildContext context,
      @required Week week,
      @required void Function(void Function()) setState}) sync* {
    final TextStyle overline = Theme.of(context).textTheme.overline;
    Widget builder(BuildContext context, int weekday, bool over) {
      return allenamenti(week.trainings[weekday]) != null
          ? TrainingChip(
              training: allenamenti(week.trainings[weekday]),
              onDelete: () => setState(() => week.trainings[weekday] = null),
            )
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: DottedBorder(
                borderType: BorderType.RRect,
                padding: const EdgeInsets.all(0),
                color: over
                    ? Theme.of(context).primaryColorDark
                    : Colors.grey[300],
                radius: Radius.circular(20),
                dashPattern: [6, 4],
                child: Container(
                  height: 32,
                ),
              ),
            );
    }

    for (int i = 0; i < weekdays.length; i += 2) {
      bool single = i + 1 >= weekdays.length;
      yield Row(
        children: <Widget>[
          if (single) Expanded(child: Container()),
          Expanded(
            flex: single ? 2 : 1,
            child: Text(
              weekdays[(i + 1) % weekdays.length],
              style: overline,
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: single
                ? Container()
                : Text(
                    weekdays[(i + 2) % weekdays.length],
                    style: overline,
                    textAlign: TextAlign.center,
                  ),
          ),
        ],
      );
      yield Row(
        children: [
          if (single)
            Expanded(
              child: Container(),
            ),
          Expanded(
            flex: single ? 2 : 1,
            child: DragTarget<Allenamento>(
              builder: (BuildContext context, List<Allenamento> candidateData,
                      List<dynamic> rejectedData) =>
                  builder(context, (i + 1) % 7, candidateData.isNotEmpty),
              onAccept: (allenamento) => setState(
                () => week.trainings[(i + 1) % weekdays.length] =
                    allenamento.reference,
              ),
            ),
          ),
          Expanded(
            child: single
                ? Container()
                : DragTarget<Allenamento>(
                    builder: (BuildContext context,
                            List<Allenamento> candidateData,
                            List<dynamic> rejectedData) =>
                        builder(context, (i + 2) % 7, candidateData.isNotEmpty),
                    onAccept: (allenamento) => setState(
                      () => week.trainings[(i + 2) % weekdays.length] =
                          allenamento.reference,
                    ),
                  ),
          ),
        ],
      );
    }
  }

  static Future<Week> fromDialog(BuildContext context) {
    final Week week = Week();
    return showDialog<Week>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          scrollable: true,
          title: Text('definisci settimana'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: days(context: context, week: week, setState: setState)
                .followedBy(<Widget>[
              Container(
                width: double.infinity,
                height: 1,
                color: Colors.grey[300],
                margin: const EdgeInsets.all(8),
              ),
              Wrap(
                alignment: WrapAlignment.center,
                children: trainingsValues
                    .map(
                      (allenamento) => Draggable<Allenamento>(
                        maxSimultaneousDrags: 1,
                        data: allenamento,
                        feedback:
                            TrainingChip(training: allenamento, elevation: 6),
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: TrainingChip(training: allenamento),
                        ),
                        childWhenDragging: Padding(
                          padding: const EdgeInsets.all(4),
                          child: TrainingChip(
                            training: allenamento,
                            enabled: false,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ]).toList(),
          ),
          actions: [
            FlatButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Annulla'),
            ),
            FlatButton(
              onPressed: () => Navigator.pop(context, week),
              child: const Text('Conferma'),
            )
          ],
        ),
      ),
    );
  }

  @override
  String toString([bool extended = false]) {
    if (!extended)
      return trainings?.values
              ?.where((t) => t != null)
              ?.map((a) => allenamenti(a))
              ?.join(', ') ??
          'nessun allenamento';
    return () sync* {
      for (int i = 0; i < weekdays.length; i++)
        yield '${weekdays[i]}: ${allenamenti(trainings[i]) ?? 'riposo'}';
    }()
        .join('\n');
  }
}

class PlansRoute extends StatefulWidget {
  @override
  _PlansRouteState createState() => _PlansRouteState();
}

class _PlansRouteState extends State<PlansRoute>
    with SingleTickerProviderStateMixin {
  final Callback callback = Callback();

  @override
  void initState() {
    callback.f = (_) => setState(() {});
    CoachHelper.onPlansCallbacks.add(callback);
    super.initState();
  }

  @override
  void dispose() {
    CoachHelper.onPlansCallbacks.remove(callback.stopListening);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PIANI DI LAVORO'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (await Tabella.fromDialog(context: context)) setState(() {});
        },
        child: Icon(Icons.add),
      ),
      body: ListView(
        children: plans.values
            .map(
              (plan) => CustomDismissible(
                key: ValueKey(plan.reference),
                confirmDismiss: (direction) async {
                  if (direction == DismissDirection.endToStart) {
                    if (await plan.modify(context: context)) setState(() {});
                    return false;
                  }
                  return await showDeleteConfirmDialog(
                    context: context,
                    name: plan.name,
                  );
                },
                onDismissed: (direction) => plan.delete(),
                child: CustomExpansionTile(
                  subtitle: (plan.athletes?.isEmpty ?? true)
                      ? null
                      : Text(
                          plan.athletesAsList,
                          style: TextStyle(
                              color: Theme.of(context).primaryColorDark),
                        ),
                  trailing: IconButton(
                    icon: Icon(Icons.add_circle, color: Colors.black),
                    onPressed: () async {
                      Week week = await Week.fromDialog(context);
                      if (week != null) {
                        plan.weeks.add(week);
                        plan.update();
                      }
                    },
                  ),
                  leading: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        plan.weeks.length.toString(),
                        style: Theme.of(context).textTheme.headline5,
                      ),
                      Text(
                        'settiman${plan.weeks.length == 1 ? 'a' : 'e'}',
                        style: Theme.of(context).textTheme.overline,
                      ),
                    ],
                  ),
                  title: plan.name,
                  children: plan.weeks
                      .map(
                        (week) => CustomDismissible(
                          key: ValueKey(week),
                          direction: DismissDirection.startToEnd,
                          confirmDismiss: (direction) async {
                            return await showDeleteConfirmDialog(
                              context: context,
                              name:
                                  'settimana #${plan.weeks.indexOf(week) + 1}',
                            );
                          },
                          onDismissed: (direction) {
                            setState(() => plan.weeks.remove(week));
                            plan.update();
                          },
                          child: CustomExpansionTile(
                            title: 'settimana #${plan.weeks.indexOf(week) + 1}',
                            subtitle: Text(
                              week.toString(),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 3,
                              style: Theme.of(context)
                                  .textTheme
                                  .overline
                                  .copyWith(
                                    color: Theme.of(context).primaryColorDark,
                                  ),
                            ),
                            children: () sync* {
                              for (int i = 0; i < weekdays.length; i++)
                                yield Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 40.0),
                                  child: Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: Text(
                                          weekdays[(i + 1) % 7],
                                          style: Theme.of(context)
                                              .textTheme
                                              .overline
                                              .copyWith(
                                                  fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      Text(
                                        allenamenti(week.trainings[(i + 1) % 7])
                                                ?.name ??
                                            'riposo',
                                        style: Theme.of(context)
                                            .textTheme
                                            .overline
                                            .copyWith(
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  week.trainings[(i + 1) % 7] ==
                                                          null
                                                      ? Colors.grey[300]
                                                      : Theme.of(context)
                                                          .primaryColorDark,
                                            ),
                                      ),
                                    ],
                                  ),
                                );
                            }()
                                .toList(),
                            trailing: IconButton(
                              icon: Icon(Icons.content_copy),
                              onPressed: () {
                                plan.weeks.insert(
                                  plan.weeks.indexOf(week),
                                  Week.copy(week),
                                );
                                plan.update();
                              },
                            ),
                            leading: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                GestureDetector(
                                  child: Icon(Icons.expand_less,
                                      color: plan.weeks.first == week
                                          ? Colors.grey[300]
                                          : Theme.of(context).primaryColorDark),
                                  onTap: plan.weeks.first == week
                                      ? null
                                      : () {
                                          int index = plan.weeks.indexOf(week);
                                          setState(() {
                                            plan.weeks.insert(index - 1,
                                                plan.weeks.removeAt(index));
                                          });
                                          plan.update();
                                        },
                                ),
                                GestureDetector(
                                  child: Icon(Icons.expand_more,
                                      color: plan.weeks.last == week
                                          ? Colors.grey[300]
                                          : Theme.of(context).primaryColorDark),
                                  onTap: plan.weeks.last == week
                                      ? null
                                      : () {
                                          int index = plan.weeks.indexOf(week);
                                          setState(() {
                                            plan.weeks.insert(index - 1,
                                                plan.weeks.removeAt(index));
                                          });
                                          plan.update();
                                        },
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
