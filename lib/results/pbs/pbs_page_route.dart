import 'package:atletica/global_widgets/custom_expansion_tile.dart';
import 'package:atletica/global_widgets/leading_info_widget.dart';
import 'package:atletica/main.dart';
import 'package:atletica/refactoring/model/tipologia.dart';
import 'package:atletica/results/pbs/pb.dart';
import 'package:atletica/results/pbs/simple_result_widget.dart';
import 'package:atletica/results/pbs/tag.dart';
import 'package:atletica/results/result.dart';
import 'package:flutter/material.dart';

final Map<TagsEvaluator, String?> filters = Map.fromIterable(tags, key: (tag) => tag, value: (_) => null);

class PbsPageRoute extends StatelessWidget {
  final Iterable<Result>? res;
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

  PbsWidget({Iterable<Result>? res, final bool clear = false}) {
    if (clear) filters.updateAll((key, value) => null);
    (res ??= Result.cachedResults).forEach((r) {
      int i = 0;
      r.asIterable.forEach((sr) => (results[sr.key.name] ??= Pb()).put(result: r, index: i++, value: sr.value));
    });
    results.removeWhere((key, value) => value.isEmpty);
    _sorted.addAll(results.keys);
    _sorted.sort((k1, k2) => -results[k1]!.count.compareTo(results[k2]!.count));
  }

  @override
  _PbsWidgetState createState() => _PbsWidgetState();
}

class _PbsWidgetState extends State<PbsWidget> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: widget._sorted.length,
      itemBuilder: (c, i) {
        final String name = widget._sorted[i];
        final Pb pb = widget.results[name]!;
        if (pb.isEmpty) return Container();
        return _PbWidget(
          name: name,
          pb: pb,
          onFilter: (t, e) => setState(() => filters[e] = t),
        );
      },
    );
  }
}

class _PbWidget extends StatelessWidget {
  final String name;
  final Pb pb;
  final void Function(String? filter, TagsEvaluator)? onFilter;
  _PbWidget({required this.name, required this.pb, this.onFilter});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final List<SimpleResult> results = pb.results.where((r) => r.acceptable).toList();

    if (results.isEmpty) return Container();

    String count = '${results.length}/${pb.realCount}';
    if (count.length > 6) count = '${results.length}';

    final List<SimpleResultWidget> children = results
        .map((r) => SimpleResultWidget(
              r: r,
              defaultColor: theme.primaryColorDark,
              onTap: onFilter,
            ))
        .toList();

    return CustomExpansionTile(
      title: name,
      children: children,
      leading: SizedBox(
        width: 80,
        child: LeadingInfoWidget(
          info: count,
          bottom: singularPlural('ripetut', 'a', 'e', pb.count),
        ),
      ),
      trailing: LeadingInfoWidget(
        info: Tipologia.corsaDist.formatTarget(results[0].r),
      ),
    );
  }
}
