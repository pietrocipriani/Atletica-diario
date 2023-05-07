import 'package:atletica/athlete/athlete.dart';
import 'package:atletica/athlete/group.dart';
import 'package:flutter/material.dart';

class AthletesPicker extends StatelessWidget {
  final List<Athlete> athletes;
  final void Function(List<Athlete> athletes) onChanged;

  AthletesPicker(this.athletes, {required this.onChanged});

  Function(Athlete a) _f(bool s) => s ? athletes.add : athletes.remove;
  Iterable<Athlete> _modified(List<Athlete> athletes, bool s) =>
      athletes.where((a) => this.athletes.contains(a) != s);

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = Group.groups.expand((g) {
      final List<Athlete> gAthletes = g.athletes.toList();
      return [
        Row(
          children: [
            Expanded(
              child: _LabeledCheckBox(
                state: g.isContainedIn(athletes),
                label: g.name,
                onChanged: (s) {
                  _modified(gAthletes, s).forEach((a) => _f(s)(a));
                  onChanged(athletes);
                },
              ),
            ),
            VerticalDivider(width: 1),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: gAthletes
                    .map(
                      (a) => _LabeledCheckBox(
                        state: athletes.contains(a),
                        label: a.name,
                        onChanged: (s) {
                          _f(s)(a);
                          onChanged(athletes);
                        },
                      ),
                    )
                    .toList(),
              ),
            )
          ],
        ),
        Divider()
      ];
    }).toList()
      ..removeLast();

    return Column(children: children, mainAxisSize: MainAxisSize.min);
  }
}

class _LabeledCheckBox extends StatelessWidget {
  final bool state;
  final String label;
  final void Function(bool newState) onChanged;

  _LabeledCheckBox({
    required this.state,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!state),
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: <Widget>[
          AnimatedContainer(
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            duration: kThemeAnimationDuration,
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color:
                  state ? Theme.of(context).indicatorColor : Colors.transparent,
              border: Border.all(
                  color: !state
                      ? Theme.of(context).disabledColor
                      : Colors.transparent),
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall,
              maxLines: 2,
              overflow: TextOverflow.clip,
            ),
          ),
        ],
      ),
    );
  }
}
