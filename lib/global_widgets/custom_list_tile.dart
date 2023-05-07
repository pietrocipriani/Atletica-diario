import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomListTile extends StatelessWidget {
  const CustomListTile({
    Key? key,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.isThreeLine = false,
    this.dense,
    this.enabled = true,
    this.onTap,
    this.onLongPress,
    this.tileColor,
  }) : super(key: key);

  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final bool isThreeLine;
  final bool enabled;
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
                style: Get.textTheme.labelSmall!,
              ),
        trailing: trailing,
        isThreeLine: isThreeLine,
        dense: dense,
        onTap: onTap,
        onLongPress: onLongPress,
      );
}
