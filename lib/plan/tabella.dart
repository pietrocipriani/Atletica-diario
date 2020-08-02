import 'package:Atletica/global_widgets/custom_dismissible.dart';
import 'package:Atletica/global_widgets/delete_confirm_dialog.dart';
import 'package:Atletica/persistence/auth.dart';
import 'package:Atletica/persistence/user_helper/coach_helper.dart';
import 'package:Atletica/training/allenamento.dart';
import 'package:Atletica/global_widgets/custom_expansion_tile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

final Map<DocumentReference, Tabella> plans = <DocumentReference, Tabella>{};

List<String> itMonths = dateTimeSymbolMap()['it'].MONTHS;

class Tabella {
  final DocumentReference reference;
  String name;
  List<Week> weeks = <Week>[];

  Tabella.parse(DocumentSnapshot raw)
      : reference = raw.reference,
        name = raw['name'],
        weeks = raw['weeks'].map<Week>((raw) => Week.parse(raw)).toList() {
    plans[reference] = this;
  }

  static Future<bool> fromDialog({@required BuildContext context}) {
    return showDialog<bool>(
      context: context,
      builder: (context) => _dialog(context),
    );
  }

  static Future<void> create({@required String name}) =>
      user.userReference.collection('plans').add({'name': name, 'weeks': []});

  Future<void> update({String name, List<Week> weeks}) => reference.updateData({
        'name': name ?? this.name,
        'weeks': (weeks ?? this.weeks).map((week) => week.asMap).toList()
      });

  Future<bool> modify({@required BuildContext context}) {
    return showDialog<bool>(
      context: context,
      builder: (context) => _dialog(context, this),
    );
  }

  static Widget _dialog(final BuildContext context, [Tabella plan]) {
    final bool isNew = plan == null;
    String name = plan?.name;

    String Function([String]) validator = ([s]) {
      s ??= name ?? '';
      if (s.isEmpty) return 'inserire il nome';
      if (plans.values.any((p) => p != plan && p.name == s))
        return 'nome già in uso';
      return null;
    };

    return StatefulBuilder(
      builder: (context, ss) => AlertDialog(
        title: Text(isNew ? 'AGGIUNGI' : 'MODIFICA'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextFormField(
              initialValue: name,
              autofocus: false,
              autovalidate: true,
              decoration: InputDecoration(labelText: 'nome'),
              validator: validator,
              onChanged: (value) {
                ss(() => name = value);
              },
            ),
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
            onPressed: validator() != null
                ? null
                : () async {
                    if (isNew)
                      Tabella.create(name: name);
                    else
                      plan.update(name: name);
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
}

class Week {
  /// `null` per ripeterlo indefinitamente
  int repeat;
  Map<int, DocumentReference> trainings;
  // TODO: implementare giorni con allenamenti multipli

  Week({this.repeat = 1, this.trainings}) {
    trainings ??= <int, DocumentReference>{};
  }
  Week.parse(Map raw) {
    // TODO: repeat
    trainings = raw.map((key, value) => MapEntry(int.tryParse(key), value));
  }
  Week.copy(Week week)
      : this.repeat = week.repeat,
        this.trainings = Map.from(week.trainings);

  Map<String, dynamic> get asMap =>
      trainings.map((key, value) => MapEntry(key.toString(), value));

  static Iterable<Widget> days(
      {@required BuildContext context,
      @required Week week,
      @required void Function(void Function()) setState}) sync* {
    final TextStyle overline = Theme.of(context).textTheme.overline;
    Widget builder(BuildContext context, int weekday, bool over) {
      return allenamenti[week.trainings[weekday]]?.chip(
              context: context,
              onDelete: () => setState(() => week.trainings[weekday] = null)) ??
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: DottedBorder(
              borderType: BorderType.RRect,
              padding: const EdgeInsets.all(0),
              color:
                  over ? Theme.of(context).primaryColorDark : Colors.grey[300],
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

  static Future<Week> fromDialog(BuildContext context) async {
    final Week week = Week();
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('definisci settimana'),
          content: Column(
              children: days(context: context, week: week, setState: setState)
                  .followedBy(<Widget>[
            Container(
              width: double.infinity,
              height: 1,
              color: Colors.grey[300],
              margin: const EdgeInsets.all(8),
            ),
            Wrap(
              alignment: WrapAlignment.start,
              crossAxisAlignment: WrapCrossAlignment.start,
              children: allenamenti.values
                  .map(
                    (allenamento) => Draggable<Allenamento>(
                      maxSimultaneousDrags: 1,
                      data: allenamento,
                      feedback:
                          allenamento.chip(context: context, elevation: 6),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: allenamento.chip(context: context),
                      ),
                      childWhenDragging: Padding(
                        padding: const EdgeInsets.all(4),
                        child: allenamento.chip(
                          context: context,
                          enabled: false,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ]).toList()),
        ),
      ),
    );
    return week;
  }

  @override
  String toString([bool extended = false]) {
    if (!extended)
      return trainings?.values
              ?.where((t) => t != null)
              ?.map((a) => allenamenti[a])
              ?.join(', ') ??
          'nessun allenamento';
    return () sync* {
      for (int i = 0; i < weekdays.length; i++)
        yield '${weekdays[i]}: ${allenamenti[trainings[i]] ?? 'riposo'}';
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
                onDismissed: (direction) => plan.reference.delete(),
                child: CustomExpansionTile(
                  trailing: IconButton(
                    icon: Icon(Icons.add_circle, color: Colors.black),
                    onPressed: () async {
                      Week week = await Week.fromDialog(context);
                      plan.weeks.add(week);
                      plan.update();
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
                                        allenamenti[week.trainings[(i + 1) % 7]]
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
