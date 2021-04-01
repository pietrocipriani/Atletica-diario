import 'package:Atletica/global_widgets/custom_list_tile.dart';
import 'package:Atletica/global_widgets/leading_info_widget.dart';
import 'package:Atletica/results/pbs/pb.dart';
import 'package:Atletica/results/pbs/tag.dart';
import 'package:Atletica/ripetuta/template.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SimpleResultWidget extends StatelessWidget {
  final void Function(String tag, TagsEvaluator evaluator) onTap;
  final Color bg;
  final SimpleResult r;
  SimpleResultWidget({@required this.r, this.bg, this.onTap});

  @override
  Widget build(BuildContext context) {
    return CustomListTile(
      key: ValueKey(r),
      title: Text(DateFormat.yMMMMd('it').format(r.date.dateTime)),
      tileColor: bg,
      trailing: LeadingInfoWidget(
        info: Tipologia.corsaDist.targetFormatter(r.r),
      ),
      subtitle: Tags(r, onTap: onTap),
    );
  }
}
