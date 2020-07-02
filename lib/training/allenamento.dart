import 'package:Atletica/global_widgets/custom_dismissible.dart';
import 'package:Atletica/global_widgets/custom_expansion_tile.dart';
import 'package:Atletica/global_widgets/delete_confirm_dialog.dart';
import 'package:Atletica/global_widgets/duration_picker.dart';
import 'package:Atletica/persistence/auth.dart';
import 'package:Atletica/persistence/user_helper/coach_helper.dart';
import 'package:Atletica/recupero/recupero.dart';
import 'package:Atletica/ripetuta/ripetuta.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

final Map<DocumentReference, Allenamento> allenamenti =
    <DocumentReference, Allenamento>{};
final List<String> weekdays = dateTimeSymbolMap()['it'].WEEKDAYS;
final List<String> shortWeekDays = dateTimeSymbolMap()['it'].SHORTWEEKDAYS;

class Allenamento {
  final DocumentReference reference;
  String name, descrizione;
  List<Serie> serie = <Serie>[];

  bool waitingForChanges = false;
  bool dismissed = false;

  Allenamento.parse(DocumentSnapshot raw)
      : assert(raw != null && raw['name'] != null),
        reference = raw.reference,
        name = raw['name'],
        descrizione = raw['description'],
        serie = raw['serie']?.map<Serie>((raw) => Serie.parse(raw))?.toList() ??
            <Serie>[] {
    allenamenti[reference] = this;
  }

  static Future<void> create() =>
      userC.coachReference.collection('trainings').add({
        'name': 'training #${allenamenti.length + 1}',
        'description': null,
        'serie': []
      });

  Ripetuta ripetutaFromIndex(int index) {
    for (Serie s in serie)
      for (int i = 0; i < s.ripetizioni; i++)
        for (Ripetuta r in s.ripetute)
          for (int j = 0; j < r.ripetizioni; j++) if (--index < 0) return r;
    return null;
  }

  Future<void> delete() {
    dismissed = true;
    return reference.delete();
  }

  Future<void> save() {
    waitingForChanges = true;
    return reference.setData({
      'name': name,
      'description': descrizione,
      'serie': serie.map((serie) => serie.asMap).toList()
    });
  }

  Recupero recuperoFromIndex(int index) {
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
                    if (s == serie.last)
                      return null;
                    else
                      return s.nextRecupero;
                  } else
                    return s.recupero;
                } else
                  return r.nextRecupero;
              } else
                return r.recupero;
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
  List<Ripetuta> ripetute = <Ripetuta>[];

  final LayerLink link = LayerLink();

  Recupero nextRecupero, recupero;

  /// `ripetizioni` quante volte ripetere la stessa `Serie` di fila
  int ripetizioni;

  Serie(
      {Iterable<Ripetuta> ripetute,
      this.recupero,
      this.ripetizioni = 1,
      this.nextRecupero}) {
    recupero ??= Recupero();
    nextRecupero ??= Recupero();
    if (ripetute != null) this.ripetute.addAll(ripetute);
  }
  Serie.parse(Map raw) {
    recupero = Recupero(raw['recupero'] ?? 3 * 60);
    nextRecupero = Recupero(raw['recuperoNext'] ?? 3 * 60);
    ripetizioni = raw['times'];
    ripetute = raw['ripetute']
            ?.map<Ripetuta>((raw) => Ripetuta.parse(raw))
            ?.toList() ??
        <Ripetuta>[];
  }

  Map<String, dynamic> get asMap => {
        'recuperoNext': nextRecupero.recupero,
        'recupero': recupero.recupero,
        'times': ripetizioni,
        'ripetute': ripetute.map((rip) => rip.asMap).toList()
      };

  int get ripetuteCount {
    return ripetute.fold(0, (sum, rip) => sum + rip.ripetizioni) * ripetizioni;
  }
}

class TrainingRoute extends StatefulWidget {
  @override
  _TrainingRouteState createState() => _TrainingRouteState();
}

class _TrainingRouteState extends State<TrainingRoute> {
  final Callback callback = Callback();

  @override
  void initState() {
    callback.f = (_) => setState(() {});
    CoachHelper.onTrainingCallbacks.add(callback);
    super.initState();
  }

  @override
  void dispose() {
    CoachHelper.onTrainingCallbacks.remove(callback.stopListening);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('ALLENAMENTI')),
      body: allenamenti.isEmpty
          ? Center(child: Text('non hai creato ancora nessun allenamento'))
          : ListView(
              children: allenamenti.values
                  .where((a) => !a.dismissed)
                  .map(
                    (a) => CustomDismissible(
                      key: ValueKey(a),
                      onDismissed: (direction) => a.delete(),
                      confirmDismiss: (direction) async {
                        if (direction == DismissDirection.startToEnd)
                          return await showDeleteConfirmDialog(
                            context: context,
                            name: a.name,
                          );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  TrainingInfoRoute(allenamento: a)),
                        ).then((value) => a.save());
                        return false;
                      },
                      child: CustomExpansionTile(
                        title: a.name,
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Text(
                              a.descrizione == null || a.descrizione.isEmpty
                                  ? 'nessuna descrizione'
                                  : a.descrizione,
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
          await Allenamento.create();
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

// TODO: program  training without plan, in a single date

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
            onPressed: () => setState(() {
              editTitle = !editTitle;
              widget.allenamento.name = _titleController.text;
            }),
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
                    () => collapsedDescription = !collapsedDescription,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: _descriptionController,
                      maxLines: 1000,
                      autofocus: false,
                      decoration: InputDecoration(
                        hintText: 'inserisci la descrizione (opzionale)',
                      ),
                      onChanged: (text) =>
                          widget.allenamento.descrizione = text,
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
                        yield CustomDismissible(
                          key: ValueKey(serie),
                          direction: DismissDirection.startToEnd,
                          confirmDismiss: (d) => showDeleteConfirmDialog(
                            context: context,
                            name:
                                'serie #${widget.allenamento.serie.indexOf(serie) + 1}',
                          ),
                          onDismissed: (direction) => setState(
                              () => widget.allenamento.serie.remove(serie)),
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
                                          (rip) =>
                                              rip != serie.ripetute.last &&
                                              rip.nextRecupero != null))
                                        yield CompositedTransformFollower(
                                          showWhenUnlinked: false,
                                          link: rip.link,
                                          child: rip.nextRecupero
                                              .widget(context, setState),
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
                                              final Duration duration =
                                                  await showDurationDialog(
                                                context,
                                                Duration(
                                                    seconds: serie
                                                        .recupero.recupero),
                                              );
                                              if (duration == null) return;
                                              setState(() => serie.recupero =
                                                  Recupero(duration.inSeconds));
                                            }
                                          : null,
                                      disabledColor: Colors.grey[300],
                                      color: Colors.black,
                                    ),
                                    if (serie.ripetizioni > 1)
                                      Text(
                                        serie.recupero.toString(),
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
                                    Ripetuta rip = await Ripetuta.fromDialog(
                                        context: context);
                                    if (rip == null) return;
                                    setState(() => serie.ripetute.add(rip));
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
                                    setState(() => serie.ripetizioni =
                                        serie.ripetizioni % 10 + 1);
                                  },
                                  onLongPress: () {
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
                      child: serie.nextRecupero.widget(context, setState),
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
        onPressed: () => setState(() => widget.allenamento.serie.add(Serie())),
        child: Icon(Icons.add),
      ),
    );
  }
}
