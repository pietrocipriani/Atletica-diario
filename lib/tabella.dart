import 'package:Atletica/allenamento.dart';
import 'package:Atletica/custom_expansion_tile.dart';
import 'package:Atletica/database.dart';
import 'package:Atletica/main.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

List<Tabella> plans = <Tabella>[];

List<String> itMonths = dateTimeSymbolMap()['it'].MONTHS;

class Tabella {
  final int id;
  String name;
  List<Week> weeks = <Week>[];

  List<int> months;

  Tabella(
      {@required this.id,
      @required this.name,
      Iterable<Week> weeks,
      this.months}) {
    if (weeks != null) this.weeks.addAll(weeks);
  }
  Tabella.parse(Map<String, dynamic> raw) : this.id = raw['id'] {
    this.name = raw['name'];
  }

  static Future<bool> fromDialog({@required BuildContext context}) {
    return showDialog<bool>(
      context: context,
      builder: (context) => _dialog(context),
    );
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

    String Function([String]) validator = ([s]) {
      s ??= name ?? '';
      if (s.isEmpty) return 'inserire il nome';
      if (plans.any((p) => p != plan && p.name == s)) return 'nome già in uso';
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
                    if (isNew) {
                      plan = Tabella(
                        id: await db.insert('Plans', {'name': name}),
                        name: name,
                      );
                      plans.add(plan);
                    } else
                      db.update(
                        'Plans',
                        {'name': plan.name = name},
                        where: 'id = ?',
                        whereArgs: [plan.id],
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
}

class Week {
  /// `null` per ripeterlo indefinitamente
  int repeat;
  Map<int, Allenamento>
      trainings; // TODO: implementare giorni con allenamenti multipli

  Week({this.repeat = 1, this.trainings}) {
    trainings ??= <int, Allenamento>{};
  }
  Week.parse(Map<String, dynamic> raw) {
    trainings = Map.fromEntries(
      raw.entries.where((entry) => shortWeekDays.contains(entry.key)).map(
            (entry) => MapEntry(
              shortWeekDays.indexOf(entry.key),
              allenamenti.firstWhere(
                (allenamento) => allenamento.id == entry.value,
                orElse: () => null,
              ),
            ),
          ),
    );
    plans.firstWhere((plan) => plan.id == raw['id']).weeks.add(this);
  }
  Week.copy(Week week)
      : this.repeat = week.repeat,
        this.trainings = Map.from(week.trainings);

  static Iterable<Widget> days(
      {@required BuildContext context,
      @required Week week,
      @required void Function(void Function()) setState}) sync* {
    final TextStyle overline = Theme.of(context).textTheme.overline;
    final Widget Function(BuildContext context, int weekday, bool over)
        builder = (context, weekday, over) {
      return week.trainings[weekday]?.chip(
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
    };
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
                () => week.trainings[(i + 1) % weekdays.length] = allenamento,
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
                          allenamento,
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
              children: allenamenti
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
      return trainings?.values?.where((t) => t != null)?.join(', ') ??
          'nessun allenamento';
    return () sync* {
      for (int i = 0; i < weekdays.length; i++)
        yield '${weekdays[i]}: ${allenamenti[i + 1] ?? 'riposo'}';
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
        children: plans
            .map(
              (plan) => Dismissible(
                direction: DismissDirection.horizontal,
                key: ValueKey(plan),
                background: Container(
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.only(left: 16),
                  color: Theme.of(context).primaryColorLight,
                  child: Icon(Icons.delete),
                ),
                secondaryBackground: Container(
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.only(right: 16),
                  color: Colors.lightGreen[200],
                  child: Icon(Icons.edit),
                ),
                confirmDismiss: (direction) async {
                  if (direction == DismissDirection.endToStart) {
                    if (await plan.modify(context: context)) setState(() {});
                    return false;
                  }
                  return await showDialog(
                    context: context,
                    builder: (context) =>
                        deleteConfirmDialog(context, plan.name),
                  );
                },
                onDismissed: (direction) {
                  plans.remove(plan);
                  db.delete('Plans', where: 'id = ?', whereArgs: [plan.id]);
                },
                child: CustomExpansionTile(
                  trailing: IconButton(
                    icon: Icon(Icons.add_circle),
                    onPressed: () async {
                      Week week = await Week.fromDialog(context);
                      db.insert(
                        'Weeks',
                        {'plan': plan.id, 'position': plan.weeks.length}
                          ..addEntries(week.trainings.entries.map(
                            (e) => MapEntry(shortWeekDays[e.key], e.value.id),
                          )),
                      );
                      plan.weeks.add(week);
                      setState(() {});
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
                  subtitle: plan.months == null
                      ? null
                      : Text(
                          plan.months
                              .map((month) => itMonths[month - 1])
                              .join(', '),
                          style: Theme.of(context).textTheme.overline.copyWith(
                                color: Theme.of(context).primaryColorDark,
                              ),
                        ),
                  children: plan.weeks
                      .map(
                        (week) => Dismissible(
                          key: ValueKey(week),
                          background: Container(
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.only(left: 16),
                            color: Theme.of(context).primaryColorLight,
                            child: Icon(Icons.delete),
                          ),
                          direction: DismissDirection.startToEnd,
                          confirmDismiss: (direction) async {
                            return await showDialog(
                              context: context,
                              builder: (context) => deleteConfirmDialog(context,
                                  'settimana #${plan.weeks.indexOf(week) + 1}'),
                            );
                          },
                          onDismissed: (direction) =>
                              setState(() => plan.weeks.remove(week)),
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
                                        week.trainings[(i + 1) % 7]?.name ??
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
                              onPressed: () => setState(
                                () => plan.weeks.insert(
                                  plan.weeks.indexOf(week),
                                  Week.copy(week),
                                ),
                              ),
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
