import 'dart:math';

import 'package:flutter/material.dart';

class DurationPicker extends StatefulWidget {
  final Duration initialDuration;
  final void Function(Duration d) onDurationChanged;

  DurationPicker(final int duration, this.onDurationChanged)
      : initialDuration = Duration(seconds: duration);

  @override
  _DurationPickerState createState() => _DurationPickerState();
}

class _DurationPickerState extends State<DurationPicker>
    with SingleTickerProviderStateMixin {
  static const kROUND_TIME = 12 * 2;
  static const kMAX_ROUNDS = 5;
  int duration; // 1 equals to 30 seconds
  bool selected = false;
  GlobalKey detectorKey = GlobalKey();
  Offset center;

  int completeRounds = 0;

  @override
  void initState() {
    duration = (widget.initialDuration.inSeconds / 30).round();
    super.initState();
  }

  void _onFinishChange() {
    setState(() => selected = false);
    widget.onDurationChanged?.call(Duration(seconds: duration * 30));
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.hardEdge,
        children: <Widget>[
          Container(
            width: 200,
            height: 200,
            alignment: Alignment.center,
            child: Text(
              '${(duration ~/ 2).toString().padLeft(2, '0')}:${((duration % 2) * 30).round().toString().padLeft(2, '0')}',
              style: Theme.of(context).textTheme.headline2,
            ),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).primaryColorLight,
                width: 4,
              ),
            ),
          ),
          Container(
            width: 200.0 - 40.0,
            height: 200.0 - 40.0,
            child: CircularProgressIndicator(
              value: duration / kROUND_TIME / kMAX_ROUNDS,
              strokeWidth: 10,
            ),
          ),
          CustomPaint(
            painter: TimerPainter(roundsColors: Theme.of(context).primaryColor),
          ),
          Transform.rotate(
            angle: 2 * pi * duration / kROUND_TIME,
            child: Transform.translate(
              offset: Offset(0, -100.0 + 2.0),
              child: Container(
                width: selected ? 40 : 20,
                height: selected ? 40 : 20,
                decoration: BoxDecoration(
                  color: selected
                      ? Theme.of(context).primaryColorDark
                      : Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          GestureDetector(
            key: detectorKey,
            onPanDown: (details) {
              center ??=
                  (detectorKey.currentContext.findRenderObject() as RenderBox)
                      .size
                      .center(Offset(0, 0));
              Offset relativeToCenter = details.localPosition - center;
              Offset handle = Offset.fromDirection(
                  2 * pi * duration / kROUND_TIME - pi / 2, 100);

              if ((relativeToCenter - handle).distance < 20)
                setState(() {
                  selected = true;
                });
            },
            onTapUp: (details) {
              if (((details.localPosition - center).distance - 100).abs() >
                  10) {
                _onFinishChange();
                return;
              }
              double angle =
                  (details.localPosition - center).direction + pi / 2;
              angle %= 2 * pi;
              int newDuration = (angle * kROUND_TIME / (2 * pi)).round();
              newDuration += duration ~/ kROUND_TIME * kROUND_TIME;
              duration = newDuration;
              _onFinishChange();
            },
            onPanEnd: (details) => _onFinishChange(),
            onLongPressEnd: (details) => _onFinishChange(),
            onPanUpdate: (details) {
              if (!selected) return;
              double currentAngle =
                  (details.localPosition - center).direction + pi / 2;
              int newDuration = (currentAngle * kROUND_TIME / (pi * 2)).round();
              newDuration += duration ~/ kROUND_TIME * kROUND_TIME;
              int delta1 = newDuration - duration;
              int delta2 = delta1 - kROUND_TIME * delta1.sign;
              if (delta2.abs() < delta1.abs()) newDuration += kROUND_TIME;
              newDuration = max(newDuration, 0);
              newDuration = min(newDuration, kMAX_ROUNDS * kROUND_TIME);

              if ((newDuration - duration).abs() > 2) return;

              setState(() => duration = newDuration);
            },
          ),
        ],
      ),
    );
  }
}

class TimerPainter extends CustomPainter {
  final Color roundsColors, stepsColor;
  final Paint p = new Paint();

  TimerPainter({@required this.roundsColors, this.stepsColor = Colors.black}) {
    p.style = PaintingStyle.stroke;
    p.strokeWidth = 1;
  }

  @override
  void paint(Canvas canvas, Size size) {
    Offset center = size.center(Offset(0, 0));
    p.color = stepsColor;
    for (int i = 0; i < _DurationPickerState.kROUND_TIME; i++) {
      double angle = i * 2 * pi / _DurationPickerState.kROUND_TIME - pi / 2;
      Offset start = Offset.fromDirection(angle, 100.0 - 4.0);
      Offset end = Offset.fromDirection(angle, 100.0 - 13.0 + (i % 2) * 5);
      canvas.drawLine(start + center, end + center, p);
    }
    p.color = roundsColors;
    for (int i = 0; i < _DurationPickerState.kMAX_ROUNDS; i++) {
      double angle = i * 2 * pi / _DurationPickerState.kMAX_ROUNDS - pi / 2;
      Offset start = Offset.fromDirection(angle, 100.0 - 15.0);
      Offset end = Offset.fromDirection(angle, 100.0 - 25.0);
      canvas.drawLine(start + center, end + center, p);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
