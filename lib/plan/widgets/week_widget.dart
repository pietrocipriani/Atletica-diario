import 'package:atletica/global_widgets/custom_dismissible.dart';
import 'package:atletica/global_widgets/custom_expansion_tile.dart';
import 'package:atletica/global_widgets/delete_confirm_dialog.dart';
import 'package:atletica/plan/tabella.dart';
import 'package:atletica/plan/week.dart';
import 'package:atletica/training/allenamento.dart';
import 'package:flutter/material.dart';

class WeekWidget extends StatefulWidget {
  final Week week;
  final Tabella plan;
  WeekWidget(this.plan, this.week);

  @override
  _WeekWidgetState createState() => _WeekWidgetState();
}

class _WeekWidgetState extends State<WeekWidget> {
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return CustomDismissible(
      key: ValueKey(widget.week),
      direction: DismissDirection.startToEnd,
      confirmDismiss: (direction) async {
        return await showDeleteConfirmDialog(
          context: context,
          name: 'settimana #${widget.plan.weeks.indexOf(widget.week) + 1}',
        );
      },
      onDismissed: (direction) {
        widget.plan.update(
          weeks: widget.plan.weeks.where((w) => w != widget.week).toList(),
        );
      },
      child: CustomExpansionTile(
        title: 'settimana #${widget.plan.weeks.indexOf(widget.week) + 1}',
        subtitle: Text(
          widget.week.toString(),
          overflow: TextOverflow.ellipsis,
          maxLines: 3,
          style: TextStyle(color: theme.primaryColorDark),
        ),
        childrenPadding: const EdgeInsets.symmetric(horizontal: 40.0),
        children: () sync* {
          for (int i = 0; i < weekdays.length; i++)
            yield Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    weekdays[(i + DateTime.monday) % 7],
                    style: theme.textTheme.overline
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  allenamenti(widget.week.trainings[(i + 1) % 7])?.name ??
                      'riposo',
                  style: theme.textTheme.overline.copyWith(
                    fontWeight: FontWeight.bold,
                    color: widget.week.trainings[(i + 1) % 7] == null
                        ? theme.disabledColor
                        : theme.primaryColorDark,
                  ),
                ),
              ],
            );
        }()
            .toList(),
        trailing: IconButton(
          icon: Icon(Icons.content_copy),
          onPressed: () {
            final List<Week> newWeeks = List.from(widget.plan.weeks);
            newWeeks.insert(
              widget.plan.weeks.indexOf(widget.week),
              Week.copy(widget.week),
            );
            widget.plan.update(weeks: newWeeks);
          },
        ),
        leading: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            GestureDetector(
              child: Icon(Icons.expand_less,
                  color: widget.plan.weeks.first == widget.week
                      ? theme.disabledColor
                      : theme.primaryColorDark),
              onTap: widget.plan.weeks.first == widget.week
                  ? null
                  : () {
                      final List<Week> newWeeks = List.from(widget.plan.weeks);
                      final int index = newWeeks.indexOf(widget.week);
                      newWeeks.insert(index - 1, newWeeks.removeAt(index));
                      widget.plan.update(weeks: newWeeks);
                    },
            ),
            GestureDetector(
              child: Icon(Icons.expand_more,
                  color: widget.plan.weeks.last == widget.week
                      ? theme.disabledColor
                      : theme.primaryColorDark),
              onTap: widget.plan.weeks.last == widget.week
                  ? null
                  : () {
                      final List<Week> newWeeks = List.from(widget.plan.weeks);
                      final int index = newWeeks.indexOf(widget.week);
                      newWeeks.insert(index + 1, newWeeks.removeAt(index));
                      widget.plan.update(weeks: newWeeks);
                    },
            ),
          ],
        ),
      ),
    );
  }
}
