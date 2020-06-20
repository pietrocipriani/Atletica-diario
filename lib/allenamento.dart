import 'package:Atletica/custom_expansion_tile.dart';
import 'package:Atletica/database.dart';
import 'package:Atletica/duration_picker.dart';
import 'package:Atletica/main.dart';
import 'package:Atletica/recupero.dart';
import 'package:Atletica/ripetuta.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqflite/sqlite_api.dart';

// TODO: salvare nel db il recupero fra le ripetute
// TODO: salvare nel db il numero di ripetute (quando ci sonon le ripetizioni)
// TODO: salvare nel db il recupero fra le serie (solo next)

List<Allenamento> allenamenti = <Allenamento>[];
final List<String> weekdays = dateTimeSymbolMap()['it'].WEEKDAYS;
final List<String> shortWeekDays = dateTimeSymbolMap()['it'].SHORTWEEKDAYS;

class Allenamento {
  final int id;
  String name, descrizione;
  List<Serie> serie = <Serie>[];

  Allenamento(
      {@required this.id,
      @required this.name,
      this.descrizione,
      Iterable<Serie> serie})
      : assert(name != null) {
    if (serie != null) this.serie.addAll(serie);
  }
  Allenamento.parse(Map<String, dynamic> raw) : this.id = raw['id'] {
    this.name = raw['name'];
    this.descrizione = raw['description'];
  }

  Ripetuta ripetutaFromIndex (int index) {
    for (Serie s in serie)
      for (int i = 0; i < s.ripetizioni; i++)
        for (Ripetuta r in s.ripetute)
          for (int j = 0; j < r.ripetizioni; j++)
            if (--index < 0) return r;
    return null;
  }
  int recuperoFromIndex (int index) {
    index--;
    if (index < 0) return null;
    for (Serie s in serie)
      for (int i = 1; i <= s.ripetizioni; i++)
        for (Ripetuta r in s.ripetute)
          for (int j = 1; j <= r.ripetizioni; j++)
            if (--index < 0) {
              if (j == r.ripetizioni) {
                if (r == s.ripetute.last) {
                  if (i == s.ripetizioni) {
                    if (s == serie.last) return null;
                    else return s.nextRecupero.recupero;
                  } else return s.recupero;
                } else return r.nextRecupero.recupero;
              } else return r.recupero;
            }
    return null;
  }

  int countRipetute() {
    return serie.fold(0, (sum, serie) => sum + serie.ripetuteCount);
  }

  Widget chip(
      {@required BuildContext context,
      double elevation = 0,
      bool enabled = true,
      void Function() onDelete}) {
    Widget child = Material(
      color: Colors.transparent,
      child: Chip(
        elevation: elevation,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: Theme.of(context).dialogBackgroundColor,
        shape: StadiumBorder(
          side: BorderSide(
            color: enabled ? Theme.of(context).primaryColor : Colors.grey[300],
          ),
        ),
        label: Text(
          name,
          style: Theme.of(context).textTheme.overline.copyWith(
              color: enabled ? null : Colors.grey[300],
              fontWeight: FontWeight.bold),
        ),
        onDeleted: onDelete,
      ),
    );
    return child;
  }

  @override
  String toString() => name;
}

class Serie {
  final int id;
  List<Ripetuta> ripetute = <Ripetuta>[];

  final LayerLink link = LayerLink();

  /// `recupero` in secondi
  int recupero;
  Recupero nextRecupero;

  /// `ripetizioni` quante volte ripetere la stessa `Serie` di fila
  int ripetizioni;

  Serie(
      {@required this.id,
      Iterable<Ripetuta> ripetute,
      this.recupero = 3 * 60,
      this.ripetizioni = 1,
      this.nextRecupero}) {
    if (ripetute != null) this.ripetute.addAll(ripetute);
  }
  Serie.parse(Map<String, dynamic> raw) : this.id = raw['id'] {
    recupero = raw['recupero'];
    nextRecupero = Recupero(raw['recuperoNext']);
    ripetizioni = raw['times'];
    allenamenti
        .firstWhere((allenamento) => allenamento.id == raw['allenamento'])
        .serie
        .add(this);
  }

  int get ripetuteCount {
    return ripetute.fold(0, (sum, rip) => sum + rip.ripetizioni) * ripetizioni;
  }
}

class TrainingRoute extends StatefulWidget {
  @override
  _TrainingRouteState createState() => _TrainingRouteState();
}

