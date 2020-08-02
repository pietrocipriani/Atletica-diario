import 'package:Atletica/athlete/atleta.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';

class AtletaLinkLineWidget extends StatelessWidget {
  final Athlete atleta;
  final dynamic selected;
  final void Function(Athlete) onTap, onLongPress;
  final void Function(GlobalKey data) onAccept;

  AtletaLinkLineWidget({
    @required Key key,
    @required this.atleta,
    @required this.selected,
    @required this.onTap,
    @required this.onLongPress,
    @required this.onAccept,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DragTarget<GlobalKey>(
      builder: (BuildContext context, List<dynamic> candidateData,
          List<dynamic> rejectedData) {
        return GestureDetector(
          onTap: () => onTap(atleta),
          onLongPress: () => onLongPress(atleta),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: DottedBorder(
              child: Text(atleta.name),
              padding: const EdgeInsets.all(8),
              radius: Radius.circular(20),
              borderType: BorderType.RRect,
              strokeWidth: selected != atleta ? 1 : 2,
              color: candidateData.isEmpty && selected != atleta
                  ? Colors.grey[300]
                  : Theme.of(context).primaryColor,
              dashPattern: [6, 4],
            ),
          ),
        );
      },
      onAccept: onAccept,
    );
  }
}
