import 'dart:async';

import 'package:flutter/material.dart';

Future<T?> showDialogOverlay<T>({
  required final BuildContext context,
  final bool barrierDismissible = true,
  required final Widget Function(
          BuildContext context, Future<void> Function([T?]) pop)
      builder,
}) {
  final OverlayState? overlay = Overlay.of(context);
  if (overlay == null)
    throw FlutterError(
      'Overlay operation requested with a context that does not include an Overlay.',
    );
  OverlayEntry? entry;
  final Completer<T?> completer = Completer();
  final GlobalKey<_CustomDialogState> _dialogKey = GlobalKey();
  Future<void> Function([T?]) pop = ([t]) async {
    await _dialogKey.currentState?.pop();
    entry?.remove();
    completer.complete(t);
  };
  entry = OverlayEntry(
    builder: (context) => CustomDialog(
      key: _dialogKey,
      pop: pop,
      child: builder(context, pop),
      barrierDismissible: barrierDismissible,
    ),
  );
  overlay.insert(entry);
  return completer.future;
}

class CustomDialog<T> extends StatefulWidget {
  final Widget child;
  final bool barrierDismissible;
  final Future<void> Function([T?]) pop;

  CustomDialog({
    final Key? key,
    required this.child,
    this.barrierDismissible = true,
    required this.pop,
  }) : super(key: key);

  @override
  _CustomDialogState createState() => _CustomDialogState();
}

class _CustomDialogState extends State<CustomDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: kThemeAnimationDuration,
  );
  late final Animation<double> _animation =
      CurvedAnimation(parent: _controller, curve: Curves.fastOutSlowIn);

  @override
  void initState() {
    _controller.forward();
    super.initState();
  }

  TickerFuture pop() {
    return _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        print('catched');
        await widget.pop();
        return false;
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          Widget barrier = Container(
            color: Color.lerp(
              Colors.transparent,
              Colors.black54,
              _animation.value,
            ),
            child: Center(
              child: Transform.scale(scale: _animation.value, child: child),
            ),
          );
          // TODO: barrierDismissible
          return barrier;
        },
        child: widget.child,
      ),
    );
  }
}
