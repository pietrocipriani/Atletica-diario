import 'package:atletica/athlete/athlete.dart';
import 'package:atletica/athlete/results/results_route.dart';
import 'package:atletica/global_widgets/custom_dismissible.dart';
import 'package:atletica/global_widgets/custom_list_tile.dart';
import 'package:atletica/global_widgets/delete_confirm_dialog.dart';
import 'package:atletica/global_widgets/leading_info_widget.dart';
import 'package:atletica/refactoring/utils/singular_plural.dart';
import 'package:flutter/material.dart';

class AthleteWidget extends StatelessWidget {
  final Athlete atleta;
  final TextStyle overlineBoldPrimaryDark;
  final void Function()? onModified;

  AthleteWidget({
    Key? key,
    required this.atleta,
    required this.overlineBoldPrimaryDark,
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
      title: Text(atleta.name),
      subtitle: Text(atleta.group!, style: overlineBoldPrimaryDark),
      trailing: LeadingInfoWidget(
        info: '${atleta.trainingsCount}',
        bottom: singPlurIT('allenamento', atleta.trainingsCount),
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
