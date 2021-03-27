import 'package:Atletica/global_widgets/custom_dismissible.dart';
import 'package:Atletica/global_widgets/custom_expansion_tile.dart';
import 'package:Atletica/global_widgets/delete_confirm_dialog.dart';
import 'package:Atletica/plan/tabella.dart';
import 'package:Atletica/plan/week.dart';
import 'package:Atletica/plan/widgets/week_widget.dart';
import 'package:flutter/material.dart';

class PlanWidget extends StatefulWidget {
  final Tabella plan;
  PlanWidget(this.plan);

  @override
  _PlanWidgetState createState() => _PlanWidgetState();
}

class _PlanWidgetState extends State<PlanWidget> {
  @override
  Widget build(BuildContext context) => CustomDismissible(
        key: ValueKey(widget.plan.reference),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.endToStart) {
            if (await widget.plan.modify(context: context)) setState(() {});
            return false;
          }
          return await showDeleteConfirmDialog(
            context: context,
            name: widget.plan.name,
          );
        },
        onDismissed: (direction) => widget.plan.delete(),
        child: CustomExpansionTile(
          subtitle: (widget.plan.athletes?.isEmpty ?? true)
              ? null
              : Text(
                  widget.plan.athletesAsList,
                  style: TextStyle(color: Theme.of(context).primaryColorDark),
                ),
          trailing: IconButton(
            icon: Icon(Icons.add_circle, color: Colors.black),
            onPressed: () async {
              final Week week = await Week.fromDialog(context);
              if (week != null) {
                widget.plan.weeks.add(week);
                widget.plan.update();
              }
            },
          ),
          leading: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                widget.plan.weeks.length.toString(),
                style: Theme.of(context).textTheme.headline5,
              ),
              Text(
                'settiman${widget.plan.weeks.length == 1 ? 'a' : 'e'}',
                style: Theme.of(context).textTheme.overline,
              ),
            ],
          ),
          title: widget.plan.name,
          children: widget.plan.weeks
              .map((week) => WeekWidget(widget.plan, week))
              .toList(),
        ),
      );
}
