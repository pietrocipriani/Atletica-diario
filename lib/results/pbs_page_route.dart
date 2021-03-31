import 'package:Atletica/global_widgets/custom_list_tile.dart';
import 'package:Atletica/global_widgets/leading_info_widget.dart';
import 'package:Atletica/main.dart';
import 'package:Atletica/persistence/auth.dart';
import 'package:Atletica/ripetuta/template.dart';
import 'package:flutter/material.dart';

class PbsPageRoute extends StatelessWidget {
  final Map<String, _Pb> results = {};

  PbsPageRoute() {
    userA.results.values
        .expand((v) => v.asIterable)
        .forEach((sr) => (results[sr.key.name] ??= _Pb()).put(sr.value));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text('PERSONAL BEST')),
        body: ListView(
          children: results.entries
              .where((e) => e.value.result != null)
              .map(
                (e) => CustomListTile(
                  title: Text(e.key),
                  leading: LeadingInfoWidget(
                    info: e.value.count.toString(),
                    bottom: singularPlural('ripetut', 'a', 'e', e.value.count),
                  ),
                  trailing: LeadingInfoWidget(
                    info: Tipologia.corsaDist.targetFormatter(e.value.result),
                    //bottom: singularPlural('ripetut', 'a', 'e', e.value.count),
                  ),
                ),
              )
              .toList(),
        ),
      );
}

class _Pb {
  double result;
  int count = 0;

  void put(final double result) {
    if (result == null) return;
    count++;
    if (this.result != null && result < this.result)
      this.result = result;
    else if (this.result == null) this.result = result;
  }
}
