// TODO: what if sr.training matches another fixed tag? about filters
import 'package:Atletica/results/pbs/pb.dart';
import 'package:Atletica/results/pbs/pbs_page_route.dart';
import 'package:flutter/material.dart';

final List<TagsEvaluator> tags = [
  TagsEvaluator(
    // training
    (sr, value) => sr.training == value,
    (sr) => sr.training,
  ),
  TagsEvaluator(
      // meet
      (sr, value) => sr.isMeet,
      (sr) => sr.isMeet ? 'meeting' : 'training',
      {'meeting': Colors.red, 'training': Colors.blue}),
  TagsEvaluator(
      // stagional
      (sr, value) => sr.stagional,
      (sr) => sr.stagional ? 'stagional' : null,
      {'stagional': Colors.green})
];

class TagsEvaluator {
  final bool Function(SimpleResult sr, String value) accept;
  final String Function(SimpleResult sr) evaluate;
  final Map<String, Color> _color;
  TagsEvaluator(this.accept, this.evaluate, [this._color]);

  Color color(final String value) => _color == null ? null : _color[value];
}

class Tags extends StatelessWidget {
  final void Function(String tag, TagsEvaluator evaluator) onTap;
  final SimpleResult simpleResult;
  Tags(this.simpleResult, {this.onTap});

  @override
  Widget build(BuildContext context) => Wrap(
      crossAxisAlignment: WrapCrossAlignment.end,
      children: tags
          .map((tag) {
            String value = tag.evaluate(simpleResult);
            return _Tag(
              value,
              tag,
              filters.values.contains(value),
              onTap: onTap,
            );
          })
          .where((w) => w != null)
          .toList());
}

class _Tag extends StatelessWidget {
  final void Function(String tag, TagsEvaluator evaluator) onTap;
  final bool selected;
  final String value;
  final TagsEvaluator evaluator;
  _Tag(this.value, this.evaluator, this.selected, {this.onTap});

  @override
  Widget build(BuildContext context) {
    String value = _ellipsis(this.value, 15);
    if (value.length > 20) value = '${value.substring(0, 17)}...';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: GestureDetector(
        onTap: () => onTap?.call(selected ? null : this.value, evaluator),
        child: Text(
          selected ? '\u2713 $value' : value,
          style: TextStyle(color: evaluator.color(this.value)),
        ),
      ),
    );
  }
}

String _ellipsis(final String str, final int len) {
  if (str.length <= len) return str;
  return str.substring(0, len - 3) + '...';
}
