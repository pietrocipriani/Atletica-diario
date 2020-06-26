import 'package:Atletica/alert_point.dart';
import 'package:Atletica/allenamento.dart';
import 'package:Atletica/auth.dart';
import 'package:Atletica/database.dart';
import 'package:Atletica/main.dart';
import 'package:Atletica/tabella.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

List<Group> groups = <Group>[];

bool exists(String name) => groups.any(
      (group) => group.atleti.any(
        (atleta) => atleta.name == name,
      ),
    );

class Group {
  final int id;
  String name;
  Tabella tabella;
  DateTime started;
  final List<Atleta> atleti = <Atleta>[];

  Group({@required this.id, @required this.name, this.tabella, this.started});
  Group.parse(Map<String, dynamic> raw) : this.id = raw['id'] {
    name = raw['name'];
    tabella = plans.firstWhere(
      (plan) => plan.name == raw['planName'],
      orElse: () => null,
    );
    started = raw['started'] == null ? null : DateTime.parse(raw['started']);
  }
}

class Atleta {
  final int id;
  String name;
  List<Allenamento> allenamenti = <Allenamento>[];

  Atleta(this.id, this.name);
  Atleta.parse(Map<String, dynamic> raw) : id = raw['id'] {
    name = raw['name'];
    groups.firstWhere((group) => group.id == raw['workGroup']).atleti.add(this);
  }

  static Future<bool> fromDialog(
      {@required BuildContext context, String name}) {
    return showDialog<bool>(
      context: context,
      builder: (context) => _dialog(context: context, name: name),
    );
  }

  Future<bool> modify({@required BuildContext context}) {
    return showDialog<bool>(
      context: context,
      builder: (context) => _dialog(context: context, atleta: this),
    );
  }

