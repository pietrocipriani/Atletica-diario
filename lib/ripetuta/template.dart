import 'package:Atletica/persistence/auth.dart';
import 'package:Atletica/ripetuta/time_pattern.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mdi/mdi.dart';

Map<String, Template> templates = <String, Template>{};

class SimpleTemplate {
  final String name;
  Tipologia tipologia;
  double lastTarget;
  String get formattedTarget {
    if (lastTarget == null) return null;
    return '${tipologia.targetFormatter(lastTarget)} ${tipologia.targetSuffix ?? ''}';
  }

  Future<void> create() {
    return user.userReference
        .collection('templates')
        .document(name)
        .setData({'lastTarget': lastTarget});
  }

  SimpleTemplate({@required this.name, this.tipologia, this.lastTarget});

  @override
  String toString() => name;
}

class Template extends SimpleTemplate {
  Template.parse(DocumentSnapshot raw)
      : this(name: raw.documentID, lastTarget: raw['lastTarget']);

  Template({@required String name, double lastTarget})
      : super(
          name: name,
          lastTarget: lastTarget,
          tipologia: Tipologia.corsaDist,
        ) {
    templates[name] = this;
  }
}

class RegularExpressions {
  static final RegExp time = RegExp(
      "^\\s*\\d+\\s*(('\\s*([0-5]?\\d\\s*)?)?(\"\\s*\\d?\\d?|\\.\\d\\d?\\s*\"?))?\\s*\$");
  static final RegExp integer = RegExp(r'^\d+$');
  static final RegExp real = RegExp(r'^\d+(.\d+)?$');
}

/*
^\s*\d+\s*('\s*([0-5]?\d\s*"\s*\d?\d?)$
*/

class Tipologia {
  final String name;
  final Widget Function({Color color}) icon;
  final Function(double value) targetFormatter;
  final bool Function(String s) targetValidator;
  final String targetScheme;
  final String targetSuffix;
  final double Function(String target) targetParser;

  Tipologia({
    @required this.name,
    @required this.icon,
    @required this.targetFormatter,
    @required this.targetValidator,
    @required this.targetScheme,
    @required this.targetParser,
    this.targetSuffix,
  });

  static List<Tipologia> values = [
    corsaDist,
    corsaTemp,
    palestra,
    esercizi,
  ];

  static final Tipologia corsaDist = Tipologia(
    name: 'corsa',
    icon: ({color = Colors.black}) => Icon(
      Icons.directions_run,
      color: color,
    ),
    targetFormatter: (target) => target == null
        ? ''
        : (target >= 60 ? "${target ~/ 60}'" : '') +
            '${(target.truncate() % 60).toString().padLeft(target >= 60 ? 2 : 1, '0')}"' +
            (target < 60 || target != target.truncate()
                ? ((target * 100).round() % 100).toString().padLeft(2, '0')
                : ''),
    targetValidator: matchTimePattern,
    targetScheme: "es: 1' 20\"50",
    targetParser: parseTimePattern,
  );
  static final Tipologia corsaTemp = Tipologia(
    name: 'corsa a tempo',
    icon: ({color = Colors.black}) => Stack(
      alignment: Alignment.center,
      overflow: Overflow.visible,
      children: <Widget>[
        Icon(
          Icons.directions_run,
          color: color,
        ),
        Positioned(
          right: -3,
          bottom: -3,
          child: Icon(
            Icons.timer,
            size: 10,
            color: color,
          ),
        ),
      ],
    ),
    targetFormatter: (target) => target?.round() ?? '',
    targetValidator: (s) => RegularExpressions.integer.hasMatch(s),
    targetScheme: 'es: 5000 m',
    targetSuffix: 'm',
    targetParser: (target) => double.parse(target),
  );
  static final Tipologia palestra = Tipologia(
    name: 'palestra',
    icon: ({color = Colors.black}) => Icon(
      Mdi.weightLifter,
      color: color,
    ),
    targetFormatter: (target) => target?.round() ?? '',
    targetValidator: (s) => RegularExpressions.integer.hasMatch(s),
    targetScheme: 'es: 40 kg',
    targetSuffix: 'kg',
    targetParser: (target) => double.parse(target),
  );
  static final Tipologia esercizi = Tipologia(
    name: 'esercizi',
    icon: ({color = Colors.black}) => Icon(Mdi.yoga, color: color),
    targetFormatter: (target) => target?.round() ?? '',
    targetValidator: (s) => RegularExpressions.integer.hasMatch(s),
    targetScheme: 'es: 20x',
    targetSuffix: 'x',
    targetParser: (target) => double.parse(target),
  );
}
