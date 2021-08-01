import 'package:flutter/material.dart';

class AnimatedText extends StatefulWidget {
  final String text;
  final TextStyle? style;

  AnimatedText({required this.text, this.style});

  @override
  _AnimatedTextState createState() => _AnimatedTextState();
}

class _AnimatedTextState extends State<AnimatedText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: Duration(seconds: 1));
  late final Animation<double> _sizeAnimation =
      Tween<double>(begin: 0, end: 3).animate(_controller);

  @override
  void initState() {
    _controller.repeat(reverse: true);
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Text(
          widget.text + ('.' * _sizeAnimation.value.round()).padRight(3),
          style: widget.style,
        );
      },
    );
  }
}
