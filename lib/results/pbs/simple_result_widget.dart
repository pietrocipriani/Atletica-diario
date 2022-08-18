import 'package:atletica/global_widgets/custom_list_tile.dart';
import 'package:atletica/global_widgets/leading_info_widget.dart';
import 'package:atletica/refactoring/model/tipologia.dart';
import 'package:atletica/results/pbs/pb.dart';
import 'package:atletica/results/pbs/tag.dart';
import 'package:flutter/material.dart';

class SimpleResultWidget extends StatelessWidget {
  final void Function(String? tag, TagsEvaluator evaluator)? onTap;
  final Color? bg;
  final Color defaultColor;
  final SimpleResult r;
  SimpleResultWidget({
    required this.r,
    required this.defaultColor,
    this.bg,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CustomListTile(
      key: ValueKey(r),
      title: Text(r.date.day.toString().padLeft(2, '0') + '/' + r.date.month.toString().padLeft(2, '0') + "/'" + (r.date.year % 100).toString().padLeft(2, '0')), // TODO: format with locations
      tileColor: bg,
      dense: true,
      trailing: LeadingInfoWidget(
        info: Tipologia.corsaDist.formatTarget(r.r),
      ),
      subtitle: Tags(r, defaultColor, onTap: onTap),
    );
  }
}
