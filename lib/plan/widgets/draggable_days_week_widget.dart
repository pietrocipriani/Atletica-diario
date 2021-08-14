import 'package:atletica/plan/week.dart';
import 'package:atletica/training/training.dart';
import 'package:atletica/training/training_chip.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';

class DraggableDaysWeekWidget extends StatefulWidget {
  final Week week;
  DraggableDaysWeekWidget(this.week);

  @override
  _DraggableDaysWeekWidgetState createState() =>
      _DraggableDaysWeekWidgetState();
}

class _DraggableDaysWeekWidgetState extends State<DraggableDaysWeekWidget> {
  Widget _builder(final int weekday, final bool over) {
    final Training? t = Training.tryOf(widget.week.trainings[weekday]);
    if (t != null)
      return TrainingChip(
        training: t,
        onDelete: () => setState(() => widget.week.trainings[weekday] = null),
      );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: DottedBorder(
        borderType: BorderType.RRect,
        padding: const EdgeInsets.all(0),
        color: over
            ? Theme.of(context).primaryColorDark
            : Theme.of(context).disabledColor,
        radius: Radius.circular(20),
        dashPattern: [6, 4],
        child: Container(
          height: 32,
        ),
      ),
    );
  }

  Widget _dayDraggable(final int weekday) => Expanded(
        flex: 2,
        child: DragTarget<Training>(
          builder: (BuildContext context, List<Training?> candidateData,
                  List<dynamic> rejectedData) =>
              _builder((weekday + 1) % 7, candidateData.isNotEmpty),
          onAccept: (allenamento) => setState(
            () => widget.week.trainings[(weekday + 1) % weekdays.length] =
                allenamento.reference,
          ),
        ),
      );

  Widget _dayTitle(final int weekday, final TextStyle overline) => Expanded(
        flex: 2,
        child: Text(
          weekdays[(weekday + 1) % weekdays.length],
          style: overline,
          textAlign: TextAlign.center,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final TextStyle overline = Theme.of(context).textTheme.overline!;
    return Column(
      children: [
        Row(children: [_dayTitle(0, overline), _dayTitle(1, overline)]),
        Row(children: [_dayDraggable(0), _dayDraggable(1)]),
        Row(children: [_dayTitle(2, overline), _dayTitle(3, overline)]),
        Row(children: [_dayDraggable(2), _dayDraggable(3)]),
        Row(children: [_dayTitle(4, overline), _dayTitle(5, overline)]),
        Row(children: [_dayDraggable(4), _dayDraggable(5)]),
        Row(children: [
          Flexible(flex: 1, child: Container()),
          _dayTitle(6, overline),
          Flexible(flex: 1, child: Container()),
        ]),
        Row(children: [
          Flexible(flex: 1, child: Container()),
          _dayDraggable(6),
          Flexible(flex: 1, child: Container()),
        ]),
      ],
    );
  }
}
