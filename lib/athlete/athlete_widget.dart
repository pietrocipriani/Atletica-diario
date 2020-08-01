import 'package:AtleticaCoach/athlete/atleta.dart';
import 'package:AtleticaCoach/athlete/results/results_route.dart';
import 'package:AtleticaCoach/global_widgets/custom_dismissible.dart';
import 'package:AtleticaCoach/global_widgets/delete_confirm_dialog.dart';
import 'package:AtleticaCoach/main.dart';
import 'package:flutter/material.dart';

class AthleteWidget extends StatelessWidget {
  final Athlete atleta;
  final TextStyle subtitle1Bold, overlineBoldPrimaryDark;
  final void Function() onModified;

  AthleteWidget({
    Key key,
    @required this.atleta,
    @required this.subtitle1Bold,
    @required this.overlineBoldPrimaryDark,
    this.onModified,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (atleta.dismissed) return Container();

    final Widget child = ListTile(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResultsRouteList(atleta),
          )),
      title: Text(atleta.name, style: subtitle1Bold),
      subtitle: Text(atleta.group, style: overlineBoldPrimaryDark),
      trailing: Column(children: <Widget>[
        Text(
          '${atleta.trainingsCount}',
          style: Theme.of(context).textTheme.headline5,
        ),
        Text(
          singularPlural('allenament', 'o', 'i', atleta.trainingsCount),
          style: Theme.of(context).textTheme.overline,
        )
      ]),
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
