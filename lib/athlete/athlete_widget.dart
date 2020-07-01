import 'package:Atletica/athlete/atleta.dart';
import 'package:Atletica/athlete/group.dart';
import 'package:Atletica/global_widgets/custom_dismissible.dart';
import 'package:Atletica/global_widgets/delete_confirm_dialog.dart';
import 'package:Atletica/main.dart';
import 'package:flutter/material.dart';

class AthleteWidget extends StatelessWidget {
  final Atleta atleta;
  final Group group;
  final TextStyle subtitle1Bold, overlineBoldPrimaryDark;
  final void Function() onModified;

  AthleteWidget({
    Key key,
    @required this.atleta,
    @required this.group,
    @required this.subtitle1Bold,
    @required this.overlineBoldPrimaryDark,
    this.onModified,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final int trainingsCount = atleta.allenamenti.length;
    final Widget trailing = Column(children: <Widget>[
      Text('$trainingsCount', style: Theme.of(context).textTheme.headline5),
      Text(
        singularPlural('allenament', 'o', 'i', trainingsCount),
        style: Theme.of(context).textTheme.overline,
      )
    ]);
    final Widget child = ListTile(
      title: Text(atleta.name, style: subtitle1Bold),
      subtitle: Text(group.name, style: overlineBoldPrimaryDark),
      trailing: trailing,
    );

    Future<bool> confirmDismiss(DismissDirection dir) async {
      if (dir == DismissDirection.startToEnd)
        return await showDeleteConfirmDialog(
          context: context,
          name: atleta.name,
        );
      else {
        atleta.modify(context: context).then((ok) {
          if (ok ?? false) onModified?.call();
        });
        return false;
      }
    }

    return CustomDismissible(
      key: ValueKey(atleta),
      child: child,
      onDismissed: (dir) => atleta.delete(),
      confirmDismiss: confirmDismiss,
    );
  }
}
