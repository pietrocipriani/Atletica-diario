import 'package:flutter/material.dart';

class CustomListTile extends StatelessWidget {
  CustomListTile({
    Key? key,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.isThreeLine = false,
    this.dense,
    this.onTap,
    this.onLongPress,
    this.tileColor,
  }) : super(key: key);

  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final bool isThreeLine;
  final bool? dense;
  final GestureTapCallback? onTap;
  final GestureLongPressCallback? onLongPress;
  final Color? tileColor;

  @override
  Widget build(BuildContext context) => ListTile(
        leading: leading,
        tileColor: tileColor ?? Colors.transparent,
        title: title == null
            ? Container()
            : DefaultTextStyle(
                child: title!,
                style: Theme.of(context).textTheme.subtitle1!,
              ),
        subtitle: subtitle == null
            ? null
            : DefaultTextStyle(
                child: subtitle!,
                style: Theme.of(context).textTheme.overline!,
              ),
        trailing: trailing,
        isThreeLine: isThreeLine,
        dense: dense,
        onTap: onTap,
        onLongPress: onLongPress,
      );
}