  static Widget _dialog(
      {@required BuildContext context, Atleta atleta, String name}) {
    bool isNew = atleta == null;
    TextEditingController controller =
        TextEditingController(text: atleta?.name ?? name);
    String Function(String) validator = (value) {
      if (value == null || value.isEmpty) return 'inserire il nome';
      if (value != atleta?.name && exists(value))
        return isNew ? 'atleta già inserito' : 'nome già esistente';
      return null;
    };
    FocusNode addGroupNode = FocusNode();
    Group selectedGroup = groups.firstWhere(
          (group) => group.atleti.contains(atleta),
          orElse: () => null,
        ) ??
        (groups.isNotEmpty ? groups.first : null);
    TextEditingController groupController = TextEditingController();
    String Function(String) groupValidator = (value) {
      if (selectedGroup != null) return null;
      if (value == null || value.isEmpty) return 'inserisci un nome';
      if (groups.any((group) => group.name == value))
        return 'gruppo già esistente';
      return null;
    };

    return StatefulBuilder(
      builder: (context, ss) => AlertDialog(
        title: Text('${isNew ? 'Aggiungi' : 'Modifica'} Atleta'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(
                controller: controller,
                autovalidate: true,
                autofocus: false,
                validator: validator,
                decoration: InputDecoration(
                  labelText: 'Nome',
                ),
                onChanged: (value) => ss(() {}),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'seleziona il gruppo:',
                  style: Theme.of(context).textTheme.bodyText1,
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Radio(
                    value: null,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    groupValue: selectedGroup,
                    onChanged: (value) {
                      addGroupNode.requestFocus();
                      ss(() => selectedGroup = value);
                    },
                  ),
                  Expanded(
                    child: TextFormField(
                      onTap: () => ss(() => selectedGroup = null),
                      controller: groupController,
                      autovalidate: true,
                      maxLines: 1,
                      validator: groupValidator,
                      focusNode: addGroupNode,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'nuovo gruppo',
                        //border: InputBorder.none,
                      ),
                      style: Theme.of(context).textTheme.overline,
                      onChanged: (v) => ss(() {}),
                    ),
                  )
                ],
              )
            ]..addAll(
                groups.map(
                  (group) => Row(
                    children: <Widget>[
                      Radio(
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        value: group,
                        groupValue: selectedGroup,
                        onChanged: (value) {
                          FocusScope.of(context).requestFocus();
                          ss(() => selectedGroup = value);
                        },
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => ss(() => selectedGroup = group),
                          child: Text(
                            group.name,
                            style: selectedGroup == group ||
                                    (group.atleti.isNotEmpty &&
                                        (group.atleti.length != 1 ||
                                            group.atleti.first != atleta))
                                ? Theme.of(context).textTheme.overline
                                : Theme.of(context).textTheme.overline.copyWith(
                                      decoration: TextDecoration.lineThrough,
                                    ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: <Widget>[
          FlatButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Annulla',
            ),
          ),
          FlatButton(
            onPressed: validator(controller.text) != null ||
                    (selectedGroup == null &&
                        groupValidator(groupController.text) != null)
                ? null
                : () async {
                    if (selectedGroup == null) {
                      selectedGroup = Group(
                        id: await db
                            .insert('Groups', {'name': groupController.text}),
                        name: groupController.text,
                      );
                      groups.add(selectedGroup);
                    }
                    if (isNew)
                      selectedGroup.atleti.add(
                        Atleta(
                            await db.insert('Athletes', {
                              'name': controller.text,
                              'workGroup': selectedGroup.id
                            }),
                            controller.text),
                      );
                    else {
                      atleta.name = controller.text;
                      db.update(
                        'Athletes',
                        {
                          'name': controller.text,
                          'workGroup': selectedGroup.id
                        },
                        where: 'id = ?',
                        whereArgs: [atleta.id],
                      );
                      if (!selectedGroup.atleti.contains(atleta)) {
                        groups.any((group) => group.atleti.remove(atleta));
                        selectedGroup.atleti.add(atleta);
                      }
                    }
                    String toRemove = groups
                        .where((group) => group.atleti.isEmpty)
                        .map((group) => group.id)
                        .toString();
                    db.delete('Groups', where: 'id IN (?)', whereArgs: [
                      toRemove.substring(1, toRemove.length - 1)
                    ]);
                    groups.removeWhere((group) => group.atleti.isEmpty);
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

class AthletesRoute extends StatefulWidget {
  @override
  _AthletesRouteState createState() => _AthletesRouteState();
}

class _AthletesRouteState extends State<AthletesRoute> {

  Callback<Event> _callback = Callback<Event>();

  @override
  void initState () {
    _callback.f = (evt) => setState(() {});
    user.requestCallbacks.add(_callback);
    super.initState();
  }

  @override
  void dispose () {
    user.requestCallbacks.remove(_callback..active = false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('ATLETI')),
      body: groups.every((group) => group.atleti.isEmpty) &&
              (user?.requests?.isEmpty ?? true)
          ? Center(
              child: Text(
                'non hai nessun atleta',
              ),
            )
          : ListView(
              children: () sync* {
              if (user?.requests?.isNotEmpty ?? false)
                yield Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'nuove richieste',
                    style: Theme.of(context).textTheme.headline6,
                    textAlign: TextAlign.center,
                  ),
                );
              for (BasicUser request in user?.requests ?? <BasicUser>[])
                yield Dismissible(
                  key: ValueKey(request),
                  child: ListTile(
                    leading: Icon(
                      Icons.new_releases,
                      color: Theme.of(context).primaryColorDark,
                    ),
                    title: Text(
                      request.name,
                      style: Theme.of(context)
                          .textTheme
                          .subtitle1
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      request.email,
                      style: Theme.of(context).textTheme.overline.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColorDark,
                          ),
                    ),
                  ),
                  background: Container(
                    color: Theme.of(context).primaryColorLight,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 16),
                    child: Icon(Icons.clear),
                  ),
                  secondaryBackground: Container(
                    color: Colors.lightGreen[200],
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    child: Icon(Icons.check),
                  ),
                  onDismissed: (direction) async {
                    if (direction == DismissDirection.startToEnd)
                      await user.refuseRequest(request.uid);
                    else 
                      await user.acceptRequest(request);
                  },
                  confirmDismiss: (direction) async {
                    if (direction == DismissDirection.startToEnd) return true;
                    return await Atleta.fromDialog(
                        context: context, name: request.name);
                  },
                );

              if (groups.any((group) => group.atleti.isNotEmpty))
                yield Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'i tuoi atleti',
                    style: Theme.of(context).textTheme.headline6,
                    textAlign: TextAlign.center,
                  ),
                );
              for (Group group in groups)
                for (Atleta a in group.atleti)
                  yield Dismissible(
                    key: ValueKey(a),
                    child: ListTile(
                      title: Text(
                        a.name,
                        style: Theme.of(context)
                            .textTheme
                            .subtitle1
                            .copyWith(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        group.name,
                        style: Theme.of(context).textTheme.overline.copyWith(
                              color: Theme.of(context).primaryColorDark,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            a.allenamenti.length.toString(),
                            style: Theme.of(context).textTheme.headline5,
                          ),
                          Text(
                            'allenament${a.allenamenti.length == 1 ? 'o' : 'i'}',
                            style: Theme.of(context).textTheme.overline,
                          )
                        ],
                      ),
                    ),
                    background: Container(
                      color: Theme.of(context).primaryColorLight,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(left: 16),
                      child: Icon(Icons.delete),
                    ),
                    secondaryBackground: Container(
                      color: Colors.lightGreen[200],
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16),
                      child: Icon(Icons.edit),
                    ),
                    onDismissed: (direction) {
                      group.atleti.remove(a);
                      db.delete(
                        'Athletes',
                        where: 'id = ?',
                        whereArgs: [a.id],
                      );
                      if (group.atleti.isEmpty) {
                        db.delete(
                          'Groups',
                          where: 'id = ?',
                          whereArgs: [group.id],
                        );
                        groups.remove(group);
                      }
                    },
                    direction: DismissDirection.horizontal,
                    confirmDismiss: (direction) async {
                      if (direction == DismissDirection.endToStart) {
                        if (await a.modify(context: context) ?? false)
                          setState(() {});
                        return false;
                      }
                      return await showDialog<bool>(
                        context: context,
                        builder: (context) =>
                            deleteConfirmDialog(context, a.name),
                      );
                    },
                  );
            }()
                  .toList()),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (await Atleta.fromDialog(context: context) ?? false)
            setState(() {});
        },
        tooltip: 'aggiungi un atleta',
        child: Icon(Icons.add),
      ),
    );
  }
}
