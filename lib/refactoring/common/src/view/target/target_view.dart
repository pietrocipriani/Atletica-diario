import 'package:atletica/refactoring/common/common.dart';
import 'package:atletica/refactoring/utils/iterable.dart';
import 'package:flutter/cupertino.dart';

/// [Widget] for showing a [Target] as /-separated formatted [ResultValue]s
class TargetView extends StatelessWidget {
  /// the [Target] to be displaied
  final Target target;

  /// the [Tipologia] to format the target
  final Tipologia tipologia;

  TargetView({required this.target, required this.tipologia, super.key});

  @override
  Widget build(BuildContext context) {
    return Text.rich(TargetViewSpan(target: target, tipologia: tipologia));
  }
}

/// Span to display in [TargetView]. It can also be displayed in a rich text widget as [TextSpan]
class TargetViewSpan extends TextSpan {
  TargetViewSpan({required final Target target, required final Tipologia tipologia})
      : super(
          style: TextStyle(fontWeight: FontWeight.bold, inherit: true),
          children: TargetCategory.values
              .map((e) => TextSpan(
                    text: tipologia.formatTarget(target[e]),
                    style: TextStyle(inherit: true, color: e.color),
                  ))
              .separate(() => const TextSpan(text: ' / '))
              .toList(),
        );
}