class _TrainingRouteState extends State<TrainingRoute> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('ALLENAMENTI')),
      body: allenamenti.isEmpty
          ? Center(child: Text('non hai creato ancora nessun allenamento'))
          : ListView(
              children: allenamenti
                  .map(
                    (a) => Dismissible(
                      key: ValueKey(a),
                      background: Container(
                        alignment: Alignment.centerLeft,
                        color: Theme.of(context).primaryColorLight,
                        padding: const EdgeInsets.only(left: 16),
                        child: Icon(Icons.delete),
                      ),
                      secondaryBackground: Container(
                        alignment: Alignment.centerRight,
                        color: Colors.lightGreen[200],
                        padding: const EdgeInsets.only(right: 16),
                        child: Icon(Icons.edit),
                      ),
                      onDismissed: (direction) {
                        setState(() => allenamenti.remove(a));
                        Batch b = db.batch();
                        b.delete('Ripetute',
                            where:
                                'serie IN (SELECT id FROM Series WHERE allenamento = ?)',
                            whereArgs: [a.id]);
                        b.delete('Series',
                            where: 'allenamento = ?', whereArgs: [a.id]);
                        b.delete('Trainings',
                            where: 'id = ?', whereArgs: [a.id]);
                        b.commit();
                      },
                      confirmDismiss: (direction) async {
                        if (direction == DismissDirection.startToEnd)
                          return await showDialog<bool>(
                              context: context,
                              builder: (context) =>
                                  deleteConfirmDialog(context, a.name));
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                TrainingInfoRoute(allenamento: a),
                          ),
                        );
                        setState(() {});
                        return false;
                      },
                      child: CustomExpansionTile(
                        title: a.name,
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Text(
                              a.descrizione ?? 'nessuna descrizione',
                              style: Theme.of(context).textTheme.overline,
                              textAlign: TextAlign.justify,
                            ),
                          )
                        ],
                        leading: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              a.countRipetute().toString(),
                              style: Theme.of(context).textTheme.headline5,
                            ),
                            Text(
                              'ripetute',
                              style: Theme.of(context).textTheme.overline,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final int id = await db.insert('Trainings', {
            'name': 'training #${allenamenti.length + 1}',
          });
          Allenamento allenamento = Allenamento(
            id: id,
            name: 'training #${allenamenti.length + 1}',
          );
          setState(() => allenamenti.add(allenamento));
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TrainingInfoRoute(
                allenamento: allenamento,
              ),
            ),
          );
          setState(() {});
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

class TrainingInfoRoute extends StatefulWidget {
  final Allenamento allenamento;
  TrainingInfoRoute({@required this.allenamento});
  @override
  _TrainingInfoRouteState createState() => _TrainingInfoRouteState();
}

class _TrainingInfoRouteState extends State<TrainingInfoRoute> {
  bool editTitle = false;
  bool collapsedDescription = true;
  TextEditingController _titleController;
  TextEditingController _descriptionController;

