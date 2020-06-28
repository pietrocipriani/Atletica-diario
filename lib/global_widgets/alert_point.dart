import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class AlertPoint extends StatefulWidget {
  @override
  _AlertPointState createState() => _AlertPointState();
}

class _AlertPointState extends State<StatefulWidget>
    with SingleTickerProviderStateMixin {
  AnimationController _controller;

  @override
  void initState() {
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _controller.repeat();
    super.initState();
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Stack(
            children: <Widget>[
              Transform.scale(
                scale: _controller.value*2,
                child: child,
              ),
              Transform.scale(
                scale: (1 - _controller.value)*2,
                child: child,
              ),
            ],
          ),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColorDark.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
        ),
      );
}

class TimerRunningIcon extends StatefulWidget {

  @override
  _TimerRunningIconState createState () => _TimerRunningIconState();
}

class _TimerRunningIconState extends State<TimerRunningIcon> with SingleTickerProviderStateMixin {
  
  AnimationController _controller;
  Animation<double> _angleAnim;

  @override
  void initState () {
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _angleAnim = CurvedAnimation(parent: _controller, curve: Curves.slowMiddle);
    _angleAnim = Tween<double>(begin: 0, end: 4*pi).animate(_angleAnim);

    _controller.repeat();
    super.initState();
  }

  @override
  void dispose () {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(32, 32),
          painter: _TimerPainter(angle: _angleAnim.value),
        );
      }
    );
  }

}

class _TimerPainter extends CustomPainter {
  final double angle;
  final Paint p = Paint();

  _TimerPainter ({@required this.angle}) {
    p.strokeWidth = 2;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(const Offset(0,0));
    final double radius = size.shortestSide/2;

    final double startAngle = angle < 2*pi ? 0 : angle % (2*pi);
    final double sweepAngle = angle < 2*pi ? angle : 2*pi - startAngle;

    p.style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, p);
    p.style = PaintingStyle.fill;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius-4), startAngle - pi/2, sweepAngle, true, p);
  }

  @override
  bool shouldRepaint(_TimerPainter oldDelegate) {
    return angle != oldDelegate.angle;
  }


}
