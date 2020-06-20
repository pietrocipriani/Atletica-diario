import 'package:flutter/material.dart';

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
