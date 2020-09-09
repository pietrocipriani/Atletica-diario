import 'package:Atletica/athlete/atleta.dart';
import 'package:Atletica/athlete/group.dart';
import 'package:Atletica/persistence/auth.dart';
import 'package:flutter/material.dart';

String _validator(String value, Athlete atleta, bool isNew) {
  if (value == null || value.isEmpty) return 'inserire il nome';
  if (value != atleta?.name && userC.athletes.any((a) => a.name == value))
    return isNew ? 'atleta già inserito' : 'nome già esistente';
  return null;
}

String _newGroupValidator(String name) {
  if (name == null || name.isEmpty) return 'inserisci un nome';
  if (Group.groups.any((group) => group.name == name))
    return 'gruppo già esistente';
  return null;
}

/// function to define if `group` should be deleted after modify/adding `atleta`.
/// to estabilish that we need to know if `selectedGroup` is the `group` in question or not
bool _shouldRemoveGroup(Group group, Group selectedGroup, Athlete atleta) {
  final List<Athlete> athletes = group.athletes;
  return selectedGroup != group &&
      (athletes.isEmpty || (athletes.length == 1 && athletes.first == atleta));
}

Widget dialog({@required BuildContext context, Athlete atleta}) {
  final TextStyle bodyText1 = Theme.of(context).textTheme.bodyText1;
  final TextStyle overlineSelected = Theme.of(context).textTheme.overline;
  final TextStyle overline =
      overlineSelected.copyWith(fontWeight: FontWeight.normal);
  final TextStyle overlineLineThrough =
      overline.copyWith(decoration: TextDecoration.lineThrough);

  bool isNew = atleta == null || atleta.isRequest;
  final String mode = isNew ? 'Aggiungi' : 'Modifica';
  final TextEditingController controller =
      TextEditingController(text: atleta?.name);

  final FocusNode addGroupNode = FocusNode();
  final String groupName = atleta?.group ?? lastGroup;
  Group selectedGroup =
      groupName == null ? Group.groups.first : Group(name: groupName);

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
            autovalidateMode: AutovalidateMode.onUserInteraction,
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
              autovalidateMode: AutovalidateMode.onUserInteraction,
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
              Group.groups.map(
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
                        : selectedGroup == group
                            ? overlineSelected
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
                  String group = selectedGroup?.name ?? groupController.text;
                  print('group: $group');
                  if (atleta != null)
                    await atleta.update(
                        nickname: controller.text, group: group);
                  else
                    Athlete.create(nickname: controller.text, group: group);
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
