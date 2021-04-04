import 'package:atletica/global_widgets/custom_expansion_tile.dart';
import 'package:atletica/global_widgets/leading_info_widget.dart';
import 'package:atletica/main.dart';
import 'package:atletica/persistence/auth.dart';
import 'package:atletica/results/pbs/pb.dart';
import 'package:atletica/results/pbs/simple_result_widget.dart';
import 'package:atletica/results/pbs/tag.dart';
import 'package:atletica/results/result.dart';
import 'package:atletica/ripetuta/template.dart';
import 'package:flutter/material.dart';

final Map<TagsEvaluator, String> filters =
    Map.fromIterable(tags, key: (tag) => tag, value: (_) => null);

class PbsPageRoute extends StatelessWidget {
  final Iterable<Result> res;
  PbsPageRoute({this.res, final bool clear = false}) {
    if (clear) filters.updateAll((key, value) => null);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text('PERSONAL BEST')),
        body: PbsWidget(res: res),
      );
}

class PbsWidget extends StatefulWidget {
  final Map<String, Pb> results = {};
  final List<String> _sorted = [];

  PbsWidget({Iterable<Result> res, final bool clear = false}) {
    if (clear) filters.updateAll((key, value) => null);
    res ??= userA.results.values;
    res.forEach((r) {
      int i = 0;
      r.asIterable.forEach((sr) => (results[sr.key.name] ??= Pb())
          .put(result: r, index: i++, value: sr.value));
    });
    results.removeWhere((key, value) => value.isEmpty);
    _sorted.addAll(results.keys);
    _sorted.sort((k1, k2) => -results[k1].count.compareTo(results[k2].count));
  }

  @override
  _PbsPageRouteState createState() => _PbsPageRouteState();
}

class _PbsPageRouteState extends State<PbsWidget> {
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color fg = theme.scaffoldBackgroundColor;
    final Color bg = theme.primaryColor;
    return ListView(
      children: widget._sorted
          .map(
            (name) {
              final Pb pb = widget.results[name];
              final List<SimpleResultWidget> children = pb.results
                  .where((r) => r.acceptable)
                  .map((r) => SimpleResultWidget(
                        r: r,
                        bg: fg,
                        defaultColor: theme.primaryColorDark,
                        onTap: (tag, evaluator) =>
                            setState(() => filters[evaluator] = tag),
                      ))
                  .toList();
              if (children.isEmpty) return null;
              return CustomExpansionTile(
                title: name,
                childrenBackgroundColor: bg,
                childrenPadding: const EdgeInsets.only(
                  left: 8,
                  right: 8,
                  bottom: 8,
                ),
                children: children,
                leading: LeadingInfoWidget(
                  info: '${children.length}/${pb.realCount}',
                  bottom: singularPlural(
                    '    ripetut',
                    'a    ',
                    'e    ',
                    pb.count,
                  ), // TODO: this is shit
                ),
                trailing: LeadingInfoWidget(
                  info: Tipologia.corsaDist.targetFormatter(children[0].r.r),
                  //bottom: singularPlural('ripetut', 'a', 'e', e.value.count),
                ),
              );
            },
          )
          .where((w) => w != null)
          .toList(),
    );
  }
}
