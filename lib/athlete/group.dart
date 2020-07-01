import 'dart:async';

import 'package:Atletica/athlete/atleta.dart';
import 'package:Atletica/persistence/database.dart';
import 'package:Atletica/plan/tabella.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqlite_api.dart';

List<Group> groups = <Group>[];
Group lastGroup;

class Group {
  final int id;
  String name;
  Tabella tabella;
  DateTime started;
  final List<Atleta> atleti = <Atleta>[];

  Group({@required this.id, @required this.name, this.tabella, this.started});
  Group.parse(Map<String, dynamic> raw) : this.id = raw['id'] {
    name = raw['name'];
    tabella = plans.firstWhere(
      (plan) => plan.name == raw['planName'],
      orElse: () => null,
    );
    started = raw['started'] == null ? null : DateTime.parse(raw['started']);
  }

  static Future<Group> createSaveAddReturn({
    @required String name,
    Tabella tabella,
    DateTime started,
  }) async {
    // TODO: add also plan and startTime
    final int id = await db.insert('Groups', {'name': name});
    final Group g = Group(id: id, name: name);
    groups.add(g);
    return g;
  }

  /// deletes `this` group both from `db` and `groups`
  /// if useless (`atleti` is empty).
  /// If `batch` is provided, it is used instead of `db`
  FutureOr<bool> delete({Batch batch, bool removeFromList = true}) {
    if (atleti.isNotEmpty) return false;
    if (removeFromList) groups.remove(this);
    if (batch == null)
      db.delete('Groups', where: 'id = ?', whereArgs: [id]);
    else
      batch.delete('Groups', where: 'id = ?', whereArgs: [id]);
    return true;
  }
}

bool existsInGroup(String name) => groups.any(
      (group) => group.atleti.any(
        (atleta) => atleta.name == name,
      ),
    );
