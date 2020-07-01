import 'package:Atletica/athlete/atleta.dart';
import 'package:Atletica/global_widgets/link_line/athlete_link_line_widget.dart';
import 'package:Atletica/global_widgets/link_line/result_link_line_widget.dart';
import 'package:Atletica/ripetuta/ripetuta.dart';
import 'package:flutter/material.dart';

class Keys {
  final GlobalKey atleta;
  GlobalKey result;

  Keys() : this.atleta = GlobalKey();
}

class Result {
  double result;
  GlobalKey key = GlobalKey();
  Result(this.result);
}

class LinkLine extends StatefulWidget {
  final List<Result> results;
  final Ripetuta rip;
  final Map<Atleta, Keys> links;

  LinkLine(
      {@required List<double> results,
      @required this.rip,
      @required Iterable<Atleta> athletes})
      : links =
            Map.fromEntries(athletes.map((atleta) => MapEntry(atleta, Keys()))),
        this.results = results.map((result) => Result(result)).toList();

  @override
  _LinkLineState createState() => _LinkLineState();
}

class _LinkLineState extends State<LinkLine> {
  GlobalKey painter = GlobalKey();

  dynamic selected;

  bool get fullLinked =>
      widget.links.values.every((keys) => keys.result != null);

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
            children: widget.links.keys
                .map((atleta) => AtletaLinkLineWidget(
                      key: widget.links[atleta].atleta,
                      atleta: atleta,
                      selected: selected,
                      onTap: (a) {
                        if (selected == null || selected is Atleta)
                          selected = selected == a ? null : a;
                        else {
                          widget.links[a].result = selected.key;
                          selected = null;
                        }
                        setState(() {});
                      },
                      onLongPress: (a) {
                        widget.links[a].result = selected = null;
                        setState(() {});
                      },
                      onAccept: (data) {
                        widget.links[atleta].result = data;
                        setState(() {});
                      },
                    ))
                .toList(),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: widget.results
                .map(
                  (result) => ResultLinkLineWidget(
                    result: result,
                    selected: selected,
                    onTap: (r) {
                      if (selected == null || selected is Result)
                        selected = r == selected ? null : r;
                      else {
                        widget.links[selected].result = r.key;
                        selected = null;
                      }
                      setState(() {});
                    },
                    onLongPress: (r) {
                      if (fullLinked)
                        widget.links.forEach((a, keys) {
                          if (keys.result == result.key) keys.result = null;
                        });
                      else
                        widget.links
                            .forEach((a, keys) => keys.result ??= result.key);
                      setState(() {});
                    },
                    targetFormatter:
                        widget.rip.template.tipologia.targetFormatter,
                    isSpecial: result.result.isNaN ||
                        result == widget.results[widget.results.length - 2],
                  ),
                )
                .toList(),
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
      {@required this.paintRO,
      this.color = Colors.black,
      @required this.keys}) {
    p.color = color;
    p.strokeWidth = 2;
    p.strokeCap = StrokeCap.round;
    p.style = PaintingStyle.stroke;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (paintRO == null) return;
    for (Keys key in keys) {
      if (key.result == null) continue;

      dynamic atleta = key.atleta.currentContext
          .findRenderObject()
          .getTransformTo(paintRO)
          .getTranslation();
      atleta = Offset(atleta.x + key.atleta.currentContext.size.width + 4,
          atleta.y + key.atleta.currentContext.size.height / 2);
      dynamic result = key.result.currentContext
          .findRenderObject()
          .getTransformTo(paintRO)
          .getTranslation();
      result = Offset(
          result.x - 4, result.y + key.result.currentContext.size.height / 2);
      Offset q1 = Offset((atleta.dx + result.dx) / 2, atleta.dy);
      Offset q2 = Offset((atleta.dx + result.dx) / 2, result.dy);

      Path path = Path();
      path.moveTo(atleta.dx, atleta.dy);
      path.cubicTo(q1.dx, q1.dy, q2.dx, q2.dy, result.dx, result.dy);
      canvas.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
