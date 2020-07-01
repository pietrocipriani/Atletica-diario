import 'package:Atletica/global_widgets/link_line/link_line.dart';
import 'package:flutter/material.dart';

class ResultLinkLineWidget extends StatelessWidget {
  final Result result;
  final void Function(Result) onTap, onLongPress;
  final String Function(double target) targetFormatter;
  final bool isSpecial;
  final dynamic selected;

  ResultLinkLineWidget({
    @required this.result,
    @required this.selected,
    @required this.onTap,
    @required this.onLongPress,
    @required this.targetFormatter,
    this.isSpecial = false,
  }) : super(key: result.key);

  @override
  Widget build(BuildContext context) {
    return Draggable(
      dragAnchor: DragAnchor.pointer,
      feedbackOffset: const Offset(-9, -9),
      feedback: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Theme.of(context).primaryColor)),
        child: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ),
      child: GestureDetector(
        onTap: () => onTap(result),
        onLongPress: () => onLongPress(result),
        child: Chip(
          label: Text(
            result.result.isNaN ? 'N.P.' : targetFormatter(result.result),
            style: Theme.of(context).textTheme.overline.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isSpecial ? Colors.red : null,
                ),
          ),
          backgroundColor: Theme.of(context).dialogBackgroundColor,
          shape: StadiumBorder(
            side: BorderSide(
              color: selected != result
                  ? Colors.grey[300]
                  : Theme.of(context).primaryColor,
            ),
          ),
        ),
      ),
    );
  }
}
