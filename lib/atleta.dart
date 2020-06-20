import 'package:Atletica/allenamento.dart';
import 'package:Atletica/database.dart';
import 'package:Atletica/main.dart';
import 'package:Atletica/tabella.dart';
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

  static Future<bool> fromDialog({@required BuildContext context}) {
    return showDialog<bool>(
      context: context,
      builder: (context) => _dialog(context: context),
    );
  }

  Future<bool> modify({@required BuildContext context}) {
    return showDialog<bool>(
      context: context,
      builder: (context) => _dialog(context: context, atleta: this),
    );
  }

  static Widget _dialog({@required BuildContext context, Atleta atleta}) {
    bool isNew = atleta == null;
    TextEditingController controller =
        TextEditingController(text: atleta?.name);
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('ATLETI')),
      body: !groups.any((group) => group.atleti.isNotEmpty)
          ? Center(
              child: Text(
                'non hai nessun atleta',
              ),
            )
          : ListView(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'i tuoi atleti',
                    style: Theme.of(context).textTheme.headline6,
                    textAlign: TextAlign.center,
                  ),
                )
              ]..addAll(
                  groups.expand(
                    (group) => group.atleti.map(
                      (a) => Dismissible(
                        key: ValueKey(a),
                        child: ListTile(
                          title: Text(
                            a.name,
                            style: Theme.of(context)
                                .textTheme
                                .subtitle1
                                .merge(TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          subtitle: Text(
                            group.name,
                            style:
                                Theme.of(context).textTheme.overline.copyWith(
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
                      ),
                    ),
                  ),
                ),
            ),
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
