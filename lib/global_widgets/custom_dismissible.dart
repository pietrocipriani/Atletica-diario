import 'package:flutter/material.dart';

class CustomDismissible extends StatelessWidget {
  final Key key;
  final Widget child;
  final Color firstBackgroundColor, secondBackgroundColor;
  final IconData firstBackgroundIcon, secondBackgroundIcon;
  final Future<bool> Function(DismissDirection) confirmDismiss;
  final void Function(DismissDirection) onDismissed;
  final void Function() onResize;

  CustomDismissible({
    @required this.key,
    @required this.child,
    this.firstBackgroundColor,
    this.secondBackgroundColor,
    this.firstBackgroundIcon,
    this.secondBackgroundIcon,
    this.confirmDismiss,
    this.onDismissed,
    this.onResize,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: key,
      child: child,
      background: Container(
        color: firstBackgroundColor ?? Theme.of(context).primaryColorLight,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 16),
        child: Icon(firstBackgroundIcon ?? Icons.delete),
      ),
      secondaryBackground: Container(
        color: secondBackgroundColor ?? Colors.lightGreen[200],
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: Icon(secondBackgroundIcon ?? Icons.edit),
      ),
      confirmDismiss: confirmDismiss,
      onDismissed: onDismissed,
      onResize: onResize,
    );
  }
}
