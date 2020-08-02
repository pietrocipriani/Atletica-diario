import 'package:flutter/material.dart';

class LeadingInfoWidget extends StatelessWidget {
  final String bottom;
  final String info;

  LeadingInfoWidget({this.bottom, @required this.info}) : assert(info != null);

  @override
  Widget build(BuildContext context) {
    final Widget infoWidget = Text(
      info,
      style: Theme.of(context).textTheme.headline5,
    );

    if (bottom == null) return infoWidget;

    return Column(
      children: <Widget>[
        infoWidget,
        Text(
          bottom,
          style: Theme.of(context)
              .textTheme
              .overline
              .copyWith(fontWeight: FontWeight.normal),
        )
      ],
    );
  }
}