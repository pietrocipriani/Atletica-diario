import 'package:Atletica/athlete/atleta.dart';
import 'package:Atletica/athlete/group.dart';
import 'package:Atletica/persistence/database.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqlite_api.dart';

String _validator(String value, Atleta atleta, bool isNew) {
  if (value == null || value.isEmpty) return 'inserire il nome';
  if (value != atleta?.name && existsInGroup(value))
    return isNew ? 'atleta già inserito' : 'nome già esistente';
  return null;
}

String _newGroupValidator(String name) {
  if (name == null || name.isEmpty) return 'inserisci un nome';
  if (groups.any((group) => group.name == name)) return 'gruppo già esistente';
  return null;
}

Group _selectedGroup(Atleta atleta) => groups.firstWhere(
      (group) => group.atleti.contains(atleta),
      orElse: () {
        if (lastGroup != null && groups.contains(lastGroup)) return lastGroup;
        if (groups.isNotEmpty) return groups.first;
        return null;
      },
    );

/// function to define if `group` should be deleted after modify/adding `atleta`.
/// to estabilish that we need to know if `selectedGroup` is the `group` in question or not
bool _shouldRemoveGroup(Group group, Group selectedGroup, Atleta atleta) {
  return selectedGroup != group &&
      (group.atleti.isEmpty ||
          (group.atleti.length == 1 && group.atleti.first == atleta));
}

Widget dialog({@required BuildContext context, Atleta atleta, String name}) {
  final TextStyle bodyText1 = Theme.of(context).textTheme.bodyText1;
  final TextStyle overline = Theme.of(context).textTheme.overline;
  final TextStyle overlineLineThrough = overline.copyWith(
    decoration: TextDecoration.lineThrough,
  );

  bool isNew = atleta == null;
  final String mode = isNew ? 'Aggiungi' : 'Modifica';
  final TextEditingController controller =
      TextEditingController(text: atleta?.name ?? name);

  final FocusNode addGroupNode = FocusNode();
  Group selectedGroup = _selectedGroup(atleta);

  final TextEditingController groupController = TextEditingController();

  final String Function(String) groupValidator = (value) {
    if (selectedGroup != null) return null;
    return _newGroupValidator(value);
  };

  final Widget title = Text('$mode Atleta');
  final Widget groupSelectorTitle = Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Text('seleziona il gruppo:', style: bodyText1),
  );

  final Widget cancel = FlatButton(
    onPressed: () => Navigator.pop(context, false),
    child: Text('Annulla'),
  );

  return StatefulBuilder(
    builder: (context, ss) => AlertDialog(
      title: title,
      scrollable: true,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextFormField(
            controller: controller,
            autovalidate: true,
            autofocus: true,
            validator: (str) => _validator(str, atleta, isNew),
            decoration: InputDecoration(labelText: 'Nome'),
            onChanged: (value) => ss(() {}),
          ),
          groupSelectorTitle,
          _GroupSelector(
            value: null,
            groupValue: selectedGroup,
            label: TextFormField(
              onTap: () => ss(() => selectedGroup = null),
              controller: groupController,
              autovalidate: true,
              maxLines: 1,
              validator: groupValidator,
              focusNode: addGroupNode,
              decoration:
                  InputDecoration(isDense: true, hintText: 'nuovo gruppo'),
              style: overline,
              onChanged: (v) => ss(() {}),
            ),
            onTap: (group) {
              addGroupNode.requestFocus();
              ss(() => selectedGroup = group);
            },
          ),
        ]
            .followedBy(
              groups.map(
                (group) => _GroupSelector(
                  groupValue: selectedGroup,
                  value: group,
                  onTap: (group) {
                    FocusScope.of(context).requestFocus();
                    ss(() => selectedGroup = group);
                  },
                  label: Text(
                    group.name,
                    style: _shouldRemoveGroup(group, selectedGroup, atleta)
                        ? overlineLineThrough
                        : overline,
                  ),
                ),
              ),
            )
            .toList(),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      actions: <Widget>[
        cancel,
        FlatButton(
          onPressed: _validator(controller.text, atleta, isNew) != null ||
                  (selectedGroup == null &&
                      groupValidator(groupController.text) != null)
              ? null
              : () async {
                  lastGroup = selectedGroup ??= await Group.createSaveAddReturn(
                    name: groupController.text,
                  );
                  if (isNew)
                    await Atleta.createSaveAddReturn(
                      name: controller.text,
                      group: selectedGroup,
                    );
                  else
                    atleta.update(
                      name: controller.text,
                      group: selectedGroup,
                    );

                  final Batch b = db.batch();
                  groups.removeWhere(
                    (group) => group.delete(batch: b, removeFromList: false),
                  );
                  b.commit();
                  Navigator.pop(context, true);
                },
          child: Text(mode),
        ),
      ],
    ),
  );
}

class _GroupSelector extends StatelessWidget {
  final Group value;
  final Group groupValue;
  final Widget label;
  final Function(Group value) onTap;

  _GroupSelector({
    @required this.value,
    @required this.groupValue,
    @required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Radio(
          value: value,
          groupValue: groupValue,
          onChanged: onTap,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        Expanded(
            child: GestureDetector(
          child: label,
          onTap: () => onTap(value),
        ))
      ],
    );
  }
}
