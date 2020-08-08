import 'package:Atletica/athlete/atleta.dart';
import 'package:Atletica/athlete/results/results_route.dart';
import 'package:Atletica/global_widgets/custom_dismissible.dart';
import 'package:Atletica/global_widgets/custom_list_tile.dart';
import 'package:Atletica/global_widgets/delete_confirm_dialog.dart';
import 'package:Atletica/global_widgets/leading_info_widget.dart';
import 'package:Atletica/main.dart';
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

    final Widget child = CustomListTile(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultsRouteList(atleta),
        ),
      ),
      title: Text(atleta.name, style: subtitle1Bold),
      subtitle: Text(atleta.group, style: overlineBoldPrimaryDark),
      trailing: LeadingInfoWidget(
        info: '${atleta.trainingsCount}',
        bottom: singularPlural('allenament', 'o', 'i', atleta.trainingsCount),
      ),
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