  @override
  void initState() {
    _titleController = TextEditingController(text: widget.allenamento.name);
    _descriptionController =
        TextEditingController(text: widget.allenamento.descrizione);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: editTitle
            ? TextFormField(
                style: Theme.of(context).textTheme.headline6,
                controller: _titleController,
              )
            : Text(widget.allenamento.name),
        actions: <Widget>[
          if (editTitle)
            IconButton(
                icon: Icon(Icons.cancel),
                onPressed: () => setState(() {
                      editTitle = !editTitle;
                      _titleController.text = widget.allenamento.name;
                    })),
          IconButton(
            icon: Icon(editTitle ? Icons.check : Icons.edit),
            onPressed: () {
              db.update(
                'Trainings',
                {'name': _titleController.text},
                where: 'id = ?',
                whereArgs: [widget.allenamento.id],
              );
              setState(() {
                editTitle = !editTitle;
                widget.allenamento.name = _titleController.text;
              });
            },
          ),
        ],
      ),
      body: Column(
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          AnimatedContainer(
            duration: Duration(milliseconds: 200),
            height: collapsedDescription ? kToolbarHeight : 200,
            child: Row(
              children: <Widget>[
                IconButton(
                  icon: Icon(
                    collapsedDescription
                        ? Icons.expand_more
                        : Icons.expand_less,
                    color: Theme.of(context).primaryColorDark,
                  ),
                  onPressed: () => setState(
                      () => collapsedDescription = !collapsedDescription),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: _descriptionController,
                      maxLines: 1000,
                      decoration: InputDecoration(
                        hintText: 'inserisci la descrizione (opzionale)',
                      ),
                      onChanged: (text) {
                        db.update(
                          'Trainings',
                          {'description': text},
                          where: 'id = ?',
                          whereArgs: [widget.allenamento.id],
                        );
                        widget.allenamento.descrizione = text;
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Stack(
                children: () sync* {
                  yield Column(
                    children: () sync* {
                      for (Serie serie in widget.allenamento.serie) {
                        yield Dismissible(
                          key: ValueKey(serie),
                          direction: DismissDirection.startToEnd,
                          confirmDismiss: (d) async => await showDialog(
                            context: context,
                            builder: (context) => deleteConfirmDialog(
                              context,
                              'serie #${widget.allenamento.serie.indexOf(serie) + 1}',
                            ),
                          ),
                          onDismissed: (direction) {
                            db.delete('Series',
                                where: 'id = ?', whereArgs: [serie.id]);
                            setState(() {
                              widget.allenamento.serie.remove(serie);
                            });
                          },
                          background: Container(
                            alignment: Alignment.centerLeft,
                            color: Theme.of(context).primaryColorLight,
                            child: Icon(Icons.delete),
                            padding: const EdgeInsets.only(left: 16),
                          ),
                          child: CustomExpansionTile(
                            children: [
                              if (serie.ripetute.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.only(
                                      top: 4, bottom: 20, right: 4, left: 4),
                                  color: Theme.of(context).primaryColor,
                                  child: Stack(
                                    children: () sync* {
                                      yield Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: () sync* {
                                            for (Ripetuta rip
                                                in serie.ripetute) {
                                              yield rip.widget(
                                                  context, setState,
                                                  serie: serie);
                                              if (rip != serie.ripetute.last)
                                                yield CompositedTransformTarget(
                                                  link: rip.link,
                                                  child: Container(
                                                    width: double.infinity,
                                                    height: 0,
                                                  ),
                                                );
                                            }
                                          }()
                                              .toList());
                                      for (Ripetuta rip in serie.ripetute.where(
                                          (rip) => rip != serie.ripetute.last && rip.nextRecupero != null))
                                        yield CompositedTransformFollower(
                                          showWhenUnlinked: false,
                                          link: rip.link,
                                          child: rip.nextRecupero.widget(
                                            context,
                                            setState,
                                            onChanged: () => db.update(
                                              'Ripetute',
                                              {
                                                'recuperoNext':
                                                    rip.nextRecupero.recupero
                                              },
                                              where: 'id = ?',
                                              whereArgs: [rip.id],
                                            ),
                                          ),
                                          offset: const Offset(0, -16),
                                        );
                                    }()
                                        .toList(),
                                  ),
                                )
                            ],
                            title:
                                'serie #${widget.allenamento.serie.indexOf(serie) + 1}',
                            subtitle: Text(
                              '${serie.ripetuteCount} ripetut${serie.ripetuteCount == 1 ? 'a' : 'e'}',
                              style: Theme.of(context)
                                  .textTheme
                                  .overline
                                  .copyWith(
                                    color: Theme.of(context).primaryColorDark,
                                  ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Stack(
                                  alignment: Alignment.bottomCenter,
                                  children: <Widget>[
                                    IconButton(
                                      icon: Icon(
                                        serie.ripetizioni > 1
                                            ? Icons.timer
                                            : Icons.timer_off,
                                      ),
                                      onPressed: serie.ripetizioni > 1
                                          ? () async {
                                              serie.recupero =
                                                  (await showDurationDialog(
                                                context,
                                                Duration(
                                                  seconds: serie.recupero,
                                                ),
                                              ))
                                                      .inSeconds;
                                              db.update(
                                                'Series',
                                                {'recupero': serie.recupero},
                                                where: 'id = ?',
                                                whereArgs: [serie.id],
                                              );
                                              setState(() {});
                                            }
                                          : null,
                                      disabledColor: Colors.grey[300],
                                      color: Colors.black,
                                    ),
                                    if (serie.ripetizioni > 1)
                                      Text(
                                        '${serie.recupero ~/ 60}:${(serie.recupero % 60).toString().padLeft(2, '0')}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .overline,
                                      )
                                  ],
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.add_circle,
                                    color: Colors.black,
                                  ),
                                  onPressed: () async {
                                    await Ripetuta.fromDialog(
                                      context: context,
                                      serie: serie,
                                    );
                                    setState(() {});
                                  },
                                ),
                              ],
                            ),
                            leading: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: <Widget>[
                                    InkWell(
                                      onTap: serie ==
                                              widget.allenamento.serie.first
                                          ? null
                                          : () {
                                              int index = widget
                                                  .allenamento.serie
                                                  .indexOf(serie);
                                              widget.allenamento.serie.insert(
                                                index - 1,
                                                widget.allenamento.serie
                                                    .removeAt(index),
                                              );
                                              Batch b = db.batch();
                                              b.update('Series',
                                                  {'position': index - 1},
                                                  where: 'id = ?',
                                                  whereArgs: [serie.id]);
                                              b.update(
                                                  'Series', {'position': index},
                                                  where: 'id = ?',
                                                  whereArgs: [
                                                    widget.allenamento
                                                        .serie[index].id
                                                  ]);
                                              b.commit();
                                              setState(() {});
                                            },
                                      child: Icon(
                                        Icons.expand_less,
                                        color: serie ==
                                                widget.allenamento.serie.first
                                            ? Colors.grey[300]
                                            : Theme.of(context)
                                                .primaryColorDark,
                                      ),
                                    ),
                                    InkWell(
                                      onTap: serie ==
                                              widget.allenamento.serie.last
                                          ? null
                                          : () {
                                              int index = widget
                                                  .allenamento.serie
                                                  .indexOf(serie);
                                              widget.allenamento.serie.insert(
                                                index + 1,
                                                widget.allenamento.serie
                                                    .removeAt(index),
                                              );
                                              Batch b = db.batch();
                                              b.update('Series',
                                                  {'position': index + 1},
                                                  where: 'id = ?',
                                                  whereArgs: [serie.id]);
                                              b.update(
                                                  'Series', {'position': index},
                                                  where: 'id = ?',
                                                  whereArgs: [
                                                    widget.allenamento
                                                        .serie[index].id
                                                  ]);
                                              b.commit();
                                              setState(() {});
                                            },
                                      child: Icon(
                                        Icons.expand_more,
                                        color: serie ==
                                                widget.allenamento.serie.last
                                            ? Colors.grey[300]
                                            : Theme.of(context)
                                                .primaryColorDark,
                                      ),
                                    ),
                                  ],
                                ),
                                GestureDetector(
                                  onTap: () {
                                    db.update(
                                      'Series',
                                      {'times': serie.ripetizioni % 10 + 1},
                                      where: 'id = ?',
                                      whereArgs: [serie.id],
                                    );
                                    setState(() => serie.ripetizioni =
                                        serie.ripetizioni % 10 + 1);
                                  },
                                  onLongPress: () {
                                    db.update(
                                      'Series',
                                      {'times': 1},
                                      where: 'id = ?',
                                      whereArgs: [serie.id],
                                    );
                                    setState(() => serie.ripetizioni = 1);
                                  },
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: <Widget>[
                                      Text(
                                        'x',
                                        style: Theme.of(context)
                                            .textTheme
                                            .overline,
                                      ),
                                      Text(
                                        serie.ripetizioni.toString(),
                                        style: Theme.of(context)
                                            .textTheme
                                            .headline5
                                            .copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: Color.lerp(
                                                Theme.of(context)
                                                    .primaryColorDark,
                                                Colors.redAccent[700],
                                                serie.ripetizioni / 10,
                                              ),
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                        if (serie != widget.allenamento.serie.last)
                          yield CompositedTransformTarget(
                            link: serie.link,
                            child: Container(
                              height: 0,
                              width: double.infinity,
                            ),
                          );
                      }
                    }()
                        .toList(),
                  );
                  for (Serie serie in widget.allenamento.serie
                      .where((serie) => serie != widget.allenamento.serie.last))
                    yield CompositedTransformFollower(
                      link: serie.link,
                      showWhenUnlinked: false,
                      child: serie.nextRecupero.widget(
                        context,
                        setState,
                        onChanged: () => db.update(
                          'Series',
                          {'recuperoNext': serie.nextRecupero.recupero},
                          where: 'id = ?',
                          whereArgs: [serie.id],
                        ),
                      ),
                      offset: const Offset(0, -16),
                    );
                }()
                    .toList(),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          int id = await db.insert('Series', {
            'allenamento': widget.allenamento.id,
            'position': widget.allenamento.serie.length,
            'recupero': 3 * 60,
            'times': 1,
            'recuperoNext': 3 * 60
          });
          setState(
            () {
              widget.allenamento.serie.add(
                Serie(id: id, nextRecupero: Recupero(3 * 60)),
              );
            },
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
