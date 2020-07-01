import 'dart:math';

import 'package:flutter/material.dart';

class SvgRenderer extends StatelessWidget {
  final Widget child;
  final Path path;
  final Size referredTo;
  final Size size;
  final Color color;
  final double strokeWidth;
  final PaintingStyle style;

  SvgRenderer({
    this.child,
    @required this.path,
    @required this.referredTo,
    this.size = Size.zero,
    this.color = Colors.black,
    this.strokeWidth = 1,
    this.style = PaintingStyle.stroke,
  });

  @override
  Widget build(BuildContext context) => CustomPaint(
        child: child,
        painter: _SvgPainter(
          path: path,
          referredTo: referredTo,
          color: color,
          strokeWidth: strokeWidth,
          style: style,
        ),
        size: size,
      );
}

class _SvgPainter extends CustomPainter {
  final Path path;
  final Paint p = Paint();

  Size referredTo;
  _SvgPainter({
    @required this.path,
    @required this.referredTo,
    Color color = Colors.black,
    double strokeWidth = 1,
    PaintingStyle style = PaintingStyle.stroke,
  }) {
    p.color = color;
    p.strokeWidth = strokeWidth;
    p.style = style;
  }

  @override
  void paint(Canvas canvas, Size size) {
    print ('painting...');
    double crop = min(
      size.width / referredTo.width,
      size.height / referredTo.height,
    );
    final Matrix4 _transform = Matrix4.identity();
    _transform.scale(crop);
    referredTo *= crop;
    final Offset traslation = (size / 2 - referredTo / 2);
    canvas.translate(traslation.dx, traslation.dy);
    canvas.drawPath(path.transform(_transform.storage), p);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
