import 'package:Atletica/global_widgets/custom_dismissible.dart';
import 'package:Atletica/global_widgets/custom_expansion_tile.dart';
import 'package:Atletica/global_widgets/delete_confirm_dialog.dart';
import 'package:Atletica/plan/tabella.dart';
import 'package:Atletica/plan/week.dart';
import 'package:Atletica/training/allenamento.dart';
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
  Widget build(BuildContext context) => CustomDismissible(
        key: ValueKey(widget.week),
        direction: DismissDirection.startToEnd,
        confirmDismiss: (direction) async {
          return await showDeleteConfirmDialog(
            context: context,
            name: 'settimana #${widget.plan.weeks.indexOf(widget.week) + 1}',
          );
        },
        onDismissed: (direction) {
          setState(() => widget.plan.weeks.remove(widget.week));
          widget.plan.update();
        },
        child: CustomExpansionTile(
          title: 'settimana #${widget.plan.weeks.indexOf(widget.week) + 1}',
          subtitle: Text(
            widget.week.toString(),
            overflow: TextOverflow.ellipsis,
            maxLines: 3,
            style: Theme.of(context).textTheme.overline.copyWith(
                  color: Theme.of(context).primaryColorDark,
                ),
          ),
          children: () sync* {
            for (int i = 0; i < weekdays.length; i++)
              yield Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        weekdays[(i + 1) % 7],
                        style: Theme.of(context)
                            .textTheme
                            .overline
                            .copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(
                      allenamenti(widget.week.trainings[(i + 1) % 7])?.name ??
                          'riposo',
                      style: Theme.of(context).textTheme.overline.copyWith(
                            fontWeight: FontWeight.bold,
                            color: widget.week.trainings[(i + 1) % 7] == null
                                ? Colors.grey[300]
                                : Theme.of(context).primaryColorDark,
                          ),
                    ),
                  ],
                ),
              );
          }()
              .toList(),
          trailing: IconButton(
            icon: Icon(Icons.content_copy),
            onPressed: () {
              widget.plan.weeks.insert(
                widget.plan.weeks.indexOf(widget.week),
                Week.copy(widget.week),
              );
              widget.plan.update();
            },
          ),
          leading: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              GestureDetector(
                child: Icon(Icons.expand_less,
                    color: widget.plan.weeks.first == widget.week
                        ? Colors.grey[300]
                        : Theme.of(context).primaryColorDark),
                onTap: widget.plan.weeks.first == widget.week
                    ? null
                    : () {
                        int index = widget.plan.weeks.indexOf(widget.week);
                        setState(() {
                          widget.plan.weeks.insert(
                              index - 1, widget.plan.weeks.removeAt(index));
                        });
                        widget.plan.update();
                      },
              ),
              GestureDetector(
                child: Icon(Icons.expand_more,
                    color: widget.plan.weeks.last == widget.week
                        ? Colors.grey[300]
                        : Theme.of(context).primaryColorDark),
                onTap: widget.plan.weeks.last == widget.week
                    ? null
                    : () {
                        int index = widget.plan.weeks.indexOf(widget.week);
                        setState(() {
                          widget.plan.weeks.insert(
                              index - 1, widget.plan.weeks.removeAt(index));
                        });
                        widget.plan.update();
                      },
              ),
            ],
          ),
        ),
      );
}
