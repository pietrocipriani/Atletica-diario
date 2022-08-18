import 'package:atletica/refactoring/model/target.dart';
import 'package:atletica/refactoring/model/tipologia.dart';
import 'package:atletica/refactoring/utils/iterable.dart';
import 'package:flutter/cupertino.dart';

class TargetView extends StatelessWidget {
  final Target target;
  final Tipologia tipologia;

  TargetView({required this.target, required this.tipologia, super.key});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: TextStyle(fontWeight: FontWeight.bold, inherit: true),
        children: TargetCategory.values
            .map((e) => TextSpan(
                  text: tipologia.formatTarget(target[e]),
                  style: TextStyle(inherit: true, color: e.color),
                ))
            .separate(() => const TextSpan(text: ' / '))
            .toList(),
      ),
    );
  }
}
