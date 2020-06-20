import 'package:Atletica/atleta.dart';
import 'package:Atletica/ripetuta.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';

class Keys {
  final GlobalKey atleta;
  GlobalKey result;

  Keys() : this.atleta = GlobalKey();
}

class Result {
  double result;
  GlobalKey key = GlobalKey();
  Result (this.result);
}

class LinkLine extends StatefulWidget {
  final List<Result> results;
  final Ripetuta rip;
  final Map<Atleta, Keys> links;

  LinkLine({@required List<double> results, @required this.rip})
      : links = Map.fromEntries(
            groups.first.atleti.map((atleta) => MapEntry(atleta, Keys()))),
        this.results = results.map((result) => Result(result)).toList();

  @override
  _LinkLineState createState() => _LinkLineState();
}

class _LinkLineState extends State<LinkLine> {
  GlobalKey painter = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      key: painter,
      foregroundPainter: LinksPainter(
          paintRO: painter.currentContext?.findRenderObject(),
          keys: widget.links.values.toList(),
          color: Theme.of(context).primaryColor),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: groups.first.atleti
                .map((atleta) => DragTarget<GlobalKey>(
                      builder: (BuildContext context,
                          List<dynamic> candidateData,
                          List<dynamic> rejectedData) {
                        return Padding(
                          key: widget.links[atleta].atleta,
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: DottedBorder(
                            child: Text(atleta.name),
                            padding: const EdgeInsets.all(8),
                            radius: Radius.circular(20),
                            borderType: BorderType.RRect,
                            color: candidateData.isEmpty
                                ? Colors.grey[300]
                                : Theme.of(context).primaryColor,
                            dashPattern: [6, 4],
                          ),
                        );
                      },
                      onAccept: (data) {
                        widget.links[atleta].result = data;
                        setState(() {});
                      }
                    ))
                .toList(),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: widget.results.map(
              (result) {
                return Draggable(
                  dragAnchor: DragAnchor.pointer,
                  data: result.key,
                  feedbackOffset: const Offset(-9, -9),
                  feedback: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: Theme.of(context).primaryColor)),
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  child: Chip(
                    key: result.key,
                    label: Text(
                      result.result.isNaN
                          ? 'N.P.'
                          : widget.rip.template.tipologia.targetFormatter(
                              result.result,
                            ),
                      style: Theme.of(context).textTheme.overline.copyWith(
                          fontWeight: FontWeight.bold,
                          color: result.result.isNaN ||
                                  result ==
                                      widget.results[widget.results.length - 2]
                              ? Colors.red
                              : null),
                    ),
                    backgroundColor: Theme.of(context).dialogBackgroundColor,
                    shape: StadiumBorder(
                        side:
                            BorderSide(color: Theme.of(context).primaryColor)),
                  ),
                );
              },
            ).toList(),
          ),
        ],
      ),
    );
  }
}

class LinksPainter extends CustomPainter {
  final RenderObject paintRO;
  final Color color;
  final List<Keys> keys;
  final Paint p = Paint();

  LinksPainter(
      {@required this.paintRO, this.color = Colors.black, @required this.keys}) {
        p.color = color;
        p.strokeWidth = 4;
        p.strokeCap = StrokeCap.round;
        p.style = PaintingStyle.stroke;
      }

  @override
  void paint(Canvas canvas, Size size) {
    if (paintRO == null) return;
    for (Keys key in keys) {
      if (key.result == null) continue;

      dynamic atleta = key.atleta.currentContext.findRenderObject().getTransformTo(paintRO).getTranslation();
      atleta = Offset(atleta.x + key.atleta.currentContext.size.width, atleta.y + key.atleta.currentContext.size.height/2);
      dynamic result = key.result.currentContext.findRenderObject().getTransformTo(paintRO).getTranslation();
      result = Offset(result.x, result.y + key.result.currentContext.size.height/2);
      Offset q1 = Offset((atleta.dx + result.dx)/2, atleta.dy);
      Offset q2 = Offset((atleta.dx + result.dx)/2, result.dy);

      Path path = Path();
      path.moveTo(atleta.dx, atleta.dy);
      path.cubicTo(q1.dx, q1.dy, q2.dx, q2.dy, result.dx, result.dy);
      canvas.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
