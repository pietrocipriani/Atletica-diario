import 'package:Atletica/athlete/atleta.dart';
import 'package:Atletica/athlete/group.dart';
import 'package:flutter/material.dart';

class AthletesPicker extends StatelessWidget {
  final List<Atleta> athletes;
  final void Function(List<Atleta> athletes) onChanged;

  AthletesPicker(this.athletes, {@required this.onChanged});

  Function(Atleta a) _f(bool s) => s ? athletes.add : athletes.remove;
  Iterable<Atleta> _modified(Group g, bool s) =>
      g.atleti.where((a) => athletes.contains(a) != s);

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [];
    for (Group g in groups) {
      children.add(_LabeledCheckBox(
        state: g.atleti.every((a) => athletes.contains(a)),
        label: g.name,
        onChanged: (s) {
          _modified(g, s).forEach((a) => _f(s)(a));
          onChanged(athletes);
        },
      ));
      for (Atleta a in g.atleti)
        children.add(_LabeledCheckBox(
          state: athletes.contains(a),
          label: a.name,
          onChanged: (s) {
            _f(s)(a);
            onChanged(athletes);
          },
          padding: 1,
        ));
    }

    return Column(children: children);
  }
}

class _LabeledCheckBox extends StatelessWidget {
  final bool state;
  final String label;
  final int padding;
  final void Function(bool newState) onChanged;

  _LabeledCheckBox({
    @required this.state,
    @required this.label,
    this.onChanged,
    this.padding = 0,
  }) : assert(padding >= 0);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!state),
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: <Widget>[
          SizedBox(width: 40.0 * padding),
          Checkbox(
            value: state,
            onChanged: onChanged,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          Text(label),
        ],
      ),
    );
  }
}
