import 'package:Atletica/athlete/atleta.dart';
import 'package:Atletica/athlete/group.dart';
import 'package:flutter/material.dart';

class AthletesPicker extends StatelessWidget {
  final List<Atleta> athletes;
  final void Function(List<Atleta> athletes) onChanged;

  AthletesPicker(this.athletes, {@required this.onChanged});

  @override
  Widget build(BuildContext context) {
    List<Widget> children = () sync* {
      for (Group g in groups) {
        yield Row(
          children: <Widget>[
            Checkbox(
                value: g.atleti.every((a) => athletes.contains(a)),
                onChanged: (v) {
                  if (v)
                    g.atleti
                        .where((a) => !athletes.contains(a))
                        .forEach((a) => athletes.add(a));
                  else
                    g.atleti.forEach((a) => athletes.remove(a));
                  onChanged(athletes);
                }),
            Text(g.name)
          ],
        );
        for (Atleta a in g.atleti) {
          yield Row(
            children: <Widget>[
              SizedBox(width: 40),
              Checkbox(
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  value: athletes.contains(a),
                  onChanged: (v) {
                    if (v)
                      athletes.add(a);
                    else
                      athletes.remove(a);
                    onChanged(athletes);
                  }),
              Text(a.name),
            ],
          );
        }
      }
    }()
        .toList();

    return Column(children: children);
  }
}
