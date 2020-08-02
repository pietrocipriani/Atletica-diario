import 'package:Atletica/athlete/atleta.dart';
import 'package:Atletica/persistence/auth.dart';
import 'package:flutter/material.dart';

String lastGroup;

class Group {
  final String name;
  List<Athlete> get athletes =>
      List.unmodifiable(userC.athletes.where((a) => a.group == name));
  static List<Group> get groups {
    final Set<String> values = Set();
    userC.athletes.forEach((a) => values.add(a.group));
    if (values.isEmpty) values.add('generico');
    return List.unmodifiable(values.map((g) => Group(name: g)));
  }

  @override
  bool operator ==(dynamic other) => other is Group && other.name == name;

  const Group({@required this.name});

  @override
  int get hashCode => name.hashCode;
}
