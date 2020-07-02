import 'package:Atletica/athlete/atleta.dart';
import 'package:flutter/material.dart';

List<Group> groups = <Group>[];
Group lastGroup;

class Group {
  String name;
  final List<Atleta> atleti = <Atleta>[];

  Group({@required this.name});
}

bool existsInGroup(String name) => groups.any(
      (group) => group.atleti.any(
        (atleta) => atleta.name == name,
      ),
    );
