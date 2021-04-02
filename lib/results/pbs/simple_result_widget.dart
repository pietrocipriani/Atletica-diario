import 'package:atletica/global_widgets/custom_list_tile.dart';
import 'package:atletica/global_widgets/leading_info_widget.dart';
import 'package:atletica/results/pbs/pb.dart';
import 'package:atletica/results/pbs/tag.dart';
import 'package:atletica/ripetuta/template.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SimpleResultWidget extends StatelessWidget {
  final void Function(String tag, TagsEvaluator evaluator) onTap;
  final Color bg, defaultColor;
  final SimpleResult r;
  SimpleResultWidget({
    @required this.r,
    @required this.defaultColor,
    this.bg,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CustomListTile(
      key: ValueKey(r),
      title: Text(DateFormat.yMMMMd('it').format(r.date.dateTime)),
      tileColor: bg,
      trailing: LeadingInfoWidget(
        info: Tipologia.corsaDist.targetFormatter(r.r),
      ),
      subtitle: Tags(r, defaultColor, onTap: onTap),
    );
  }
}
