import 'package:Atletica/date.dart';
import 'package:Atletica/results/pbs/pbs_page_route.dart';
import 'package:Atletica/results/result.dart';
import 'package:flutter/material.dart';

class Pb {
  final List<SimpleResult> results = [];

  int get count => results.length;
  double get best => results.first.r;
  bool get isEmpty => results.isEmpty;
  int realCount = 0;

  void put(
      {@required final Result result,
      @required final int index,
      @required final double value}) {
    realCount++;
    if (value == null) return;
    final int i = results.lastIndexWhere((r) => r.r < value) + 1;
    results.insert(i, SimpleResult(result: result, index: index));
  }
}

class SimpleResult {
  final Result _result;
  final double r;
  SimpleResult({@required final Result result, @required final int index})
      : _result = result,
        r = result.resultAt(index);

  bool get isMeet => _result.results.length == 1;
  String get training => _result.training;
  Date get date => _result.date;
  bool get stagional => (Date.now() - _result.date as Duration).inDays <= 365;

  bool get acceptable => filters.entries
      .every((e) => e.value == null || e.key.evaluate(this) == e.value);
}
