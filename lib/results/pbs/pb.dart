import 'package:atletica/date.dart';
import 'package:atletica/refactoring/common/common.dart';
import 'package:atletica/results/pbs/pbs_page_route.dart';
import 'package:atletica/results/result.dart';

class Pb {
  final List<SimpleResult> results = [];

  int get count => results.length;
  ResultValue? get best => results.first.r;
  bool get isEmpty => results.isEmpty;
  int realCount = 0;

  void put(
      {required final Result result,
      required final int index,
      required final ResultValue? value}) {
    realCount++;
    if (value == null) return;

    final int i = results.lastIndexWhere((r) => r.r! < value) + 1;
    // TODO: per Tipologia.corsaTime che accetta sia Duration che Distance è necessario
    // fare la comparazione attraverso il tempo della ripetuta (convertire passo in distanza o viceversa)
    results.insert(i, SimpleResult(result: result, index: index));
  }
}

class SimpleResult {
  final Result _result;
  final ResultValue? r;

  SimpleResult({required final Result result, required final int index})
      : _result = result,
        r = result.resultAt(index);

  bool get isMeet => _result.results.length == 1;
  String get training => _result.training;
  Date get date => _result.date;
  bool get stagional => (Date.now() - _result.date as Duration).inDays <= 365;

  bool get acceptable => filters.entries
      .every((e) => e.value == null || e.key.evaluate(this) == e.value);
}
