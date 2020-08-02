import 'dart:math';
import 'dart:ui';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:Atletica/running_training/running_training.dart' as rt;

class StopWatch extends StatefulWidget {
  final rt.TickerProvider ticker;

  StopWatch({@required this.ticker});

  @override
  _StopWatchState createState() => _StopWatchState();
}

class _StopWatchState extends State<StopWatch>
    with SingleTickerProviderStateMixin {
  Ticker ticker;
  AnimationController _controller;
  Animation<double> _lapAnimation;
  Duration freezedElapsed;

  @override
  void initState() {
    ticker = widget.ticker.createTicker(() => setState(() {}));
    _controller =
        AnimationController(vsync: this, duration: Duration(milliseconds: 300));
    _lapAnimation = Tween<double>(begin: 1, end: 2).animate(_controller);
    widget.ticker.lapCallBack = (elapsed) async {
      freezedElapsed = elapsed;
      if (_controller.isAnimating) _controller.reset();
      await _controller.forward();
      if (freezedElapsed == elapsed) {
        await _controller.reverse();
        freezedElapsed = null;
      }
    };
    super.initState();
  }

  @override
  void dispose() {
    widget.ticker.muted = true;
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Duration d = freezedElapsed ?? widget.ticker.elapsed;
    Widget time = Text(
      '${d.inMinutes}:${((d.inMilliseconds / 1000) % 60).toStringAsFixed(2).padLeft(5, '0')}',
      style: Theme.of(context).textTheme.headline4.copyWith(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
    );
    if (freezedElapsed != null)
      time = Transform.scale(scale: _lapAnimation.value, child: time);
    return AspectRatio(
      aspectRatio: 1,
      child: DottedBorder(
        borderType: BorderType.Circle,
        color: Colors.grey[300],
        padding: const EdgeInsets.all(0),
        dashPattern: [6, 4],
        child: CustomPaint(
          child: Center(
            child: time,
          ),
          willChange: true,
          painter: _SnakeCircle(
            color: Theme.of(context).primaryColor,
            angle: 2 * pi * widget.ticker.elapsed.inMilliseconds / (15000),
          ),
        ),
      ),
    );
  }
}

class _SnakeCircle extends CustomPainter {
  static const _DEFAULT_STROKE_WIDTH = 10;
  static const _DEFAULT_ANIMATION_PERIOD = pi / 15;
  final Color color;
  final double angle;
  final Paint p = Paint();

  _SnakeCircle({@required this.color, @required this.angle}) {
    p.strokeWidth = 10;
    p.style = PaintingStyle.stroke;
    p.strokeCap = StrokeCap.round;
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.translate(size.width / 2, size.height / 2);
    double backAngle = min(angle, pi / 8);
    canvas.rotate(-pi / 2 + angle - backAngle);

    final Rect rect = Rect.fromCenter(
        center: Offset(0, 0), width: size.width, height: size.height);

    p.strokeWidth = ((angle / _DEFAULT_ANIMATION_PERIOD) % 1 + 1) *
        _DEFAULT_STROKE_WIDTH /
        2;
    if ((angle ~/ _DEFAULT_ANIMATION_PERIOD) % 2 == 0)
      p.strokeWidth = _DEFAULT_STROKE_WIDTH * 3 / 2 - p.strokeWidth;

    p.shader = SweepGradient(
      center: Alignment.center,
      colors: [color.withOpacity(0), color],
      startAngle: backAngle - pi / 8,
      endAngle: backAngle,
      tileMode: TileMode.mirror,
    ).createShader(rect);
    canvas.drawArc(rect, backAngle, -backAngle, false, p);
  }

  @override
  bool shouldRepaint(_SnakeCircle oldDelegate) {
    return color != oldDelegate.color || angle != oldDelegate.angle;
  }
}
